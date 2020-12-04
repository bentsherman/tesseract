#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="hemelb/output-large-15"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run inference script
export TF_CPP_MIN_LOG_LEVEL="3"

# inputs = np n_sites hardware_type:onehot
python bin/predict.py \
    ${OUTPUT_DIR}/hemelb.realtime.${MODEL} \
    1 3850000 1 0 0
