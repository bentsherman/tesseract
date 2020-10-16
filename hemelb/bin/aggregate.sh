#!/bin/bash

if [[ $# != 1 ]]; then
        echo "usage: $0 <output-dir>"
        exit -1
fi

OUTPUT_DIR="$1"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/aggregate.py \
    ${OUTPUT_DIR}/reports/trace.txt \
    --output-dir ${OUTPUT_DIR} \
    --fix-exit-na -1 \
    --fix-runtime-ms
