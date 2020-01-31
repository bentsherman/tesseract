#!/bin/bash
# Generate conditions file for some basic hemelb experiments.

python bin/make-conditions.py \
	--default blocksize=16 \
	--default gpu_model=1080ti \
	--default latticetype=D3Q15 \
	--default np=1 \
	--experiment blocksize=16,32,64,128,256,512 \
	--experiment latticetype=D3Q15,D3Q19,D3Q27 \
	--experiment gpu_model=cpu,1080ti np=1,2,4,8
