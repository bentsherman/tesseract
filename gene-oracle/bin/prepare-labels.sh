#!/bin/bash

EMX_FILE="$1"
LABELS_FILE="$2"

# get list of samples
awk '{ print $1 }' ${EMX_FILE} | tail -n +2 > tmp1

# combine samples and labels
paste tmp1 ${LABELS_FILE} > tmp2

rm tmp1
mv tmp2 ${LABELS_FILE}