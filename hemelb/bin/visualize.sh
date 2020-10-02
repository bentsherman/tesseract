#!/bin/bash

FORMAT="png"

module purge
module add anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# PART 1: INPUT DATA, PRELIMINARY EXPERIMENTS
OUTPUT_DIR="hemelb/output-prelim"

echo "hemelb-site-counts"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-site-counts.txt \
    ${OUTPUT_DIR}/hemelb-site-counts.${FORMAT} \
    --plot-type bar \
    --mapper files/visualize-mapper.txt \
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
    --mapper files/visualize-mapper.txt \
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
    --mapper files/visualize-mapper.txt \
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
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis loadtime \
    --row geometry \
    --color steelblue

echo "hemelb-run-times"
python bin/visualize.py \
    ${OUTPUT_DIR}/hemelb-run-times.txt \
    ${OUTPUT_DIR}/hemelb-run-times.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis runtime \
    --row geometry \
    --color steelblue

# PART 2: EXECUTION PARAMETERS
OUTPUT_DIR="hemelb/output-small"

echo "hemelb-blocksize"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/hemelb-blocksize.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --mapper-term "blocksize=CUDA Block Size" \
    --xaxis blocksize \
    --yaxis realtime \
    --row geometry \
    --col gpu_model \
    --select gpu_model=p100,v100 \
    --select latticetype=D3Q15 \
    --select np=1 \
    --select ngpus=0 \
    --color steelblue

echo "hemelb-latticetype"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/hemelb-latticetype.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --mapper-term "latticetype=Lattice Type" \
    --xaxis latticetype \
    --yaxis realtime \
    --row geometry \
    --col gpu_model \
    --select gpu_model=cpu,p100,v100 \
    --select np=1 \
    --select ngpus=0 \
    --color steelblue

echo "hemelb-oversubscribe"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/hemelb-oversubscribe.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --row geometry \
    --col gpu_model \
    --select gpu_model=p100,v100 \
    --select ngpus=1 \
    --color steelblue

# PART 3: STRONG SCALING STUDY
OUTPUT_DIR="hemelb/output-large"

echo "hemelb-exitcode"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/hemelb-exitcode.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis exit \
    --col gpu_model \
    --palette muted

echo "hemelb-realtime"
python bin/visualize.py \
    ${OUTPUT_DIR}/trace.txt \
    ${OUTPUT_DIR}/hemelb-realtime.${FORMAT} \
    --plot-type point \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --hue gpu_model \
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
    --mapper files/visualize-mapper.txt \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput \
    --hue gpu_model \
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
    --mapper files/visualize-mapper.txt \
    --mapper-term "throughput=Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput \
    --hue gpu_model \
    --yscale log \
    --palette muted

echo "hemelb-throughput-per-core"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-throughput-per-core.${FORMAT} \
    --plot-type point \
    --mapper files/visualize-mapper.txt \
    --mapper-term "throughput_per_core=Per-core Throughput (SUP/s)" \
    --xaxis np \
    --yaxis throughput_per_core \
    --hue gpu_model \
    --yscale log \
    --palette muted

echo "hemelb-speedup-np"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-speedup-np.${FORMAT} \
    --plot-type point \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_np \
    --hue gpu_model \
    --row geometry \
    --sharey \
    --height 2 \
    --aspect 1.5 \
    --palette muted

echo "hemelb-efficiency"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-efficiency.${FORMAT} \
    --plot-type point \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis efficiency \
    --hue gpu_model \
    --row geometry \
    --sharey \
    --height 2 \
    --aspect 1.5 \
    --palette muted

echo "hemelb-speedup-gpu"
python bin/visualize.py \
    ${OUTPUT_DIR}/speedup.txt \
    ${OUTPUT_DIR}/hemelb-speedup-gpu.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_gpu \
    --col gpu_model \
    --row geometry \
    --select gpu_model=p100,v100 \
    --sharey \
    --height 2 \
    --aspect 1.5 \
    --color steelblue
