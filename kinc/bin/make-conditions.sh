#!/bin/bash
# Generate conditions file for some basic kinc experiments.

python bin/make-conditions.py \
	--default gpu_model=1080ti \
	--default revision=master \
	--default threads=1 \
	--default clusmethod=gmm \
	--default corrmethod=spearman \
	--default preout=true \
	--default postout=true \
	--default bsize=32768 \
	--default gsize=4096 \
	--default lsize=32 \
	--default np=1 \
	--experiment revision=v3.3.0,master \
	--experiment threads=1,2,3,4,5,6,7,8 \
	--experiment bsize=1024,2048,4096,8192,16384,32768 \
	--experiment gsize=1024,2048,4096,8192,16384,32768 \
	--experiment lsize=16,32,64,128,256,512 \
	--experiment gpu_model=cpu,1080ti np=1,2,4,8
