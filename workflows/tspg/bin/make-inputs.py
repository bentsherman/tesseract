#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import random
import sklearn.model_selection



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a list of gene sets drawn from an input dataset')
    parser.add_argument('--dataset', help='input dataset (samples x genes)', required=True)
    parser.add_argument('--labels', help='list of sample labels', required=True)
    parser.add_argument('--train-size-iters', help='training set proportion', type=float, nargs='+')
    parser.add_argument('--min-genes', help='minimum gene set size', type=int, default=1)
    parser.add_argument('--max-genes', help='maximum gene set size', type=int)
    parser.add_argument('--n-sets', help='number of gene sets', type=int, default=50)

    args = parser.parse_args()

    # load input dataset
    x = pd.read_csv(args.dataset, index_col=0, sep='\t')
    y = pd.read_csv(args.labels, index_col=0, sep='\t', header=None)
    x_samples = list(x.index)
    x_genes = list(x.columns)

    # get filename prefix
    prefix = args.dataset.split('.')[0]

    # set train size iters if needed
    if args.train_size_iters == None:
        args.train_size_iters = np.arange(0.1, 1.0, 0.1)

    # generate train/perturb splits
    for i, train_size in enumerate(args.train_size_iters):
        # split dataset into train/perturb sets
        x_train, x_perturb, y_train, y_perturb = sklearn.model_selection.train_test_split(x, y, test_size=1 - train_size)

        # save train/perturb data to file
        x_train.to_csv('%s.%d.train.emx.txt' % (prefix, i + 1), sep='\t')
        y_train.to_csv('%s.%d.train.labels.txt' % (prefix, i + 1), sep='\t', header=None)
        x_perturb.to_csv('%s.%d.perturb.emx.txt' % (prefix, i + 1), sep='\t')
        y_perturb.to_csv('%s.%d.perturb.labels.txt' % (prefix, i + 1), sep='\t', header=None)

    # set max genes if needed
    if args.max_genes == None:
        args.max_genes = len(x_genes)

    # create gene sets
    gene_sets = []

    for i in range(args.n_sets):
        n_genes = random.randint(args.min_genes, args.max_genes)
        genes = random.sample(x_genes, n_genes)

        gene_sets.append(['gene-set-%03d' % i] + genes)

    # save gene sets to file
    f = open('%s.genesets.txt' % (prefix), 'w')
    f.write('\n'.join(['\t'.join(gene_set) for gene_set in gene_sets]))
    f.write('\n')
