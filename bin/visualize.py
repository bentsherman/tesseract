#!/usr/bin/env python3

import argparse
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import sys



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument("input", help="input dataset")
	parser.add_argument("outfile", help="output plot")
	parser.add_argument("--xaxis", help="column name of x-axis", required=True)
	parser.add_argument("--yaxis", help="column name of y-axis", required=True)
	parser.add_argument("--hue1", help="column name of primary hue axis (splits data within subplot)", nargs="?")
	parser.add_argument("--hue2", help="column name of secondary hue axis (splits data across subplots)", nargs="?")
	parser.add_argument("--color", help="color for all barplot elements", nargs="?")
	parser.add_argument("--ratio", help="aspect ratio to control figure width", type=float, default=0)

	args = parser.parse_args()

	# load dataframe
	data = pd.read_csv(args.input, sep="\t")

	# exclude rows which have missing values on y-axis
	data_clean = data[~data[args.yaxis].isna()]

	# apply aspect ratio if specified
	if args.ratio != 0:
		plt.figure(figsize=(5 * args.ratio, 5))

	# create a categorical plot if either hue columns are specified
	if args.hue1 != None or args.hue2 != None:
		sns.catplot(x=args.xaxis, y=args.yaxis, hue=args.hue1, col=args.hue2, data=data_clean, kind="bar", color=args.color)

	# otherwise create a bar plot
	else:
		sns.barplot(x=args.xaxis, y=args.yaxis, data=data_clean, color=args.color)

	# disable x-axis ticks if there are too many categories
	if len(set(data[args.xaxis])) >= 100:
		plt.xticks([])

	# save output figure
	plt.savefig(args.outfile)
	plt.close()
