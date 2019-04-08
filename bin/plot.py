import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
import sys



if __name__ == "__main__":
	# parse command-line arguments
	if len(sys.argv) != 3:
		print("usage: python plot.py [infile] [outfiles]")
		sys.exit(-1)

	infile = sys.argv[1]
	outfiles = sys.argv[2].split(",")

	# determine data, axes, and hue
	data = pd.read_table(sys.argv[1])
	x = data.columns[0]
	hue = data.columns[1]
	y_columns = data.columns[2:]

	if len(outfiles) != len(y_columns):
		print("error: y columns do not match outfile names")
		sys.exit(-1)

	# save plot of each y column
	for outfile, y in zip(outfiles, y_columns):
		data_clean = data[~data[y].isna()]

		sns.catplot(x=x, y=y, hue=hue, data=data_clean, kind="bar")
		plt.savefig(outfile)
