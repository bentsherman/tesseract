#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="hemelb/output-large-15"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run inference script
export TF_CPP_MIN_LOG_LEVEL="3"

python bin/predict.py \
    ${OUTPUT_DIR}/hemelb.realtime.${MODEL} \
    np=1 \
    n_sites=3850000 \
    hardware_type_cpu=1 \
    hardware_type_p100=0 \
    hardware_type_v100=0
