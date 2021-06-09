#!/bin/bash
# Generate conditions file for some basic tspg experiments.

OUTPUT_DIR="tspg/data"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/make-conditions.py \
	--default conda_env=mlbd \
	--default input.dir=input \
	--default input.gmt_file=thyroid.genesets.txt \
	--default input.target_class=thca-rsem-fpkm-tcga-t \
	--experiment-inner \
		input.train_data=thyroid.{1-9}.train.emx.txt \
		input.train_labels=thyroid.{1-9}.train.labels.txt \
		input.perturb_data=thyroid.{1-9}.perturb.emx.txt \
		input.perturb_labels=thyroid.{1-9}.perturb.labels.txt \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions.txt"
