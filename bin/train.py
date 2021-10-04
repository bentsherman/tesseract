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

import models
import utils



def load_dataset(trace_file):
    # load trace file
    df = pd.read_csv(trace_file, sep='\t')

    # convert each resource metric to hr or GB
    df['runtime_hr'] = df['realtime'] / 1000 / 3600
    df['memory_GB'] = df['peak_rss'] / (1024 ** 3)
    df['disk_GB'] = df['write_bytes'] / (1024 ** 3)

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
        'realtime',
        'queue',
        '%cpu',
        '%mem',
        'rss',
        'vmem',
        'peak_rss',
        'peak_vmem',
        'read_bytes',
        'write_bytes',
        'rchar',
        'wchar',
        'syscr',
        'syscw',
        'vol_ctxt',
        'inv_ctxt',
        'scratch',
        'error_action'
    ]

    df.drop(columns=drop_columns, inplace=True, errors='ignore')

    # remove failed jobs
    df = df[df['exit'] == 0]

    return df



def merge_dataset(df, key, merge_file):
    if key in df.columns:
        # load other dataset
        df_merge = load_dataset(merge_file)

        # get list of new columns in other dataset
        columns = [c for c in df_merge.columns if c not in df.columns]
        df_merge = df_merge[[key] + columns]

        # merge other dataset
        df = df.merge(df_merge, on=key, how='left', copy=False)

    return df



def load_datasets(pipeline_name, process_names, base_dir='.', merge_files=[]):
    # load dataset for each process
    dfs = {}

    for process_name in process_names:
        try:
            trace_file = '%s/%s.%s.trace.txt' % (base_dir, pipeline_name, process_name)
            dfs[process_name] = load_dataset(trace_file)
        except FileNotFoundError:
            print('warn: no dataset found for process %s' % (process_name))

    # load merge files
    for process_name in dfs:
        df = dfs[process_name]

        for key, merge_file in merge_files:
            merge_file = os.path.join(base_dir, merge_file)
            df = merge_dataset(df, key, merge_file)

        dfs[process_name] = df

    return dfs



def is_categorical(df, column):
    return column != None and df[column].dtype.kind in 'OSUV'



def create_dataset(df, inputs, target=None):
    # extract input/target data from trace data
    X = df[inputs]
    y = df[target].values if target != None else None

    # one-hot encode categorical inputs, save categories
    options = {column: None for column in inputs}

    for column in inputs:
        if is_categorical(X, column):
            options[column] = X[column].unique().tolist()
            X = pd.get_dummies(X, columns=[column], drop_first=False)

    # save column order
    columns = list(X.columns)

    return X.values, y, columns, options



def create_dummy():
    return sklearn.dummy.DummyRegressor(strategy='quantile', quantile=1.0)



def create_gb(loss='lad'):
    return sklearn.ensemble.GradientBoostingRegressor(loss=loss, n_estimators=100)



def create_lr():
    return sklearn.linear_model.LinearRegression()



def asym_loss(y_true, y_pred):
    error = y_pred - y_true
    return tf.reduce_mean(
        tf.where(
            error < 0,
            tf.square(error),
            error
        ),
        axis=-1)



def asym_huber_loss(y_true, y_pred, delta=1.0):
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
    activation_target=None,
    l1=0,
    l2=1e-5,
    p_dropout=0.1,
    intervals=False,
    optimizer='adam', # lr=0.001
    loss='mean_absolute_error'):

    def build_fn():
        # create a 3-layer neural network
        x_input = keras.Input(shape=input_shape)

        x = x_input
        for units in hidden_layer_sizes:
            x = keras.layers.Dense(
                units=units,
                activation=activation,
                kernel_regularizer=keras.regularizers.l1_l2(l1, l2),
                bias_regularizer=keras.regularizers.l1_l2(l1, l2)
            )(x)

            if p_dropout != None:
                training = True if intervals else None
                x = keras.layers.Dropout(p_dropout)(x, training=training)

        y_output = keras.layers.Dense(units=1, activation=activation_target)(x)

        mlp = keras.models.Model(x_input, y_output)

        # compile the model
        mlp.compile(optimizer=optimizer, loss=loss)

        return mlp

    if intervals:
        KerasRegressor = models.KerasRegressorWithIntervals
    else:
        KerasRegressor = models.KerasRegressor

    return KerasRegressor(
        build_fn=build_fn,
        batch_size=32,
        epochs=200,
        verbose=False,
        validation_split=0.1
    )



def create_rf(criterion='mae', intervals=False):
    if intervals:
        RandomForestRegressor = models.RandomForestRegressorWithIntervals
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



def hpc_cost(y_true, y_pred):
    return np.mean(np.where(y_pred < y_true, y_pred + y_true, y_pred))



def prediction_interval_coverage(y_true, y_lower, y_upper):
    return np.mean((y_lower <= y_true) & (y_true <= y_upper))



