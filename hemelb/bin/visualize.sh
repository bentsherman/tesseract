#!/bin/bash

FORMAT="png"

module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# PART 1: INPUT DATA, PRELIMINARY EXPERIMENTS
OUTPUT_DIR="hemelb/output-prelim"

echo "hemelb-site-counts"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-site-counts.txt \
    ${OUTPUT_DIR}/hemelb-site-counts.${FORMAT} \
    --plot-type bar \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "n_sites=Number of Sites" \
    --xaxis geometry \
    --yaxis n_sites \
    --select geometry=C0003,C0004,C0005,C0009,C0010,Cylinder \
    --rotate-xticklabels \
    --sort-yaxis \
    --color steelblue

echo "hemelb-sparsity"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-sparsity.txt \
    ${OUTPUT_DIR}/hemelb-sparsity.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "fluid_fraction_percent=Fluid Fraction (%)" \
    --xaxis geometry \
    --yaxis fluid_fraction_percent \
    --select geometry=C0003,C0004,C0005,C0009,C0010,Cylinder \
    --rotate-xticklabels \
    --sort-yaxis \
    --color steelblue

echo "hemelb-cut-edges"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-cut-edges.txt \
    ${OUTPUT_DIR}/hemelb-cut-edges.${FORMAT} \
    --plot-type bar \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "edges=Number of Cut Edges" \
    --xaxis np \
    --yaxis edges \
    --col geometry \
    --select geometry=C0003,Cylinder \
    --color steelblue

echo "hemelb-load-times"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-load-times.txt \
    ${OUTPUT_DIR}/hemelb-load-times.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis loadtime \
    --row geometry \
    --color steelblue

echo "hemelb-run-times"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-run-times.txt \
    ${OUTPUT_DIR}/hemelb-run-times.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis runtime \
    --row geometry \
    --color steelblue

# PART 2: EXECUTION PARAMETERS
OUTPUT_DIR="hemelb/output-small"

echo "hemelb-blocksize"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-blocksize.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "blocksize=CUDA Block Size" \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis blocksize \
    --yaxis throughput \
    --row geometry \
    --col hardware_type \
    --select hardware_type=p100,v100 \
    --select latticetype=D3Q15 \
    --select np=1 \
    --select ngpus=0 \
    --color steelblue

echo "hemelb-latticetype"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-latticetype.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "latticetype=Lattice Type" \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis latticetype \
    --yaxis throughput \
    --row geometry \
    --col hardware_type \
    --select blocksize=32 \
    --select hardware_type=cpu,p100,v100 \
    --select np=1 \
    --select ngpus=0 \
    --color steelblue

echo "hemelb-oversubscribe"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-oversubscribe.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput \
    --row geometry \
    --col hardware_type \
    --select blocksize=32 \
    --select hardware_type=p100,v100 \
    --select latticetype=D3Q15 \
    --select ngpus=1 \
    --color steelblue

# PART 3: STRONG SCALING STUDY
OUTPUT_DIR="hemelb/output-large"

echo "hemelb-exitcode"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.hemelb.txt \
    ${OUTPUT_DIR}/hemelb-exitcode.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis exit \
    --col hardware_type \
    --palette muted

echo "hemelb-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.hemelb.txt \
    ${OUTPUT_DIR}/hemelb-realtime.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --hue hardware_type \
    --row geometry \
    --sharey \
    --height 2 \
    --aspect 1.5 \
    --yscale log \
    --palette muted

echo "hemelb-throughput"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-throughput.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput \
    --hue hardware_type \
    --row geometry \
    --sharey \
    --height 2 \
    --aspect 1.5 \
    --yscale log \
    --palette muted

echo "hemelb-throughput-aggregate"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-throughput-aggregate.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput \
    --hue hardware_type \
    --yscale log \
    --palette muted

echo "hemelb-throughput-per-core"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-throughput-per-core.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --mapper-term "throughput_per_core=Per-core Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput_per_core \
    --hue hardware_type \
    --yscale log \
    --palette muted

echo "hemelb-speedup-np"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-speedup-np.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_np \
    --hue hardware_type \
    --row geometry \
    --sharey \
    --ymin 0 \
    --height 2 \
    --aspect 1.5 \
    --palette muted

echo "hemelb-efficiency"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-efficiency.${FORMAT} \
    --plot-type point \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis efficiency \
    --hue hardware_type \
    --row geometry \
    --sharey \
    --ymin 0 \
    --ymax 1 \
    --height 2 \
    --aspect 1.5 \
    --palette muted

echo "hemelb-speedup-gpu"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-speedup-gpu.${FORMAT} \
    --mapper-file files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_gpu \
    --col hardware_type \
    --row geometry \
    --select hardware_type=p100,v100 \
    --sharey \
    --ymin 0 \
    --height 2 \
    --aspect 1.5 \
    --color steelblue
