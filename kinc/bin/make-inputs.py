#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import random

import utils



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser(description="Create a set of datasets drawn from an input dataset")
	parser.add_argument("--dataset", help="input dataset", required=True)
	parser.add_argument("--n-outputs", help="number of output datasets", type=int, default=10)

	args = parser.parse_args()

	# load input dataset
	df = utils.load_dataframe(args.dataset)

	# generate output datasets from input
	for i in range(args.n_outputs):
		# create sub dataset
		n_samples = df.shape[0] * i // args.n_outputs
		n_features = df.shape[1] * i // args.n_outputs

		samples = random.sample(list(df.index), n_samples)
		features = random.sample(list(df.columns), n_features)

		x = df.loc[samples, features]

		# save dataset to file
		utils.save_dataframe("dataset.%03d.txt" % (i), x)
