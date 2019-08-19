#!/usr/bin/env python3

import argparse
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import sys



def filter_by_values(df, column, values):
	mask = [(v in values) for v in df[column]]
	return df[mask]



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument("input", help="input dataset")
	parser.add_argument("outfile", help="output plot")
	parser.add_argument("--xaxis", help="column name of x-axis", required=True)
	parser.add_argument("--xaxis-values", help="values to include from x column", nargs="*")
	parser.add_argument("--yaxis", help="column name of y-axis", required=True)
	parser.add_argument("--yaxis-values", help="values to include from y column", nargs="*")
	parser.add_argument("--hue1", help="column name of primary hue axis (splits data within subplot)", nargs="?")
	parser.add_argument("--hue1-values", help="values to include from primary hue column", nargs="*")
	parser.add_argument("--hue2", help="column name of secondary hue axis (splits data across subplots)", nargs="?")
	parser.add_argument("--hue2-values", help="values to include from secondary hue column", nargs="*")
	parser.add_argument("--color", help="color for all barplot elements", nargs="?")
	parser.add_argument("--ratio", help="aspect ratio to control figure width", type=float, default=0)

	args = parser.parse_args()

	# load dataframe
	data = pd.read_csv(args.input, sep="\t")

	# apply filters to dataframe
	axes = [
		(args.xaxis, args.xaxis_values),
		(args.yaxis, args.yaxis_values),
		(args.hue1, args.hue1_values),
		(args.hue2, args.hue2_values)
	]

	for column, values in axes:
		# skip columns which were not specified
		if column == None:
			continue

		# remove rows which have missing values in column
		data = data[~data[column].isna()]

		# filter rows by selected values in column
		if values != None and len(values) > 0:
			data = filter_by_values(data, column, values)

		# sort dataframe by column
		data.sort_values(by=column, inplace=True)

	# apply aspect ratio if specified
	if args.ratio != 0:
		plt.figure(figsize=(5 * args.ratio, 5))

	# create a categorical plot if either hue columns are specified
	if args.hue1 != None or args.hue2 != None:
		sns.catplot(x=args.xaxis, y=args.yaxis, hue=args.hue1, col=args.hue2, data=data, kind="bar", color=args.color)

	# otherwise create a bar plot
	else:
		sns.barplot(x=args.xaxis, y=args.yaxis, data=data, color=args.color)

	# disable x-axis ticks if there are too many categories
	if len(set(data[args.xaxis])) >= 100:
		plt.xticks([])

	# save output figure
	plt.savefig(args.outfile)
	plt.close()
