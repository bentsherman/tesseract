#!/bin/bash
# Generate conditions file for some basic kinc experiments.

OUTPUT_DIR="workflows/kinc/input"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

bin/make-conditions.py \
	--default similarity_chunkrun=true \
	--default similarity_hardware_type=p100 \
	--default similarity_threads=2 \
	--default corrpower=true \
	--default condtest=true \
	--default extract=true \
	--experiment-outer similarity_hardware_type=cpu,p100,v100 similarity_chunks=4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-chunk.txt"

bin/make-conditions.py \
	--default similarity_chunkrun=false \
	--default similarity_chunks=1 \
	--default similarity_hardware_type=p100 \
	--default similarity_threads=2 \
	--default corrpower=false \
	--default condtest=false \
	--default extract=false \
	--experiment-outer similarity_hardware_type=cpu,p100,v100 similarity_chunks=1,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-mpi.txt"
