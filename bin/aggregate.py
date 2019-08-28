#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd



def merge_name_unit(name, unit):
	if isinstance(unit, str):
		return "%s (%s)" % (name, unit)
	else:
		return name



def load_trace(filename):
	return pd.read_csv(filename, sep="\t")



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
	parser.add_argument("--trace-input", help="list of nextflow trace files", nargs="+")
	parser.add_argument("--trace-output", help="output trace dataframe")
	parser.add_argument("--nvprof-input", help="list of nvprof files", nargs="+")
	parser.add_argument("--nvprof-output", help="output nvprof dataframe")
	parser.add_argument("--nvprof-mapper", help="mapping file for renaming column names")

	args = parser.parse_args()

	if args.trace_input:
		# load nextflow trace files
		trace_files = [load_trace(filename) for filename in args.trace_input]

		# aggregate trace files into one dataframe
		X_trace = pd.DataFrame()

		for X_i in trace_files:
			X_trace = X_trace.append(X_i, sort=False)

		# append condition columns to trace dataframe
		X_trace["tag"] = X_trace["tag"].apply(lambda tag: tag.replace(".", "-"))

		X_trace["experiment_type"] = X_trace["process"]
		X_trace["experiment_value"] = X_trace["tag"].apply(lambda tag: tag.split("/")[0])
		X_trace["dataset"] = X_trace["tag"].apply(lambda tag: tag.split("/")[1])
		X_trace["gpu_model"] = X_trace["tag"].apply(lambda tag: tag.split("/")[2])
		X_trace["trial"] = X_trace["tag"].apply(lambda tag: tag.split("/")[3])

		X_trace.drop(columns=["process", "tag", "name"], inplace=True)

		# save trace dataframe
		X_trace.to_csv(args.trace_output, sep="\t", index=False)

	if args.nvprof_input:
		# load nvprof files
		nvprof_files = [load_nvprof(filename) for filename in args.nvprof_input]

		# aggregate nvprof files into one dataframe
		X_nvprof = pd.DataFrame()

		for filename, X_i in zip(args.nvprof_input, nvprof_files):
			# parse conditions from filename
			tokens = filename.replace(".", "/").split("/")
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
			X_nvprof = X_nvprof.append(X_i, sort=False)

		# rename column names if mapping file is specified
		if args.nvprof_mapper:
			mapper = pd.read_csv(args.nvprof_mapper, sep="\t")
			mapper = {mapper.loc[i, "display_name"]: mapper.loc[i, "column_name"] for i in mapper.index}

			X_nvprof.rename(columns=mapper, copy=False, inplace=True)

		# save nvprof dataframe
		X_nvprof.to_csv(args.nvprof_output, sep="\t", index=False)
