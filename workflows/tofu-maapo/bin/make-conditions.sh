#!/bin/bash
# Generate conditions file for tofu experiments.
OUTPUT_DIR="workflows/tofu-maapo/input"

module purge
module load miniconda3/4.12.0 gcc/8.3.0

source activate tesseract

bin/make-conditions.py \
        --default assembly=true \
		--default publish_rawbins=true \
		--default genome=human \
		--default reads="input/testinput.csv" \
		--remove-duplicates \
		--experiment-outer max_memory=256.GB,128.GB,30000.GB max_cpus=24,16,30 \
		--output-file "${OUTPUT_DIR}/conditions.txt"
