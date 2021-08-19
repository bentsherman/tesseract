#!/bin/bash

# parse command-line arguments
if [[ $# != 2 ]]; then
        echo "usage: $0 <trace-files> <output-dir>"
        exit -1
fi

TRACE_FILES="$1"
OUTPUT_DIR="$2"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

# run aggregate script
python bin/aggregate.py \
    ${TRACE_FILES} \
    --output-dir ${OUTPUT_DIR} \
    --fix-exit-na -1
