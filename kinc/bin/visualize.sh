#!/bin/bash

FORMAT="png"

module purge
module add anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

OUTPUT_DIR="kinc/output"

echo "kinc-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/kinc-realtime.${FORMAT} \
    --plot-type point \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --hue gpu_model \
    --row dataset \
    --select status=CACHED,COMPLETED \
    --select gpu_model=cpu,p100,v100 \
    --sharey \
    --aspect 1.5 \
    --palette muted
