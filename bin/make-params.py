#!/usr/bin/env python3

import argparse
import yaml



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('params_file', help='params file')

    args = parser.parse_args()

    # load params
    params_in = yaml.safe_load(open(args.params_file))

    # transform params
    params_out = {}

    for key in params_in:
        # split key into scopes
        scopes = key.split('.')
        
        # iteratively append scopes to params
        tmp = params_out

        for scope in scopes[0:-1]:
            if scope not in tmp:
                tmp[scope] = {}
            tmp = tmp[scope]

        # append final key and value to params
        tmp[scopes[-1]] = params_in[key]

    # write params to output file
    yaml.dump(params_out, stream=open(args.params_file, 'w'))
