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
    parser.add_argument('--n-row-iters', help='number of row iterations', type=int, default=8)
    parser.add_argument('--n-col-iters', help='number of column iterations', type=int, default=4)

    args = parser.parse_args()

    # load input dataset
    X = pd.read_csv(args.dataset, index_col=0, sep='\t')
    y = pd.read_csv(args.labels, index_col=0, sep='\t')

    # compute output filename prefix
    prefix = args.dataset.split('.')[0]

    # generate output datasets from input
    for i in range(1, args.n_row_iters + 1):
        for j in range(1, args.n_col_iters + 1):
            # generate filenames
            dataset_name = '%s.%03d.%03d.emx.txt' % (prefix, i, j)
            labels_name = '%s.%03d.%03d.annotations.txt' % (prefix, i, j)

            # create partial dataset
            n_rows = X.shape[0] * i // args.n_row_iters
            n_cols = X.shape[1] * j // args.n_col_iters

            rows = random.sample(list(X.index), n_rows)
            cols = random.sample(list(X.columns), n_cols)

            X_subset = X.loc[rows, cols]
            y_subset = y.loc[cols]

            # print dataset stats
            print('%s\t%d\t%d' % (dataset_name, n_rows, n_cols))

            # save output files
            X_subset.to_csv(dataset_name, sep='\t', na_rep='NA', float_format='%.8f')
            y_subset.to_csv(labels_name, sep='\t')
