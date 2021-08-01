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

    args = parser.parse_args()

    # load model
    f = open('%s.pkl' % (args.model_name), 'rb')
    model = pickle.load(f)

    # load model configuration
    f = open('%s.json' % (args.model_name), 'r')
    config = json.load(f)

    # parse inputs
    inputs = [kv.split('=') for kv in args.inputs]
    inputs = {k: float(v) for k, v in inputs}
    x_input = [inputs[column] for column in config['inputs']]

    # perform inference
    X = np.array([x_input])
    y = model.predict(X)

    # print results
    print(y)
