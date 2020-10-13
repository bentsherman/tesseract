#!/bin/bash
# Run kinc benchmarking pipeline with the given input datasets.

module purge
module load nextflow/20.07.1

nextflow \
	-C kinc/nextflow.config \
	run \
	kinc/main.nf \
	-ansi-log true \
	-profile pbs \
	-resume
