#!/bin/bash

CONFIG_FILE="notebooks/00-pipelines.json"
RESULTS_FILE="notebooks/results.csv"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

export TF_CPP_MIN_LOG_LEVEL="3"

# run evaluation script
python bin/evaluate-models.py \
    ${CONFIG_FILE} \
    ${RESULTS_FILE}
