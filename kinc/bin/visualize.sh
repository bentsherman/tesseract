#!/bin/bash

FORMAT="png"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# PART 1: strong scaling analysis (np)
OUTPUT_DIR="kinc/output-02"

echo "kinc-np-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-exit.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis exit \
    --col gpu_model \
    --palette muted

echo "kinc-np-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-realtime.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --hue gpu_model \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette muted

echo "kinc-np-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-peak_rss.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis peak_rss \
    --hue gpu_model \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

echo "kinc-np-peak_vmem"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-peak_vmem.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis peak_vmem \
    --hue gpu_model \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

echo "kinc-np-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-read_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis read_bytes \
    --hue gpu_model \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

echo "kinc-np-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-write_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis write_bytes \
    --hue gpu_model \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

# PART 1: weak scaling analysis (dataset)
OUTPUT_DIR="kinc/output-05"

echo "kinc-dataset-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-exit.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis exit \
    --col gpu_model \
    --palette muted

echo "kinc-dataset-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-realtime.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis realtime \
    --hue gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette muted \
    --rotate-xticklabels

echo "kinc-dataset-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-peak_rss.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis peak_rss \
    --hue gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

echo "kinc-dataset-peak_vmem"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-peak_vmem.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis peak_vmem \
    --hue gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

echo "kinc-dataset-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-read_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis read_bytes \
    --hue gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

echo "kinc-dataset-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-dataset-write_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis dataset \
    --yaxis write_bytes \
    --hue gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

# PART 3: strong scaling analysis (dataset, np)
OUTPUT_DIR="kinc/output-04"

echo "kinc-np-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-exit.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis exit \
    --row dataset \
    --col gpu_model

echo "kinc-np-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-realtime.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --hue dataset \
    --col gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette viridis

echo "kinc-np-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-peak_rss.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis peak_rss \
    --hue dataset \
    --col gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis

echo "kinc-np-peak_vmem"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-peak_vmem.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis peak_vmem \
    --hue dataset \
    --col gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis

echo "kinc-np-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-read_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis read_bytes \
    --hue dataset \
    --col gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis

echo "kinc-np-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.kinc.txt \
    ${OUTPUT_DIR}/kinc-np-write_bytes.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis write_bytes \
    --hue dataset \
    --col gpu_model \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis
