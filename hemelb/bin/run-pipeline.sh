#!/bin/bash
# Run hemelb benchmarking pipeline with the given input datasets and conditions file.

nextflow \
	-C hemelb/nextflow.config \
	run \
	hemelb/main.nf \
	-profile pbs
