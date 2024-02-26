#!/usr/bin/env python3

import argparse
import json
import numpy as np
import pickle
import sys

import utils



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('model_name', help='name of trained model')
    parser.add_argument('inputs', help='key-value pairs of input values', nargs='+')
    parser.add_argument('--ci', help='proportion of confidence interval', default=0.95)

    args = parser.parse_args()

    # validate confidence interval
    if args.ci < 0 or 1 < args.ci:
        print('error: --ci must be between 0 and 1')
        sys.exit(1)

    # load model
    f = open('%s.pkl' % (args.model_name), 'rb')
    model = pickle.load(f)

    # load model configuration
    f = open('%s.json' % (args.model_name), 'r')
    config = json.load(f)

    # parse inputs
    inputs = [kv.split('=') for kv in args.inputs]
    inputs = {k: v for k, v in inputs}

    # convert inputs into an ordered vector
    x_input = {}

    for column, options in config['inputs'].items():
        # one-hot encode categorical inputs
        if options != None:
            for v in options:
                x_input['%s_%s' % (column, v)] = (inputs[column] == v)

        # copy numerical inputs directly
        else:
            x_input[column] = inputs[column]

    x_input = [float(x_input[c]) for c in config['columns']]

    # perform inference
    X = np.array([x_input])
    y_bar, y_std = utils.check_std(model.predict(X))
    y_lower, y_upper = utils.predict_intervals(y_bar, y_std, ci=args.ci)

    # print results
    target = config['target']

    print('%12s : %8.3f - %8.3f - %8.3f %s' % (
        target,
        y_lower, y_bar, y_upper,
        utils.UNITS[target]))
