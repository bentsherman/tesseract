#!/bin/bash

MODEL="mlp"
OUTPUT_DIR="kinc/output-04"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# run inference script
export TF_CPP_MIN_LOG_LEVEL="3"

python bin/predict.py \
    ${OUTPUT_DIR}/kinc.runtime_hr.${MODEL} \
    np=1 \
    n_rows=7050 \
    n_cols=188 \
    hardware_type_cpu=1 \
    hardware_type_p100=0 \
    hardware_type_v100=0
