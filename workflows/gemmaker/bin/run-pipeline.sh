#!/bin/bash
# Run a Nextflow pipeline.

# initialize environment
module purge
module load nextflow/21.04.1

# clear GEMmaker staging directory (when changing input data)
rm -rf ${NXF_WORK}/GEMmaker

# clear output directory
rm -rf results

# run nextflow pipeline
nextflow \
    -c ${HOME}/workspace/configs/conf/palmetto.config \
    run \
    systemsgenetics/gemmaker \
    -r dev \
    -profile singularity \
    --pipeline kallisto \
    --kallisto_index_path input/references/Arabidopsis_thaliana.TAIR10.kallisto.indexed \
    --sras input/SRA_IDs.txt \
    --publish_dir_mode symlink \
    --max_cpus 50 \
    -resume
