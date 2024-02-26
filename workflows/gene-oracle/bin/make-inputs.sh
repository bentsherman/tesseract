#!/bin/bash
# Generate input files for some basic gene-oracle experiments.

# parse command-line arguments
if [[ $# != 1 ]]; then
    echo "usage: $0 <emx-file>"
    exit -1
fi

EMX_FILE="$1"
MIN_GENES=5
MAX_GENES=20
N_SETS="32 64 128 256 512 1024"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

# generate partial datsets
python bin/make-inputs.py \
    --dataset ${EMX_FILE} \
    --min-genes ${MIN_GENES} \
    --max-genes ${MAX_GENES} \
    --n-sets ${N_SETS}
