import os
import pandas as pd
import sys



def select_rows_by_values(df, column, values):
    return pd.DataFrame().append([df[df[column].astype(str) == v] for v in values], sort=False)



def main():
    # parse command-line arguments
    if len(sys.argv) != 4:
        print('usage: ./compute-speedup.py <trace-file> <sizes-file> <output-file>')
        sys.exit(1)

    args_trace = sys.argv[1]
    args_sizes = sys.argv[2]
    args_output = sys.argv[3]

    # load input data
    df = pd.read_csv(args_trace, sep='\t')
    df_sizes = pd.read_csv(args_sizes, sep='\t')

    # remove unused rows
    df = select_rows_by_values(df, 'status', ['CACHED', 'COMPLETED'])
    df = select_rows_by_values(df, 'gpu_model', ['cpu', 'p100', 'v100'])
    df = select_rows_by_values(df, 'latticetype', ['D3Q15'])

    # aggregate trials into averages
    group_keys = ['gpu_model', 'geometry', 'np']
    aggregate_keys = ['realtime']

    df = df[group_keys + aggregate_keys]
    df = df.groupby(group_keys).aggregate(['size', 'mean'])
    df.reset_index(inplace=True)

    # remove second column level
    df.columns = df.columns.map('|'.join).str.strip('|')

    # append site counts to trace data
    df = df.merge(df_sizes, on='geometry', how='left', copy=False)

    # compute throughput
    n_iters = 50000
    df['throughput'] = df['n_sites'] * n_iters / df['realtime|mean']

    # compute per-core throughput
    df['throughput_per_core'] = df['throughput'] / df['np']

    # compute parallel speedup
    df['speedup_np'] = 0.0

    for idx, row in df.iterrows():
        row_single = df[(df['gpu_model'] == row['gpu_model']) & (df['geometry'] == row['geometry']) & (df['np'] == 1)]
        realtime_single = row_single['realtime|mean']

        if not realtime_single.empty:
            df.loc[idx, 'speedup_np'] = realtime_single.values[0] / row['realtime|mean']

    # compute parallel efficiency
    df['efficiency'] = df['speedup_np'] / df['np']

    # compute GPU speedup
    df['speedup_gpu'] = 0.0

    for idx, row in df.iterrows():
        if row['gpu_model'] != 'cpu':
            row_cpu = df[(df['gpu_model'] == 'cpu') & (df['geometry'] == row['geometry']) & (df['np'] == row['np'])]
            realtime_cpu = row_cpu['realtime|mean']

            if not realtime_cpu.empty:
                df.loc[idx, 'speedup_gpu'] = realtime_cpu.values[0] / row['realtime|mean']

    # save output dataframe
    df.to_csv(args_output, sep='\t', index=False)

if __name__ == '__main__':
    main()