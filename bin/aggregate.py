#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd



def merge_name_unit(name, unit):
	if isinstance(unit, str):
		return "%s (%s)" % (name, unit)
	else:
		return name



def load_nvprof(filename):
	# load dataframe
	df = pd.read_csv(filename)

	# merge the two header rows
	names = df.columns
	units = df.iloc[0, :]
	df.columns = [merge_name_unit(name, unit) for (name, unit) in zip(names, units)]

	# remove second header row
	df = df.iloc[1:, :]

	return df



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument("infiles", help="list of input files", nargs="+")
	parser.add_argument("outfile", help="output dataframe")

	args = parser.parse_args()

	# load input dataframes
	inputs = [load_nvprof(infile) for infile in args.infiles]

	# aggregate input dataframes into one dataframe
	X = pd.DataFrame()

	for infile, X_i in zip(args.infiles, inputs):
		# parse conditions from filename
		tokens = infile.replace(".", "/").split("/")
		experiment_type = tokens[-7]
		experiment_value = tokens[-6]
		dataset = tokens[-5]
		gpu_model = tokens[-4]
		trial = tokens[-3]

		# append condition columns to input dataframe
		X_i["experiment_type"] = experiment_type
		X_i["experiment_value"] = experiment_value
		X_i["dataset"] = dataset
		X_i["gpu_model"] = gpu_model
		X_i["trial"] = trial

		# append input dataframe rows to output dataframe
		X = X.append(X_i, sort=False)

	# save output dataframe
	X.to_csv(args.outfile, sep="\t", index=False)
