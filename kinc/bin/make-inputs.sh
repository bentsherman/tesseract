#!/bin/bash
# Generate input files for some basic kinc experiments.

# parse command-line arguments
if [[ $# != 3 ]]; then
    echo "usage: $0 <infile> <n-row-iters> <n-col-iters>"
    exit -1
fi

INFILE="$1"
N_ROW_ITERS="$2"
N_COL_ITERS="$3"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

# generate partial datsets
echo 'generating datasets...'

DIRNAME=$(dirname ${INFILE})
BASENAME=$(basename ${INFILE} .emx.txt)

python kinc/bin/make-inputs.py \
    --dataset ${INFILE} \
    --labels ${DIRNAME}/${BASENAME}.labels.txt \
    --n-row-iters ${N_ROW_ITERS} \
    --n-col-iters ${N_COL_ITERS}

# convert emx txt files to emx files
echo 'converting datasets info emx format...'

for EMX_TXT_FILE in ${DIRNAME}/${BASENAME}.*.emx.txt; do
    EMX_FILE="${DIRNAME}/$(basename ${EMX_TXT_FILE} .txt)"

    echo ${EMX_FILE}

    singularity exec \
        --bind ${TMPDIR} \
        --bind ${PWD} \
        "${NXF_SINGULARITY_CACHEDIR}/systemsgenetics-kinc-3.4.2-cpu.img" \
    kinc run import-emx \
        --input ${EMX_TXT_FILE} \
        --output ${EMX_FILE} \
        > /dev/null
done
