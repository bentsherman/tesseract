#!/usr/bin/env python3

import argparse
import numpy as np
import os
import pandas as pd



def load_trace(filename):
    return pd.read_csv(filename, sep='\t', index_col='hash', na_values='-')



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('trace_files', help='list of nextflow trace files', nargs='+')
    parser.add_argument('--output-dir', help='output directory', default='.')
    parser.add_argument('--fix-exit-na', help='impute missing exit codes', type=int)
    parser.add_argument('--fix-runtime-sleep', help='adjust runtime metrics to account for running sleep beforehand', type=int)

    args = parser.parse_args()

    # load nextflow trace files into a single dataframe
    df = pd.concat([load_trace(filename) for filename in args.trace_files])

    # remove duplicate rows
    df = df[~df.index.duplicated()]

    # impute missing exit codes
    if args.fix_exit_na != None:
        df['exit'].fillna(args.fix_exit_na, inplace=True)
        df['exit'] = df['exit'].astype(int)

    # adjust runtime metrics to exclude sleep time
    if args.fix_runtime_sleep != None:
        df['duration'] -= args.fix_runtime_sleep * 1000
        df['realtime'] -= args.fix_runtime_sleep * 1000

    # separate trace data by process type
    process_names = df['process'].unique()

    for process_name in process_names:
        print(process_name)

        # extract trace data for process type
        df_process = df[df['process'] == process_name]

        # extract input features for each executed task
        conditions = []

        for hash_id in df_process.index:
            # load execution log
            try:
                filenames = ['.command.out', '.command.err']
                filenames = [os.path.join(df_process.loc[hash_id, 'workdir'], filename) for filename in filenames]
                files = [open(filename) for filename in filenames]
                lines = [line.strip() for f in files for line in f]
            except FileNotFoundError:
                print('warning: failed to load execution log for task %s' % (hash_id))
                continue

            # parse input features from trace directives
            PREFIX = '#TRACE'
            lines = [line[len(PREFIX):] for line in lines if line.startswith(PREFIX)]
            items = [line.split('=') for line in lines]
            c = {k.strip(): v.strip() for k, v in items}

            c['hash'] = hash_id

            # append input features to list
            conditions.append(c)

        # skip this process if no execution logs were found
        if len(conditions) == 0:
            print('warning: no execution logs found for process %s' % (process_name))
            continue

        # convert input features into dataframe
        df_conditions = pd.DataFrame(conditions)

        # merge trace data with input features
        df_process = df_process.merge(df_conditions, how='left', on='hash')
        df_process.sort_index(inplace=True)

        # save output trace dataframe
        filename = '%s/trace.%s.txt' % (args.output_dir, process_name)
        df_process.to_csv(filename, sep='\t', index=False)
