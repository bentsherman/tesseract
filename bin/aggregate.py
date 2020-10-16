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
    parser.add_argument('--fix-runtime-ms', help='convert runtime metrics from ms to s', action='store_true')

    args = parser.parse_args()

    # load nextflow trace files into a single dataframe
    df = pd.concat([load_trace(filename) for filename in args.trace_files])

    # impute missing exit codes
    if args.fix_exit_na != None:
        df['exit'].fillna(args.fix_exit_na, inplace=True)
        df['exit'] = df['exit'].astype(int)

    # adjust runtime metrics to exclude sleep time
    if args.fix_runtime_sleep != None:
        df['duration'] -= args.fix_runtime_sleep * 1000
        df['realtime'] -= args.fix_runtime_sleep * 1000

    # convert runtime metrics from ms to s
    if args.fix_runtime_ms:
        df['duration'] /= 1000
        df['realtime'] /= 1000

    # separate trace data by process
    process_names = df['process'].unique()

    for process_name in process_names:
        # extract trace data for process type
        df_process = df[df['process'] == process_name]

        # extract input conditions from process scripts
        conditions = []

        for hash_id in df_process.index:
            # load process script
            filename = os.path.join(df_process.loc[hash_id, 'workdir'], '.command.sh')

            try:
                lines = [line.strip() for line in open(filename)]
            except FileNotFoundError:
                print('error: could not find process script for task %s' % (hash_id))
                continue

            # parse input conditions from trace directives
            PREFIX = '#TRACE'
            lines = [line[len(PREFIX):] for line in lines if line.startswith(PREFIX)]
            items = [line.split('=') for line in lines]
            c = {k.strip(): v.strip() for k, v in items}

            c['hash'] = hash_id

            # append input conditions to list
            conditions.append(c)

        # merge input conditions into dataframe
        df_conditions = pd.DataFrame(conditions)

        # merge trace data with input conditions
        df_process = df_process.merge(df_conditions, how='left', on='hash')
        df_process.sort_index(inplace=True)

        # save output trace dataframe
        filename = '%s/trace.%s.txt' % (args.output_dir, process_name)
        df_process.to_csv(filename, sep='\t', index=False)