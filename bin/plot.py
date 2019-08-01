import argparse
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import sys



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument("input", help="input dataset")
	parser.add_argument("outfiles", help="output plots")
	parser.add_argument("--xaxis", help="column index of x-axis", type=int, default=0)
	parser.add_argument("--hue", help="column index of hue axis", type=int, default=-1)
	parser.add_argument("--col", help="additional column index which will be used to create separate subplots", type=int, default=-1)
	parser.add_argument("--color", help="color for all barplot elements", default=None)
	parser.add_argument("--ratio", help="aspect ratio to control figure width", type=int, default=0)

	args = parser.parse_args()

	outfiles = args.outfiles.split(",")

	# validate arguments
	indices = [args.xaxis, args.hue, args.col]
	indices = [idx for idx in indices if idx != -1]

	if len(indices) > len(set(indices)):
		print("error: x-axis, hue, and col indices overlap")
		sys.exit(-1)

	# load dataframe and map axes to column indices
	data = pd.read_csv(args.input, sep="\t")

	x = data.columns[args.xaxis]
	hue = data.columns[args.hue] if args.hue != -1 else None
	col = data.columns[args.col] if args.col != -1 else None

	y_columns = list(set(data.columns) - set([x, hue, col]))

	if len(outfiles) != len(y_columns):
		print("error: y columns do not match outfile names")
		sys.exit(-1)

	# save plot of each y column
	for outfile, y in zip(outfiles, y_columns):
		data_clean = data[~data[y].isna()]

		if args.ratio != 0:
			plt.figure(figsize=(5 * args.ratio, 5))

		if hue == None and col == None:
			sns.barplot(x=x, y=y, data=data_clean, color=args.color)
		else:
			sns.catplot(x=x, y=y, hue=hue, col=col, data=data_clean, kind="bar", color=args.color)

		if len(set(data[x])) >= 100:
			plt.xticks([])

		plt.savefig(outfile)
		plt.close()
