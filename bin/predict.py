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
    parser.add_argument('inputs', help='input values for prediction', nargs='+', type=float)

    args = parser.parse_args()

    # load model
    f = open('%s.pkl' % (args.model_name), 'rb')
    model = pickle.load(f)

    # load model configuration
    f = open('%s.json' % (args.model_name), 'r')
    config = json.load(f)

    # perform inference
    X = np.array([args.inputs])
    y = model.predict(X)

    # apply transforms to output if specified
    for transform in config['output-transforms']:
        try:
            t = utils.transforms[transform]
            y = t.inverse_transform(y)
        except:
            print('error: output transform %s not recognized' % (transform))
            sys.exit(1)

    # print results
    print(y)
