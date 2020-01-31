#!/usr/bin/env python3

import argparse
import itertools
import pandas as pd



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument("--default", help="default condition value", action="append", default=[], metavar="condition=value")
	parser.add_argument("--experiment", help="generate experiments on a single condition", action="append", default=[], nargs="+", metavar="condition=value,value,... [...]")
	parser.add_argument("--output-file", help="output filename", default="conditions.txt")

	args = parser.parse_args()

	# initialize list of defaults
	defaults = {}

	for d in args.default:
		condition, value = d.split("=")
		defaults[condition] = value

	print(args)

	# generate experiments
	experiments = []

	for e in args.experiment:
		obj = {}

		for token in e:
			condition, values = token.split("=")
			values = values.split(",")

			obj[condition] = [(condition, value) for value in values]

		iterations = itertools.product(*obj.values())

		for it in iterations:
			experiment = {**defaults}

			for condition, value in it:
				experiment[condition] = value

			experiments.append(experiment)

	df = pd.DataFrame(experiments)
	df.to_csv(args.output_file, sep="\t", index=False)