def evaluate_trials(model, X, y, train_sizes=[0.8], n_trials=5):
    # use n_jobs=1 for tensorflow models
    if issubclass(type(model.named_steps['reg']), models.KerasRegressor):
        n_jobs = 1
    else:
        n_jobs = -1

    # perform repeated trials
    def evaluate(train_size):
        # create train/test split
        X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=1 - train_size)

        # train model
        model.fit(X_train, y_train)

        # get model predictions
        y_bar, y_std = utils.check_std(model.predict(X_test))

        # evaluate model
        mae = mean_absolute_error(y_test, y_bar)
        mpe = mean_absolute_percentage_error(y_test, y_bar)

        return train_size, mae, mpe

    results = Parallel(n_jobs=-1)(delayed(evaluate)(ts) for ts in train_sizes for _ in range(n_trials))

    # collect results
    scores_map = {}

    for train_size in train_sizes:
        scores_map[train_size] = {
            'mae': [mae for (ts, mae, mpe) in results if ts == train_size],
            'mpe': [mpe for (ts, mae, mpe) in results if ts == train_size]
        }

    return scores_map



def evaluate_cv(model, X, y, cv=5, ci=0.95):
    # initialize prediction arrays
    y_bar = np.empty_like(y)
    y_std = np.empty_like(y)

    # perform k-fold cross validation
    kfold = sklearn.model_selection.KFold(n_splits=cv, shuffle=True)

    for train_index, test_index in kfold.split(X):
        # reset session (for keras models)
        keras.backend.clear_session()

        # extract train/test split
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]

        # train model
        model_ = sklearn.base.clone(model)
        model_.fit(X_train, y_train)

        # get model predictions
        y_bar_i, y_std_i = utils.check_std(model_.predict(X_test))

        y_bar[test_index] = y_bar_i
        y_std[test_index] = y_std_i

    # compute prediction intervals
    y_lower, y_upper = utils.predict_intervals(y_bar, y_std, ci=ci)

    # evaluate predictions
    scores = {
        'mae': mean_absolute_error(y, y_bar),
        'mpe': mean_absolute_percentage_error(y, y_bar),
        'rae': relative_absolute_error(y, y_bar),
        'hpc': hpc_cost(y, y_bar),
        'cov': prediction_interval_coverage(y, y_lower, y_upper)
    }

    return scores, y_bar, y_std



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('dataset', help='dataset file')
    parser.add_argument('--base-dir', help='base directory for dataset files', default='.')
    parser.add_argument('--merge', help='additional dataset to merge into training data', action='append', nargs=2, metavar=('key', 'mergefile'), default=[])
    parser.add_argument('--inputs', help='list of input features', nargs='+', required=True)
    parser.add_argument('--target', help='target variable', required=True)
    parser.add_argument('--min-std', help='minimum std dev required to train model', type=float, default=0.1)
    parser.add_argument('--scaler', help='preprocessing transform to apply to inputs', choices=['maxabs', 'minmax', 'standard'], default='maxabs')
    parser.add_argument('--model-type', help='which model to train', choices=['gb', 'lr', 'mlp', 'rf'], required=True)
    parser.add_argument('--model-name', help='name of trained model for output files', required=True)
    parser.add_argument('--intervals', help='enable confidence intervals', action='store_true')

    args = parser.parse_args()

    # load dataset
    print('loading data')

    df = load_dataset(args.dataset)

    # load merge files and join with trace file
    for key, merge_file in args.merge:
        merge_file = os.path.join(args.base_dir, merge_file)
        df = merge_dataset(df, key, merge_file)

    # extract inputs/target from dataset
    try:
        X, y, columns, options = create_dataset(df, args.inputs, args.target)
    except KeyError:
        print('error: one or more input/target columns are not in the dataset')
        sys.exit(1)

    # print transformed input features
    print('input features: %s' % (' '.join(columns)))

    # select scaler
    if args.scaler != None:
        scalers = {
            'maxabs':   sklearn.preprocessing.MaxAbsScaler,
            'minmax':   sklearn.preprocessing.MinMaxScaler,
            'standard': sklearn.preprocessing.StandardScaler
        }
        Scaler = scalers[args.scaler]

    # use dummy regressor if target data has low variance
    if y.std() < args.min_std:
        print('target value has low variance, using max value rounded up')
        model_type = 'dummy'
    else:
        model_type = args.model_type

    # select model type
    if model_type == 'dummy':
        reg = create_dummy()

    elif model_type == 'gb':
        reg = create_gb()

    elif model_type == 'lr':
        reg = create_lr()

    elif model_type == 'mlp':
        reg = create_mlp(X.shape[1], intervals=args.intervals)

    elif model_type == 'rf':
        reg = create_rf(intervals=args.intervals)

    # create model pipeline
    model = create_pipeline(reg, scaler_fn=Scaler)

    # create model configuration
    config = {
        'inputs': options,
        'columns': columns,
        'target': args.target,
        'model_type': model_type
    }

    # train and evaluate model
    print('training model')

    scores, _, _ = evaluate_cv(model, X, y)

    # print cross-validation results
    print('mae: %0.3f %s' % (scores['mae'], utils.UNITS[args.target]))
    print('mpe: %0.3f %%' % (scores['mpe']))
    print('cov: %0.3f'    % (scores['cov']))

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
