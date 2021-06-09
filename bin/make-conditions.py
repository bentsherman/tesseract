#!/usr/bin/env python3

import argparse
import itertools
import pandas as pd
import re



def expand_range(value):
    # search for '{a-b}'
    p = re.compile('\{(\d+)-(\d+)\}')
    m = p.search(value)

    # return identity if no such expression found
    if m == None:
        return [value]

    # otherwise expand string with all values in [a, b]
    else:
        a = int(m.group(1))
        b = int(m.group(2))

        return [value.replace(m.group(), str(i)) for i in range(a, b + 1)]



def generate_experiments(configs, defaults, method):
    # define aggregation method
    methods = {
        'product': itertools.product,
        'zip': zip
    }
    method = methods[method]

    # generate experiments
    experiments = []

    for e in configs:
        # parse config object
        obj = {}

        for token in e:
            # parse condition and values
            condition, values = token.split('=')
            values = values.split(',')

            # expand range expressions
            values = sum([expand_range(v) for v in values], [])

            # append condition/values to config
            obj[condition] = [(condition, value) for value in values]

        # aggregate experiment variables
        iterations = method(*obj.values())

        # append defaults to each experiment
        for it in iterations:
            experiment = {**defaults}

            for condition, value in it:
                experiment[condition] = value

            experiments.append(experiment)

    return experiments



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--default', help='default condition value', action='append', default=[], metavar='condition=value')
    parser.add_argument('--experiment-inner', help='generate experiments from inner product of conditions', action='append', default=[], nargs='+', metavar='condition=value,value,... [...]')
    parser.add_argument('--experiment-outer', help='generate experiments from outer product of conditions', action='append', default=[], nargs='+', metavar='condition=value,value,... [...]')
    parser.add_argument('--output-file', help='output filename', default='conditions.txt')
    parser.add_argument('--remove-duplicates', help='remove duplicate condition sets', action='store_true')

    args = parser.parse_args()

    # initialize list of defaults
    defaults = {}

    for d in args.default:
        condition, value = d.split('=')
        defaults[condition] = value

    # initialize list of experiments
    experiments = []

    # generate inner-product experiments
    experiments += generate_experiments(args.experiment_inner, defaults, 'zip')

    # generate outer-product experiments
    experiments += generate_experiments(args.experiment_outer, defaults, 'product')

    # create output dataframe
    df = pd.DataFrame(experiments)

    # remove duplicate rows if specified
    if args.remove_duplicates:
        df.drop_duplicates(inplace=True)

    # save output dataframe
    df.to_csv(args.output_file, sep='\t', index=False)
