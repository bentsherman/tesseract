#!/bin/bash
# Generate conditions file for some basic kinc experiments.

OUTPUT_DIR="kinc/input"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

bin/make-conditions.py \
	--default similarity_chunkrun=true \
	--default similarity_chunks=1 \
	--default similarity_hardware_type=p100 \
	--default similarity_threads=2 \
	--default corrpower_enabled=true \
	--default condtest_enabled=true \
	--default extract_enabled=true \
	--experiment-outer similarity_hardware_type=cpu,p100,v100 similarity_chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-chunk.txt"

bin/make-conditions.py \
	--default similarity_chunkrun=false \
	--default similarity_chunks=1 \
	--default similarity_hardware_type=p100 \
	--default similarity_threads=2 \
	--default corrpower_enabled=false \
	--default condtest_enabled=false \
	--default extract_enabled=false \
	--experiment-outer similarity_hardware_type=cpu,p100,v100 similarity_chunks=1,2,4,8,16 \
	--remove-duplicates \
	--output-file "${OUTPUT_DIR}/conditions-mpi.txt"
