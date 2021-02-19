#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import random



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a range of datasets drawn from an input dataset')
    parser.add_argument('--dataset', help='input dataset (genes x samples)', required=True)
    parser.add_argument('--n-row-iters', help='number of row iterations', type=int, default=8)
    parser.add_argument('--n-col-iters', help='number of column iterations', type=int, default=4)

    args = parser.parse_args()

    # load input dataset
    df = pd.read_csv(args.dataset, index_col=0, sep="\t")

    # compute output filename prefix
    prefix = args.dataset.split('.')[0]

    # generate output datasets from input
    for i in range(1, args.n_row_iters + 1):
        for j in range(1, args.n_col_iters + 1):
            # generate filename
            filename = '%s.%03d.%03d.emx.txt' % (prefix, i, j)

            # create partial dataset
            n_rows = df.shape[0] * i // args.n_row_iters
            n_cols = df.shape[1] * j // args.n_col_iters

            rows = random.sample(list(df.index), n_rows)
            cols = random.sample(list(df.columns), n_cols)

            df_subset = df.loc[rows, cols]

            # print dataset stats
            print('%s\t%d\t%d' % (filename, n_rows, n_cols))

            # save dataset to file
            df_subset.to_csv(filename, sep="\t", na_rep="NA", float_format="%.8f")
