import os
import pandas as pd
import sys

def main():
    # parse command-line arguments
    args_input = sys.argv[1]
    args_output = sys.argv[2]

    # load input data
    infiles = os.listdir(args_input)
    inputs = [pd.read_csv(os.path.join(args_input, infile), sep='\t') for infile in infiles]

    # merge inputs into one dataframe
    df = pd.DataFrame().append(inputs)
    df.set_index('task_id', drop=True, inplace=True)
    df.sort_index(inplace=True)

    # save output dataframe
    df.to_csv(args_output, sep='\t')

if __name__ == '__main__':
    main()