#!/bin/bash
# Generate conditions file for some basic kinc experiments.

OUTPUT_DIR="kinc/input"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/make-conditions.py \
	--default hardware_type=p100 \
	--default threads=2 \
	--default clusmethod=gmm \
	--default corrmethod=spearman \
	--default preout=true \
	--default postout=true \
	--default bsize=32768 \
	--default gsize=4096 \
	--default lsize=32 \
	--default np=1 \
	--experiment hardware_type=cpu,p100,v100 np=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-np.txt"

python bin/make-conditions.py \
	--default hardware_type=p100 \
	--default threads=2 \
	--default clusmethod=gmm \
	--default corrmethod=spearman \
	--default preout=true \
	--default postout=true \
	--default bsize=32768 \
	--default gsize=4096 \
	--default lsize=32 \
	--default np=1 \
	--experiment hardware_type=cpu,p100,v100 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-dataset.txt"
