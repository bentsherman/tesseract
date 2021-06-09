#!/bin/bash
# Generate input files for some basic tspg experiments.

# parse command-line arguments
if [[ $# != 2 ]]; then
    echo "usage: $0 <emx-file> <labels-file>"
    exit -1
fi

EMX_FILE="$1"
LABELS_FILE="$2"
MIN_GENES=5
MAX_GENES=20
N_SETS=100

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# generate partial datsets
python tspg/bin/make-inputs.py \
    --dataset ${EMX_FILE} \
    --labels ${LABELS_FILE} \
    --min-genes ${MIN_GENES} \
    --max-genes ${MAX_GENES} \
    --n-sets ${N_SETS}