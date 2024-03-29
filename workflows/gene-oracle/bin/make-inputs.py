#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import random



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a list of gene sets drawn from an input dataset')
    parser.add_argument('--dataset', help='input dataset (samples x genes)', required=True)
    parser.add_argument('--min-genes', help='minimum gene set size', type=int, default=1)
    parser.add_argument('--max-genes', help='maximum gene set size', type=int)
    parser.add_argument('--n-sets', help='number of gene sets', type=int, nargs='+', default=[50])

    args = parser.parse_args()

    # load input dataset
    df = pd.read_csv(args.dataset, index_col=0, sep="\t")
    df_genes = list(df.columns)

    # get filename prefix
    prefix = args.dataset.split('.')[0]

    # set max genes if needed
    if args.max_genes == None:
        args.max_genes = len(df_genes)

    # create gene set lists
    for n_sets in args.n_sets:
        gene_sets = []

        for i in range(n_sets):
            n_genes = random.randint(args.min_genes, args.max_genes)
            genes = random.sample(df_genes, n_genes)

            gene_sets.append(['gene-set-%04d' % i] + genes)

        # save gene set list to file
        f = open('%s.%04d.genesets.txt' % (prefix, n_sets), 'w')
        f.write('\n'.join(['\t'.join(gene_set) for gene_set in gene_sets]))
        f.write('\n')
