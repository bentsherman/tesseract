#!/usr/bin/env python3

import argparse
import random



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser(description='Create a list of run IDs from a list of sample metadata')
    parser.add_argument('infile', help='input file')
    parser.add_argument('--outfile', help='output file', default='SRA_IDs.txt')
    parser.add_argument('--n-samples', help='number of samples', type=int, default=1000)

    args = parser.parse_args()

    # load input file
    def parse_sample(line):
        line = line.strip()
        line = line.replace('"', '')
        tokens = line.split(',')
        sample_id, run_ids = tokens[0], tokens[1].split(' ')
        return sample_id, run_ids

    samples = [parse_sample(line) for line in open(args.infile, 'r')]

    # select subset of samples
    samples = random.sample(samples, args.n_samples)

    # save run ids to output file
    f = open(args.outfile, 'w')
    f.write('\n'.join([run_id for sample_id, run_ids in samples for run_id in run_ids]))
    f.write('\n')
