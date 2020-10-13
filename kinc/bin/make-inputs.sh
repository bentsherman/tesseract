#!/bin/bash
# Generate conditions file for some basic kinc experiments.

# parse command-line arguments
if [[ $# != 1 ]]; then
        echo "usage: $0 <infile>"
        exit -1
fi

INFILE="$1"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1
module load kinc/v3.4.2

source activate mlbd

# generate input files
python kinc/bin/make-inputs.py \
	--dataset kinc/data/Yeast.emx.txt \
	--n-outputs 10

# convert emx txt files to emx files
for INFILE in kinc/data/*.emx.txt; do
    BASENAME="$(basename ${INFILE} .emx.txt)"
    EMX_FILE="kinc/data/${BASENAME}.emx"

    echo ${EMX_FILE}

    kinc run import-emx \
        --input ${INFILE} \
        --output ${EMX_FILE} \
        > /dev/null
done