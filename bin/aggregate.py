#!/usr/bin/env python3

import argparse
import numpy as np
import os
import pandas as pd



def load_conditions(filename):
    return pd.read_csv(filename, sep='\t', index_col='task_id')



def load_trace(filename):
    return pd.read_csv(filename, sep='\t', index_col='task_id', na_values='-')



if __name__ == '__main__':
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--conditions', help='input conditions file')
    parser.add_argument('--trace-input', help='list of nextflow trace files', nargs='+')
    parser.add_argument('--trace-output', help='output trace dataframe')
    parser.add_argument('--fix-exit-na', help='impute missing exit codes', type=int)
    parser.add_argument('--fix-runtime-sleep', help='adjust runtime metrics to account for running sleep beforehand', type=int)
    parser.add_argument('--fix-runtime-ms', help='convert runtime metrics from ms to s', action='store_true')

    args = parser.parse_args()

    # load nextflow trace files into a single dataframe
    df = pd.concat([load_trace(filename) for filename in args.trace_input])

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

    # load input conditions from file if specified
    if args.conditions != None:
        print('loading input conditions from file')

        df_conditions = load_conditions(args.conditions)

    # otherwise extract input conditions from process scripts
    else:
        print('extracting input conditions from process scripts')

        conditions = []

        for task_id in df.index:
            # load process script
            filename = os.path.join(df.loc[task_id, 'workdir'], '.command.sh')

            try:
                lines = [line.rstrip() for line in open(filename)]
            except FileNotFoundError:
                print('error: could not find process script for task %d' % (task_id))
                continue

            # extract line containing input conditions
            line = lines[2]

            # parse input conditions from text
            a = line.index('[')
            b = line.index(']')
            line = line[(a + 1):b]

            items = line.split(', ')
            items = [item.split(':') for item in items]
            c = {k: v for k, v in items}

            # convert task_id to number
            c['task_id'] = int(c['task_id'])

            # overwrite task_id if it does not match
            if task_id != c['task_id']:
                print('warning: task id from trace file (%d) does not match process script (%d), using task id from trace file' % (task_id, c['task_id']))
                c['task_id'] = task_id

            # append input conditions to list
            conditions.append(c)

        # merge input conditions into dataframe
        df_conditions = pd.DataFrame(conditions)

    # merge trace data with input conditions
    df = df.merge(df_conditions, how='left', on='task_id')
    df.sort_index(inplace=True)

    # save output trace dataframe
    df.to_csv(args.trace_output, sep='\t')