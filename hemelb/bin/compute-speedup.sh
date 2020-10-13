#!/bin/bash

if [[ $# != 1 ]]; then
        echo "usage: $0 <output-dir>"
        exit -1
fi

OUTPUT_DIR="$1"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/compute-speedup.py \
    ${OUTPUT_DIR}/trace.txt \
    hemelb/output-prelim/hemelb-site-counts.txt \
    ${OUTPUT_DIR}/speedup.txt
