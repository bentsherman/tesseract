#!/usr/bin/env python3

import argparse
import numpy as np
import pickle
import sys



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('model_file', help='trained model file')
    parser.add_argument('--model', help='model type', choices=['mlp', 'rf'], required=True)
    parser.add_argument('--inputs', help='input values for prediction', nargs='+', type=float, required=True)
    parser.add_argument('--output-transform', help='apply transform to output variable')

    args = parser.parse_args()

    # load model from file
    f = open(args.model_file, 'rb')
    model = pickle.load(f)

    # perform inference
    X = np.array([args.inputs])
    y = model.predict(X)

    # apply transform to output if specified
    if args.output_transform != None:
        if args.output_transform == 'exp2':
            y = 2 ** y
        elif args.output_transform == 'log2':
            y = np.log2(y)
        else:
            print('error: output transform %s not recognized' % (args.output_transform))
            sys.exit(1)

    # print results
    print(y)
