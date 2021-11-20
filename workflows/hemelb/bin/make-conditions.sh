#!/bin/bash
# Generate conditions files for hemelb experiments.

OUTPUT_DIR="workflows/hemelb/input"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

bin/make-conditions.py \
	--default blocksize=512 \
	--default latticetype=D3Q19 \
	--default np=1 \
	--experiment-outer hardware_type=p100,v100 blocksize=32,64,128,256,512,1024 \
	--experiment-outer hardware_type=cpu,p100,v100 latticetype=D3Q15,D3Q19,D3Q27 \
	--remove-duplicates \
	--output-file ${OUTPUT_DIR}/conditions-small.txt

bin/make-conditions.py \
	--default blocksize=512 \
	--default latticetype=D3Q19 \
	--default np=1 \
	--experiment-outer hardware_type=cpu,p100,v100 np=1,2,4,8,16,32 \
	--remove-duplicates \
	--output-file ${OUTPUT_DIR}/conditions-large.txt
