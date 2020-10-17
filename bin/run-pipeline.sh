#!/bin/bash
# Run a Nextflow pipeline.

# parse command-line arguments
if [[ $# != 1 ]]; then
    echo "usage: $0 <pipeline-dir>"
    exit -1
fi

PIPELINE_DIR="$1"

# initialize environment
module purge
module load nextflow/20.07.1

# run nextflow pipeline
cd ${PIPELINE_DIR}

nextflow \
    -C nextflow.config \
    run \
    main.nf \
    -ansi-log true \
    -profile pbs,testing \
    -resume
