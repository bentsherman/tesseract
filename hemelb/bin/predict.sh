#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="hemelb/output-large-16"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run inference script
export TF_CPP_MIN_LOG_LEVEL="3"

# inputs = np n_sites gpu_model:onehot
# output = realtime:log2
python bin/predict.py \
    ${OUTPUT_DIR}/hemelb.realtime.${MODEL}.pkl \
    --model ${MODEL} \
    --output-transform exp2 \
    --inputs 1 3850000 1 0 0
