#!/usr/bin/env python3

import argparse
import numpy as np
import os
import pandas as pd
import pickle
import sklearn.ensemble
import sklearn.metrics
import sklearn.model_selection
import sklearn.pipeline
import sklearn.preprocessing
import sys
from tensorflow import keras

from utils import KerasRegressor



def parse_transforms(arg):
    tokens = arg.split(':')
    return { 'name': tokens[0], 'transforms': tokens[1:] }



def create_mlp(input_shape, hidden_layer_sizes=[10], activation='relu'):
    def build_fn():
        # create a 3-layer neural network
        x_input = keras.Input(shape=input_shape)

        x = x_input
        for units in [128, 64, 32]:
            x = keras.layers.Dense(units=units, activation=activation)(x)

        y_output = keras.layers.Dense(units=1)(x)

        mlp = keras.models.Model(x_input, y_output)

        # compile the model
        mlp.compile(optimizer='adam', loss='mean_absolute_percentage_error')

        return mlp

    return KerasRegressor(
        build_fn=build_fn,
        batch_size=32,
        epochs=200,
        validation_split=0.1,
        verbose=False
    )



def create_rf():
    return sklearn.ensemble.RandomForestRegressor(n_estimators=100)



def mean_absolute_percentage_error(y_true, y_pred):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    return 100 * np.mean(np.abs((y_true - y_pred) / y_true))



def relative_absolute_error(y_true, y_pred):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    return 100 * np.abs(y_true - y_pred).sum() / np.abs(y_true - y_true.mean()).sum()



def evaluate_once(model, X, y, train_size=0.8):
    # create train/test split
    X_train, X_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=1 - train_size)

    # train model
    model.fit(X_train, y_train)

    # evaluate model
    y_pred = model.predict(X_test)
    score = mean_absolute_percentage_error(y_test, y_pred)

    return score



def evaluate_trials(model, X, y, train_size=0.8, n_trials=5):
    return [evaluate_once(model, X, y, train_size=train_size) for i in range(n_trials)]



def evaluate_cv(model, X, y, cv=5):
    scorer = sklearn.metrics.make_scorer(mean_absolute_percentage_error)
    scores = sklearn.model_selection.cross_val_score(model, X, y, scoring=scorer, cv=cv, n_jobs=-1)

    return scores



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('trace_file', help='annotated trace file')
    parser.add_argument('--merge', help='join an additional dataframe to trace file', action='append', nargs=2, metavar=('key', 'mergefile'), default=[])
    parser.add_argument('--inputs', help='list of input features (append :<transform> for additional transform)', nargs='+', required=True)
    parser.add_argument('--output', help='output variable (append :<transform> for additional transform)', required=True)
    parser.add_argument('--scaler', help='preprocessing transform to apply to inputs', choices=['maxabs', 'minmax', 'standard'])
    parser.add_argument('--model', help='which model to train', choices=['mlp', 'rf'], required=True)
    parser.add_argument('--cv', help='number of folds for cross-validation', type=int, default=5)
    parser.add_argument('--model-file', help='output file to save trained model')

    args = parser.parse_args()

    # parse input and output transforms
    inputs = [parse_transforms(arg) for arg in args.inputs]
    output = parse_transforms(args.output)

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
        X = df[[c['name'] for c in inputs]]
        y = df[output['name']]
    except KeyError:
        print('error: one or more input/output variables are not in the dataset')
        sys.exit(1)

    # one-hot encode categorical inputs
    onehot_columns = [c['name'] for c in inputs if 'onehot' in c['transforms']]

    X = pd.get_dummies(X, columns=onehot_columns, drop_first=False)

    # apply transforms to output
    for transform in output['transforms']:
        if transform == 'exp2':
            y = 2 ** y
        elif transform == 'log2':
            y = np.log2(y)
        else:
            print('error: output transform %s not recognized' % (transform))
            sys.exit(1)

    # print transformed input features
    print('input features: %s' % (' '.join(X.columns)))

    # select scaler
    if args.scaler != None:
        scalers = {
            'maxabs': sklearn.preprocessing.MaxAbsScaler,
            'minmax': sklearn.preprocessing.MinMaxScaler,
            'standard': sklearn.preprocessing.StandardScaler
        }
        Scaler = scalers[args.scaler]

    # select regression model
    if args.model == 'mlp':
        regressor = create_mlp(X.shape[1], hidden_layer_sizes=[128, 64, 32])

    elif args.model == 'rf':
        regressor = create_rf()

    # create pipeline
    model = sklearn.pipeline.Pipeline([
        ('scaler', Scaler()),
        ('regressor', regressor)
    ])

    # train and evaluate model
    print('training model')

    scores = evaluate_cv(model, X, y, cv=args.cv)

    # print cross-validation results
    print('MAPE: %0.3f %%' % (scores.mean()))

    # save trained model if specified
    if args.model_file != None:
        print('saving model to file')

        # train model on full dataset
        model.fit(X, y)

        # workaround for keras models
        try:
            model.named_steps['regressor'].build_fn = None
        except:
            pass

        # save model to file
        f = open(args.model_file, 'wb')
        pickle.dump(model, f)
