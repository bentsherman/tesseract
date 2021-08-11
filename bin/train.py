#!/usr/bin/env python3

import argparse
from joblib import Parallel, delayed
import json
import numpy as np
import os
import pandas as pd
import pickle
import sklearn.dummy
import sklearn.ensemble
import sklearn.linear_model
from sklearn.metrics import mean_absolute_error
import sklearn.model_selection
import sklearn.pipeline
import sklearn.preprocessing
import sys
import tensorflow as tf
from tensorflow import keras

import utils



def load_pipeline(trace_dir, merge_files=[]):
    # get list of trace files
    filenames = os.listdir(trace_dir)
    process_names = [f.split('.')[1] for f in filenames if f.startswith('trace.') and f.endswith('.txt')]

    # load trace files
    dfs = {process_name: pd.read_csv('%s/trace.%s.txt' % (trace_dir, process_name), sep='\t') for process_name in process_names}

    # load merge files
    for key, columns, filename in merge_files:
        for process_name in dfs:
            if filename == 'trace.%s.txt' % (process_name):
                continue

            df = dfs[process_name]

            if len(set(columns).intersection(set(df.columns))) > 0:
                print('warning: merge columns already present, skipping merge')
                continue

            if key in df.columns:
                df_merge = pd.read_csv(os.path.join(trace_dir, filename), sep='\t')
                df_merge = df_merge[[key] + columns]
                dfs[process_name] = df.merge(df_merge, on=key, how='left', copy=False)

    # remove unused columns
    drop_columns = [
        'task_id',
        'native_id',
        'process',
        'tag',
        'name',
        'status',
        'module',
        'container',
        'cpus',
        'time',
        'disk',
        'memory',
        'attempt',
        'submit',
        'start',
        'complete',
        'duration',
        'queue',
        '%cpu',
        '%mem',
        'rss',
        'vmem',
        'peak_vmem',
        'rchar',
        'wchar',
        'syscr',
        'syscw',
        'vol_ctxt',
        'inv_ctxt',
        'scratch',
        'error_action'
    ]

    for process_name, df in dfs.items():
        df.drop(columns=drop_columns, inplace=True, errors='ignore')

    # apply additional transformations
    for process_name, df in dfs.items():
        # compute normalized output features
        df['runtime_hr'] = df['realtime'] / 1000 / 3600
        df['memory_GB'] = df['peak_rss'] / (1024 ** 3)
        df['disk_GB'] = df['write_bytes'] / (1024 ** 3)

        # remove failed jobs
        df = df[df['exit'] == 0]

        dfs[process_name] = df

    return dfs



def is_categorical(df, column):
    return column != None and df[column].dtype.kind in 'OSUV'



def create_dataset(df, inputs, target=None):
    # extract input/target data from trace data
    X = df[inputs]
    y = df[target].values if target != None else None

    # one-hot encode categorical inputs
    for column in inputs:
        if is_categorical(X, column):
            X = pd.get_dummies(X, columns=[column], drop_first=False)

    # save column order
    columns = list(X.columns)

    return X.values, y, columns



def create_dummy(strategy='mean'):
    return sklearn.dummy.DummyRegressor(strategy=strategy)



def create_gb(loss='lad'):
    return sklearn.ensemble.GradientBoostingRegressor(loss=loss, n_estimators=100)



def create_lr():
    return sklearn.linear_model.LinearRegression()



def asym_error(y_true, y_pred):
    error = y_pred - y_true
    return tf.reduce_mean(
        tf.where(
            error <= 0,
            tf.square(error),
            error
        ),
        axis=-1)



def huber_asym(y_true, y_pred, delta=1.0):
    error = y_pred - y_true
    return tf.reduce_mean(
        tf.where(
            error <= delta,
            0.5 * tf.square(error),
            delta * error - 0.5 * tf.square(delta)
        ),
        axis=-1)



def create_mlp(
    input_shape,
    hidden_layer_sizes=[128, 128, 128],
    activation='relu',
    l1=0,
    l2=1e-3,
    p_dropout=0.1,
    conf_intervals=False,
    optimizer='adam', # lr=0.001
    loss='mean_absolute_error'):

    def build_fn():
        # create a 3-layer neural network
        x_input = keras.Input(shape=input_shape)

        x = x_input
        for units in hidden_layer_sizes:
            x = keras.layers.Dense(
                units=units,
                activation='relu',
                kernel_regularizer=keras.regularizers.l1_l2(l1, l2),
                bias_regularizer=keras.regularizers.l1_l2(l1, l2)
            )(x)

            if p_dropout != None:
                training = True if conf_intervals else None
                x = keras.layers.Dropout(p_dropout)(x, training=training)

        y_output = keras.layers.Dense(units=1)(x)

        mlp = keras.models.Model(x_input, y_output)

        # compile the model
        mlp.compile(optimizer=optimizer, loss=loss)

        return mlp

    if conf_intervals:
        KerasRegressor = utils.KerasRegressorWithIntervals
    else:
        KerasRegressor = utils.KerasRegressor

    return KerasRegressor(
        build_fn=build_fn,
        batch_size=32,
        epochs=200,
        verbose=False,
        validation_split=0.1
    )



def create_rf(criterion='mae', conf_intervals=False):
    if conf_intervals:
        RandomForestRegressor = utils.RandomForestRegressorWithIntervals
    else:
        RandomForestRegressor = sklearn.ensemble.RandomForestRegressor

    return RandomForestRegressor(n_estimators=100, criterion=criterion)



