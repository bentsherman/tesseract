#!/bin/bash
# Print dataset sizes for a list of GEMs.

# parse command-line arguments
if [[ $# != 1 ]]; then
        echo "usage: $0 <input-dir>"
        exit -1
fi

INPUT_DIR="$1"

# generate table of dataset sizes
printf "dataset\tn_rows\tn_cols\n"

for f in $(ls ${INPUT_DIR}/*.emx.txt); do
	DATASET=$(basename ${f} .emx.txt)
	N_ROWS=$(tail -n +1 ${f} | wc -l)
	N_COLS=$(head -n +1 ${f} | wc -w)

	printf "${DATASET}\t${N_ROWS}\t${N_COLS}\n"
done
