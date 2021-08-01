#!/bin/bash

MODEL_TYPE="mlp"
OUTPUT_DIR="kinc/output-04"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run training script
export TF_CPP_MIN_LOG_LEVEL="3"

python bin/train.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    --inputs hardware_type np n_rows n_cols \
    --output runtime_hr \
    --scaler maxabs \
    --model-type ${MODEL_TYPE} \
    --model-name ${OUTPUT_DIR}/kinc.runtime_hr.${MODEL_TYPE}
