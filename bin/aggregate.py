#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd



def merge_name_unit(name, unit):
	if isinstance(unit, str):
		return "%s (%s)" % (name, unit)
	else:
		return name



def load_conditions(filename):
	return pd.read_csv(filename, sep="\t", index_col="task_id")



def load_trace(filename):
	return pd.read_csv(filename, sep="\t", index_col="task_id", na_values="-")



def load_nvprof(filename):
	# load dataframe
	df = pd.read_csv(filename, skiprows=3)

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
	parser.add_argument("--conditions", help="conditions file", required=True)
	parser.add_argument("--trace-input", help="list of nextflow trace files", nargs="+")
	parser.add_argument("--trace-output", help="output trace dataframe")
	parser.add_argument("--nvprof-input", help="list of nvprof files", nargs="+")
	parser.add_argument("--nvprof-output", help="output nvprof dataframe")
	parser.add_argument("--nvprof-mapper", help="mapping file for renaming column names")
	parser.add_argument("--fix-exit-na", help="impute missing exit codes", action="store_true")
	parser.add_argument("--fix-runtime-sleep", help="adjust runtime metrics to account for running sleep beforehand", action="store_true")
	parser.add_argument("--fix-runtime-ms", help="convert runtime metrics from ms to s", action="store_true")

	args = parser.parse_args()

	# load conditions file
	X_conditions = load_conditions(args.conditions)

	if args.trace_input:
		# load nextflow trace files
		trace_files = [load_trace(filename) for filename in args.trace_input]

		# aggregate trace files into one dataframe
		X_trace = pd.DataFrame()

		for X_i in trace_files:
			X_trace = X_trace.append(X_i, sort=False)

		# remove unused columns
		X_trace.drop(columns=["process", "tag", "name"], inplace=True)

		# impute missing exit codes
		if args.fix_exit_na:
			X_trace["exit"].fillna(143, inplace=True)
			X_trace["exit"] = X_trace["exit"].astype(int)

		# adjust runtime metrics to exclude sleep time
		if args.fix_runtime_sleep:
			X_trace["duration"] -= 10000
			X_trace["realtime"] -= 10000

		# convert runtime metrics from ms to s
		if args.fix_runtime_ms:
			X_trace["duration"] /= 1000
			X_trace["realtime"] /= 1000

		# merge with input conditions
		X_trace = X_conditions.join(X_trace, on="task_id")

		# save trace dataframe
		X_trace.to_csv(args.trace_output, sep="\t", index="task_id")

	if args.nvprof_input:
		# load nvprof files
		nvprof_files = [load_nvprof(filename) for filename in args.nvprof_input]

		# aggregate nvprof files into one dataframe
		X_nvprof = pd.DataFrame()

		for filename, X_i in zip(args.nvprof_input, nvprof_files):
			# parse conditions from filename
			tokens = filename.replace(".", "/").split("/")
			task_id = tokens[-4]
			pid = tokens[-3]

			# append condition columns to input dataframe
			X_i["task_id"] = task_id
			X_i["pid"] = pid

			# append input dataframe rows to output dataframe
			X_nvprof = X_nvprof.append(X_i, sort=False)

		# rename column names if mapping file is specified
		if args.nvprof_mapper:
			mapper = pd.read_csv(args.nvprof_mapper, sep="\t")
			mapper = {mapper.loc[i, "display_name"]: mapper.loc[i, "column_name"] for i in mapper.index}

			X_nvprof.rename(columns=mapper, copy=False, inplace=True)

		# merge with input conditions
		X_nvprof = X_conditions.merge(X_nvprof, on="task_id")

		# save nvprof dataframe
		X_nvprof.to_csv(args.nvprof_output, sep="\t", index=False)
