#!/bin/bash
# Generate conditions file for some basic gene-oracle experiments.

OUTPUT_DIR="gene-oracle/data"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

python bin/make-conditions.py \
	--default conda_env=tesseract \
	--default phase1=true \
	--default phase1_model=lr \
	--default phase1_random_min=1 \
	--default phase1_random_max=20 \
	--default phase1_random_iters=10 \
	--default phase1_threshold=1 \
	--default phase1_n_sets=-1 \
	--experiment-outer chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions.txt"
