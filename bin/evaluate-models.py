#!/usr/bin/env python3

import argparse
import json
import numpy as np
import os
import pandas as pd

from train import \
    load_pipeline, \
    create_dataset, \
    create_gb, \
    create_mlp, \
    create_rf, \
    evaluate_cv



def evaluate_models(pipeline_name, config, dfs):
    # evaluate prediction models for each process
    results = []

    for process_name, inputs in config['processes'].items():
        df = dfs[process_name]

        # skip if there are too few samples
        if len(df.index) < 10:
            continue

        # skip if there are no input features
        if len(inputs) == 0:
            continue

        # evaluate models for each target
        for target in ['runtime_hr', 'memory_GB', 'disk_GB']:
            print(pipeline_name, process_name, target)

            # compute summary stats
            row = {
                'pipeline': pipeline_name,
                'process': process_name,
                'target': target,
                'min': df[target].min(),
                'med': df[target].median(),
                'max': df[target].max()
            }

            # extract performance dataset
            X, y, columns = create_dataset(df, inputs, target)

            # define models
            models = [
                ('gb', create_gb()),
                ('rf', create_rf()),
                ('mlp', create_mlp(X.shape[1])),
            ]

            # evaluate each model on dataset
            for model_name, model in models:
                # evaluate model
                scores, y_pred = evaluate_cv(model, X, y, cv=5)

                # save metrics
                row['%s|mae' % (model_name)] = np.mean(scores['mae'])
                row['%s|rae' % (model_name)] = np.mean(scores['rae'])

            # save results
            results.append(row)

    return results




def main():
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('config_file', help='config file of pipelines')
    parser.add_argument('outfile', help='output file of results')

    args = parser.parse_args()

    # load config file
    config_map = json.load(open(args.config_file))

    # process each pipeline
    results = []

    for pipeline, config in config_map.items():
        # load pipeline trace files
        dfs = load_pipeline(config['trace_dir'], config['merge_files'])

        # train and evaluate prediction models
        results_i = evaluate_models(pipeline, config, dfs)

        # save results
        results += results_i

    # save output dataframe
    df_results = pd.DataFrame(results)
    df_results.set_index(['pipeline', 'process', 'target'], inplace=True)
    df_results.to_csv(args.outfile, sep='\t')



if __name__ == '__main__':
    main()