#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import random



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a range of datasets drawn from an input dataset')
    parser.add_argument('--dataset', help='input dataset (genes x samples)', required=True)
    parser.add_argument('--labels', help='input labels file', required=True)
    parser.add_argument('--method', help='sampling method', choices=['grid', 'random'], default='grid')
    parser.add_argument('--n-grid-rows', help='number of rows (for grid sampling)', type=int, default=4)
    parser.add_argument('--n-grid-cols', help='number of cols (for grid sampling)', type=int, default=4)
    parser.add_argument('--n-samples', help='number of samples (for random sampling)', type=int, default=10)

    args = parser.parse_args()

    # load dataset and labels
    X = pd.read_csv(args.dataset, index_col=0, sep='\t')
    y = pd.read_csv(args.labels, index_col=0, sep='\t')

    # remove index name from dataset
    X.index.rename('', inplace=True)

    # compute output filename prefix
    prefix = args.dataset.split('.')[0]

    # sample from grid if specified
    if args.method == 'grid':
        itor = [(i, j) for i in range(1, args.n_grid_rows + 1) for j in range(1, args.n_grid_cols + 1)]
        names = ['%03d.%03d' % (i, j) for i, j in itor]
        m_values = [X.shape[0] * i // args.n_grid_rows for i, j in itor]
        n_values = [X.shape[1] * j // args.n_grid_cols for i, j in itor]
        samples = zip(names, m_values, n_values)

    # sample randomly if specified
    elif args.method == 'random':
        itor = range(1, args.n_samples + 1)
        names = ['%03d' % (i) for i in itor]
        m_values = [random.randrange(X.shape[0] // 10, X.shape[0]) for i in itor]
        n_values = [random.randrange(X.shape[1] // 10, X.shape[1]) for i in itor]
        samples = zip(names, m_values, n_values)

    # generate output datasets from input
    for name, m, n in samples:
        # generate filenames
        dataset_name = '%s.%s.emx.txt' % (prefix, name)
        labels_name = '%s.%s.annotations.txt' % (prefix, name)

        # create partial dataset
        rows = random.sample(list(X.index), m)
        cols = random.sample(list(X.columns), n)

        X_subset = X.loc[rows, cols]
        y_subset = y.loc[cols]

        # print dataset stats
        print('%s\t%d\t%d' % (dataset_name, m, n))

        # save output files
        X_subset.to_csv(dataset_name, sep='\t', na_rep='NA', float_format='%.8f')
        y_subset.to_csv(labels_name, sep='\t')
