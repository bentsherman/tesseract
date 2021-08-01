#!/bin/bash
# Generate conditions file for some basic gene-oracle experiments.

OUTPUT_DIR="gene-oracle/data"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/make-conditions.py \
	--default conda_env=mlbd \
	--default phase1.enabled=true \
	--default phase1.model=lr \
	--default phase1.random_min=1 \
	--default phase1.random_max=20 \
	--default phase1.random_iters=10 \
	--default phase1.threshold=1 \
	--default phase1.n_sets=-1 \
	--experiment-outer chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions.txt"
