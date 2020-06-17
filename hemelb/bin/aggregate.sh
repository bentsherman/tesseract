#!/bin/bash

OUTPUT_DIR="hemelb/output-large"

python bin/aggregate.py \
    --conditions ${OUTPUT_DIR}/conditions.txt \
    --trace-input ${OUTPUT_DIR}/reports/trace.txt \
    --trace-output trace.txt \
    --fix-runtime-ms
