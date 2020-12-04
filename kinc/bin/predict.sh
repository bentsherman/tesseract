#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="kinc/output-04"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run inference script
export TF_CPP_MIN_LOG_LEVEL="3"

# inputs = np n_rows n_cols hardware_type:onehot
# output = realtime:log2
python bin/predict.py \
    ${OUTPUT_DIR}/kinc.realtime.${MODEL}.pkl \
    --model ${MODEL} \
    --output-transform exp2 \
    --inputs 1 7050 188 1 0 0
