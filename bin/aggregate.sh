#!/bin/bash

# parse command-line arguments
if [[ $# != 2 ]]; then
        echo "usage: $0 <input-dir> <output-dir>"
        exit -1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run aggregate script
python bin/aggregate.py \
    ${INPUT_DIR}/trace.*.txt \
    --output-dir ${OUTPUT_DIR} \
    --fix-exit-na -1 \
    --fix-runtime-ms
