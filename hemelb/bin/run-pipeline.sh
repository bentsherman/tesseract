#!/bin/bash
# Run hemelb benchmarking pipeline with the given input datasets and conditions file.

module purge
module load nextflow/20.07.1

nextflow \
	-C hemelb/nextflow.config \
	run \
	hemelb/main.nf \
	-ansi-log true \
	-profile pbs
