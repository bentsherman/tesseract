#!/bin/bash

FORMAT="png"

module purge
module load miniconda2/4.7.12.1 gcc/8.3.0

# PART 1: strong scaling analysis (np)
OUTPUT_DIR="workflows/tofu/output-02"

echo "tofu-np-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-exit.${FORMAT} \
    --xaxis np \
    --yaxis exit \
    --col hardware_type \
    --palette muted

echo "tofu-np-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-realtime.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis realtime \
    --hue hardware_type \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette muted

echo "tofu-np-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-peak_rss.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis peak_rss \
    --hue hardware_type \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

echo "tofu-np-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-read_bytes.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis read_bytes \
    --hue hardware_type \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

echo "tofu-np-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-write_bytes.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis write_bytes \
    --hue hardware_type \
    --row dataset \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted

# PART 1: weak scaling analysis (dataset)
OUTPUT_DIR="workflows/tofu/output-05"

echo "tofu-dataset-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-dataset-exit.${FORMAT} \
    --xaxis dataset \
    --yaxis exit \
    --col hardware_type \
    --palette muted

echo "tofu-dataset-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-dataset-realtime.${FORMAT} \
    --plot-type point \
    --xaxis dataset \
    --yaxis realtime \
    --hue hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette muted \
    --rotate-xticklabels

echo "tofu-dataset-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-dataset-peak_rss.${FORMAT} \
    --plot-type point \
    --xaxis dataset \
    --yaxis peak_rss \
    --hue hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

echo "tofu-dataset-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-dataset-read_bytes.${FORMAT} \
    --plot-type point \
    --xaxis dataset \
    --yaxis read_bytes \
    --hue hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

echo "tofu-dataset-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-dataset-write_bytes.${FORMAT} \
    --plot-type point \
    --xaxis dataset \
    --yaxis write_bytes \
    --hue hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette muted \
    --rotate-xticklabels

# PART 3: strong scaling analysis (dataset, np)
OUTPUT_DIR="workflows/tofu/output-04"

echo "tofu-np-exit"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-exit.${FORMAT} \
    --xaxis np \
    --yaxis exit \
    --row dataset \
    --col hardware_type

echo "tofu-np-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-realtime.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis realtime \
    --hue dataset \
    --col hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --yscale log \
    --palette viridis

echo "tofu-np-peak_rss"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-peak_rss.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis peak_rss \
    --hue dataset \
    --col hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis

echo "tofu-np-read_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-read_bytes.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis read_bytes \
    --hue dataset \
    --col hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis

echo "tofu-np-write_bytes"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.tofu.txt \
    ${OUTPUT_DIR}/tofu-np-write_bytes.${FORMAT} \
    --plot-type point \
    --xaxis np \
    --yaxis write_bytes \
    --hue dataset \
    --col hardware_type \
    --select exit=0 \
    --sharey \
    --aspect 1.5 \
    --palette viridis
