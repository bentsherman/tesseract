#!/bin/bash
# Generate conditions files for hemelb experiments.

OUTPUT_DIR="hemelb/input"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

python bin/make-conditions.py \
	--default blocksize=32 \
	--default gpu_model=cpu \
	--default latticetype=D3Q15 \
	--default np=1 \
	--default ngpus=0 \
	--experiment gpu_model=p100,v100 blocksize=16,32,64,128,256,512 \
	--experiment gpu_model=cpu,p100,v100 latticetype=D3Q15,D3Q19,D3Q27 \
	--experiment gpu_model=p100,v100 np=1,2,3,4,5,6,7,8 ngpus=1 \
	--remove-duplicates \
	--output-file ${OUTPUT_DIR}/conditions-small.txt

python bin/make-conditions.py \
	--default blocksize=32 \
	--default gpu_model=cpu \
	--default latticetype=D3Q15 \
	--default np=1 \
	--default ngpus=0 \
	--experiment gpu_model=cpu,p100,v100 np=1,2,4,8,16,32 \
	--remove-duplicates \
	--output-file ${OUTPUT_DIR}/conditions-large.txt
