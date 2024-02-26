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
    parser.add_argument('--pipeline-name', help='name of pipeline', required=True)
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
            # load execution logs
            filenames = ['.command.log', '.command.out', '.command.err']
            filenames = [os.path.join(df_process.loc[hash_id, 'workdir'], filename) for filename in filenames]
            files = [open(filename) for filename in filenames if os.path.exists(filename)]
            lines = [line.strip() for f in files for line in f]

            if len(files) == 0:
                print('warning: no execution logs were found for task %s' % (hash_id))
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
        df_conditions.set_index('hash', inplace=True)

        # merge trace data with input features
        df_process = df_process.merge(df_conditions, how='left', left_index=True, right_index=True)
        df_process.sort_index(inplace=True)

        # append trace data to output file
        filename = '%s/%s.%s.trace.txt' % (args.output_dir, args.pipeline_name, process_name)

        if os.path.exists(filename):
            # load existing trace data
            df_prev = pd.read_csv(filename, sep='\t')

            # infer hash if necessary
            if 'hash' not in df_prev.columns:
                def workdir_hash(w):
                    tokens = w.split('/')
                    return '%s/%s' % (tokens[-2], tokens[-1][0:6])

                df_prev['hash'] = df_prev['workdir'].apply(workdir_hash)

            df_prev.set_index('hash', inplace=True)

            # append new trace data to existing data
            df_process = pd.concat([df_prev, df_process])

            # remove duplicate rows
            df_process = df_process[~df_process.index.duplicated()]

        df_process.to_csv(filename, sep='\t')
