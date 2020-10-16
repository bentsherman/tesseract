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

# generate partial datsets
echo 'generating partial datasets...'

python kinc/bin/make-inputs.py \
    --dataset ${INFILE} \
    --n-row-iters 8 \
    --n-col-iters 4

# convert emx txt files to emx files
echo 'converting datasets info emx format...'

DIRNAME=$(dirname ${INFILE})
BASENAME=$(basename ${INFILE} .emx.txt)

for EMX_TXT_FILE in ${DIRNAME}/${BASENAME}.*.emx.txt; do
    EMX_FILE="${DIRNAME}/$(basename ${EMX_TXT_FILE} .txt)"

    echo ${EMX_FILE}

    kinc run import-emx \
        --input ${EMX_TXT_FILE} \
        --output ${EMX_FILE} \
        > /dev/null
done