#!/bin/bash
# Generate conditions file for some basic tspg experiments.

OUTPUT_DIR="tspg/data"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

python bin/make-conditions.py \
	--default conda_env=mlbd \
	--default input_dir=input \
	--default gmt_file=thyroid.genesets.txt \
	--default target_class=thca-rsem-fpkm-tcga-t \
	--experiment-inner \
		train_data=thyroid.{1-9}.train.emx.txt \
		train_labels=thyroid.{1-9}.train.labels.txt \
		perturb_data=thyroid.{1-9}.perturb.emx.txt \
		perturb_labels=thyroid.{1-9}.perturb.labels.txt \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions.txt"
