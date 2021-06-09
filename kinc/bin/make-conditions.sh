#!/bin/bash
# Generate conditions file for some basic kinc experiments.

OUTPUT_DIR="kinc/data"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/make-conditions.py \
	--default similarity.chunkrun=true \
	--default similarity.chunks=1 \
	--default similarity.hardware_type=p100 \
	--default similarity.threads=2 \
	--default similarity.clusmethod=gmm \
	--default similarity.corrmethod=spearman \
	--default threshold_rmt.enabled=true \
	--default extract.enabled=true \
	--experiment-outer similarity.hardware_type=cpu,p100,v100 similarity.chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-chunk.txt"

python bin/make-conditions.py \
	--default similarity.chunkrun=false \
	--default similarity.chunks=1 \
	--default similarity.hardware_type=p100 \
	--default similarity.threads=2 \
	--default similarity.clusmethod=gmm \
	--default similarity.corrmethod=spearman \
	--default threshold_rmt.enabled=false \
	--default extract.enabled=false \
	--experiment-outer similarity.hardware_type=cpu,p100,v100 similarity.chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-mpi.txt"
