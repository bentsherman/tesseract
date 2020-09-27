#!/bin/bash

OUTPUT_DIR="hemelb/output-large"

module purge
module add anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/compute-speedup.py \
    ${OUTPUT_DIR}/trace.txt \
    hemelb/output-prelim/hemelb-site-counts.txt \
    ${OUTPUT_DIR}/speedup.txt
