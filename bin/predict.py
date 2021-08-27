#!/usr/bin/env python3

import argparse
import json
import numpy as np
import pickle

import utils



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('model_name', help='name of trained model')
    parser.add_argument('inputs', help='key-value pairs of input values', nargs='+')

    args = parser.parse_args()

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
    y = model.predict(X)

    # print results
    target = config['target']
    print('%s = %0.3f %s' % (target, y, utils.UNITS[target]))
