#!/bin/bash
# Generate conditions file for some basic kinc experiments.

# parse command-line arguments
if [[ $# != 3 ]]; then
    echo "usage: $0 <infile> <n-row-iters> <n-col-iters>"
    exit -1
fi

INFILE="$1"
N_ROW_ITERS="$2"
N_COL_ITERS="$3"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# generate partial datsets
python kinc/bin/make-inputs.py \
    --dataset ${INFILE} \
    --n-row-iters ${N_ROW_ITERS} \
    --n-col-iters ${N_COL_ITERS}
