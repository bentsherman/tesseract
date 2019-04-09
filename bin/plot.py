import argparse
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import sys



if __name__ == "__main__":
	# parse command-line arguments
	parser = argparse.ArgumentParser()
	parser.add_argument(help="input dataset", dest="INPUT")
	parser.add_argument(help="output plots", dest="OUTFILES")
	parser.add_argument("--xaxis", type=int, default=0, help="column index of x-axis", dest="XAXIS")
	parser.add_argument("--hue", type=int, default=-1, help="column index of hue axis", dest="HUE")
	parser.add_argument("--col", type=int, default=-1, help="additional column index which will be used to create separate subplots", dest="EXTRA")
	parser.add_argument("--color", default=None, help="color for all barplot elements", dest="COLOR")
	parser.add_argument("--ratio", type=int, default=0, help="aspect ratio to control figure width", dest="RATIO")

	args = parser.parse_args()

	outfiles = args.OUTFILES.split(",")

	# validate arguments
	indices = [args.XAXIS, args.HUE, args.EXTRA]
	indices = [idx for idx in indices if idx != -1]

	if len(indices) > len(set(indices)):
		print("error: x-axis, hue, and col indices overlap")
		sys.exit(-1)

	# load dataframe and map axes to column indices
	data = pd.read_table(args.INPUT)

	x = data.columns[args.XAXIS]
	hue = data.columns[args.HUE] if args.HUE != -1 else None
	col = data.columns[args.EXTRA] if args.EXTRA != -1 else None

	y_columns = list(set(data.columns) - set([x, hue, col]))

	if len(outfiles) != len(y_columns):
		print("error: y columns do not match outfile names")
		sys.exit(-1)

	# save plot of each y column
	for outfile, y in zip(outfiles, y_columns):
		data_clean = data[~data[y].isna()]

		if args.RATIO != 0:
			plt.figure(figsize=(5 * args.RATIO, 5))

		if hue == None and col == None:
			sns.barplot(x=x, y=y, data=data_clean, color=args.COLOR)
		else:
			sns.catplot(x=x, y=y, hue=hue, col=col, data=data_clean, kind="bar", color=args.COLOR)

		if len(set(data[x])) >= 100:
			plt.xticks([])

		plt.savefig(outfile)
