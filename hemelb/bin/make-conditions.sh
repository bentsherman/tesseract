#!/bin/bash
# Generate conditions file for some basic hemelb experiments.

python bin/make-conditions.py \
	--default blocksize=32 \
	--default gpu_model=p100 \
	--default latticetype=D3Q15 \
	--default np=1 \
	--experiment gpu_model=p100,v100 blocksize=16,32,64,128,256,512 \
	--experiment gpu_model=cpu,p100,v100 latticetype=D3Q15,D3Q19,D3Q27 \
	--remove-duplicates \
	--output-file conditions-small.txt

python bin/make-conditions.py \
	--default blocksize=32 \
	--default gpu_model=p100 \
	--default latticetype=D3Q15 \
	--default np=1 \
	--experiment gpu_model=cpu,p100,v100 np=1,2,4,8,16,32 \
	--remove-duplicates \
	--output-file conditions-large.txt