def create_pipeline(reg, scaler_fn=sklearn.preprocessing.MaxAbsScaler):
    return sklearn.pipeline.Pipeline([
        ('scaler', scaler_fn()),
        ('reg', reg)
    ])



def mean_absolute_percentage_error(y_true, y_pred):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    return 100 * np.mean(np.abs((y_true - y_pred) / y_true))



def relative_absolute_error(y_true, y_pred):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    return 100 * np.abs(y_true - y_pred).sum() / np.abs(y_true - y_true.mean()).sum()



def prediction_interval_coverage(y_true, y_lower, y_upper):
    return np.mean((y_lower <= y_true) & (y_true <= y_upper))



def evaluate_trials(model, X, y, train_size=0.8, n_trials=5):
    # perform repeated trials
    def evaluate(i):
        # create train/test split
        X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=1 - train_size)

        # train model
        model.fit(X_train, y_train)

        # get model predictions
        y_pred = model.predict(X_test)

        if isinstance(y_pred, tuple):
            y_pred, _, _ = y_pred

        # evaluate model
        mae = mean_absolute_error(y_test, y_pred)
        rae = relative_absolute_error(y_test, y_pred)

        return mae, rae

    results = Parallel(n_jobs=-1)(delayed(evaluate)(i) for i in range(n_trials))

    # collect results
    scores = {
        'mae': [],
        'rae': []
    }

    for mae, rae in results:
        scores['mae'].append(mae)
        scores['rae'].append(rae)

    return scores



def evaluate_cv(model, X, y, cv=5):
    # perform k-fold cross validation
    kfold = sklearn.model_selection.KFold(n_splits=cv, shuffle=True)

    def evaluate(train_index, test_index):
        # extract train/test split
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]

        # train model
        model_ = sklearn.base.clone(model)
        model_.fit(X_train, y_train)

        # get model predictions
        y_pred_i = model_.predict(X_test)

        return y_pred_i, test_index

    results = Parallel(n_jobs=-1)(delayed(evaluate)(*args) for args in kfold.split(X))

    # collect results
    y_pred = np.empty_like(y)
    y_lower = np.empty_like(y)
    y_upper = np.empty_like(y)

    for y_pred_i, test_index in results:
        # save prediction intervals
        if isinstance(y_pred_i, tuple):
            y_pred_i, y_lower_i, y_upper_i = y_pred_i
            y_lower[test_index] = y_lower_i
            y_upper[test_index] = y_upper_i
        else:
            y_lower[test_index] = y_pred_i
            y_upper[test_index] = y_pred_i

        # save point predictions
        y_pred[test_index] = y_pred_i

    # evaluate predictions
    scores = {
        'mae': mean_absolute_error(y, y_pred),
        'rae': relative_absolute_error(y, y_pred),
        'cov': prediction_interval_coverage(y, y_lower, y_upper)
    }

    return scores, y_pred, y_lower, y_upper



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('trace_file', help='annotated trace file')
    parser.add_argument('--merge', help='join an additional dataframe to trace file', action='append', nargs=2, metavar=('key', 'mergefile'), default=[])
    parser.add_argument('--inputs', help='list of input features', nargs='+', required=True)
    parser.add_argument('--output', help='target variable', required=True)
    parser.add_argument('--scaler', help='preprocessing transform to apply to inputs', choices=['maxabs', 'minmax', 'standard'])
    parser.add_argument('--model-type', help='which model to train', choices=['gb', 'mlp', 'rf'], required=True)
    parser.add_argument('--model-name', help='name of trained model for output files')

    args = parser.parse_args()

    # load trace file
    print('loading data')

    df = pd.read_csv(args.trace_file, sep='\t')

    # load merge files and join with trace file
    for key, filename in args.merge:
        df_merge = pd.read_csv(filename, sep='\t')
        df = df.merge(df_merge, on=key, how='left', copy=False)

    # select only tasks that completed successfully
    df = df[df['exit'] == 0]

    # extract input/output data from trace data
    try:
        X, y, columns = create_dataset(df, args.inputs, args.output)
    except KeyError:
        print('error: one or more input/output variables are not in the dataset')
        sys.exit(1)

    # print transformed input features
    print('input features: %s' % (' '.join(columns)))

    # select scaler
    if args.scaler != None:
        scalers = {
            'maxabs': sklearn.preprocessing.MaxAbsScaler,
            'minmax': sklearn.preprocessing.MinMaxScaler,
            'standard': sklearn.preprocessing.StandardScaler
        }
        Scaler = scalers[args.scaler]

    # select model type
    if args.model_type == 'lr':
        reg = create_lr()

    elif args.model_type == 'gb':
        reg = create_gb()

    elif args.model_type == 'mlp':
        reg = create_mlp(X.shape[1])

    elif args.model_type == 'rf':
        reg = create_rf()

    # create pipeline
    model = create_pipeline(reg, scaler_fn=Scaler)

    # create model configuration
    config = {
        'inputs': columns,
        'model-type': args.model_type
    }

    # train and evaluate model
    print('training model')

    scores, y_pred = evaluate_cv(model, X, y)

    # print cross-validation results
    print('MAE: %0.3f' % (scores['mae'].mean()))
    print('RAE: %0.3f %%' % (scores['rae'].mean()))

    # save trained model if specified
    if args.model_name != None:
        print('saving model to file')

        # train model on full dataset
        model.fit(X, y)

        # workaround for keras models
        try:
            model.named_steps['reg'].build_fn = None
        except:
            pass

        # save model to file
        f = open('%s.pkl' % (args.model_name), 'wb')
        pickle.dump(model, f)

        # save model configuration
        f = open('%s.json' % (args.model_name), 'w')
        json.dump(config, f)
