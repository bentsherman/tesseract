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
	parser.add_argument("--hue", type=int, default=1, help="column index of hue axis", dest="HUE")
	parser.add_argument("--extra", type=int, default=None, help="additional column index which will be used to plot row-wise data in separate plots", dest="EXTRA")

	args = parser.parse_args()

	outfiles = args.OUTFILES.split(",")

	# validate arguments
	indices = [args.XAXIS, args.HUE, args.EXTRA]

	if len(indices) > len(set(indices)):
		print("error: x-axis, hue, and extra indices overlap")
		sys.exit(-1)

	# load dataframe and map axes to column indices
	data = pd.read_table(args.INPUT)

	extra = data.columns[args.EXTRA]
	x = data.columns[args.XAXIS]
	hue = data.columns[args.HUE]

	y_columns = list(set(data.columns) - set([extra, x, hue]))

	if len(outfiles) != len(y_columns):
		print("error: y columns do not match outfile names")
		sys.exit(-1)

	# save plot of each y column
	for outfile, y in zip(outfiles, y_columns):
		basename, ext = ".".join(outfile.split(".")[:-1]), outfile.split(".")[-1]
		extra_values = list(set(data[extra]))

		for extra_value in extra_values:
			data_clean = data[(data[extra] == extra_value) & (~data[y].isna())]

			sns.catplot(x=x, y=y, hue=hue, data=data_clean, kind="bar")
			plt.savefig("%s-%s.%s" % (basename, extra_value, ext))
