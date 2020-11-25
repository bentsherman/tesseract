#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="kinc/output-04"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run training script
export TF_CPP_MIN_LOG_LEVEL="3"

python bin/train.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    --inputs gpu_model:onehot np n_rows n_cols \
    --output realtime:log2 \
    --scaler maxabs \
    --model ${MODEL} \
    --model-file ${OUTPUT_DIR}/kinc.realtime.${MODEL}.pkl
