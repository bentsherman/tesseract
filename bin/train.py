#!/usr/bin/env python3

import argparse
import numpy as np
import os
import pandas as pd
import pickle
import sklearn.ensemble
import sklearn.metrics
import sklearn.model_selection
import sklearn.preprocessing
import sys
from tensorflow import keras



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

    return keras.wrappers.scikit_learn.KerasRegressor(
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

    # select scaler
    if args.scaler != None:
        scalers = {
            'maxabs': sklearn.preprocessing.MaxAbsScaler,
            'minmax': sklearn.preprocessing.MinMaxScaler,
            'standard': sklearn.preprocessing.StandardScaler
        }
        Scaler = scalers[args.scaler]

    # load nextflow trace files into a single dataframe
    df = pd.read_csv(args.trace_file, sep='\t')

    # select only tasks that completed successfully
    df = df[df['exit'] == 0]

    # extract input/output data from trace data
    input_names = [c['name'] for c in inputs]

    try:
        X = df[input_names]
        y = df[output['name']]
    except KeyError:
        print('error: one or more input/output variables are not in the dataset')
        sys.exit(1)

    # one-hot encode categorical inputs
    onehot_columns = [c['name'] for c in inputs if 'onehot' in c['transforms']]

    X = pd.get_dummies(X, columns=onehot_columns, drop_first=False)

    # apply scaler to input data
    if args.scaler != None:
        X = Scaler().fit_transform(X)

    # apply transforms to output
    for transform in output['transforms']:
        if transform == 'log2':
            y = np.log2(y)
        else:
            print('error: output transform %s not recognized' % (transform))
            sys.exit(1)

    # select model
    if args.model == 'mlp':
        print('training mlp model')

        # train mlp
        model = create_mlp(X.shape[1], hidden_layer_sizes=[128, 64, 32])

        # evaluate mlp
        scores = evaluate_cv(model, X, y, cv=args.cv)

        # print cross-validation results
        print('MAPE: %0.3f %%' % (scores.mean()))

        # save trained model if specified
        if args.model_file != None:
            # train model on full dataset
            model.fit(X, y)

            # save model to file
            model.model.save(args.model_file)

    elif args.model == 'rf':
        print('training rf model')

        # train random forest
        model = create_rf()

        # evaluate random forest
        scores = evaluate_cv(model, X, y, cv=args.cv)

        # print training results
        print('MAPE: %0.3f %%' % (scores.mean()))

        # save trained model if specified
        if args.model_file != None:
            # train model on full dataset
            model.fit(X, y)

            # save model to file
            f = open(args.model_file, 'wb')
            pickle.dump(model, f)
