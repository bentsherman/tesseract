#!/bin/bash

MODEL_TYPE="mlp"
OUTPUT_DIR="hemelb/output-large-15"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run training script
export TF_CPP_MIN_LOG_LEVEL="3"

python bin/train.py \
    ${OUTPUT_DIR}/trace.hemelb.txt \
    --merge geometry ${OUTPUT_DIR}/hemelb-site-counts.txt \
    --inputs hardware_type:onehot np n_sites \
    --output realtime:log2 \
    --scaler maxabs \
    --model-type ${MODEL_TYPE} \
    --model-name ${OUTPUT_DIR}/hemelb.realtime.${MODEL_TYPE}
