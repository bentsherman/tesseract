#!/bin/bash

OUTPUT_DIR="kinc/output"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/aggregate.py \
    --trace-input ${OUTPUT_DIR}/reports/trace.txt \
    --trace-output ${OUTPUT_DIR}/trace.txt \
    --fix-exit-na -1 \
    --fix-runtime-ms
