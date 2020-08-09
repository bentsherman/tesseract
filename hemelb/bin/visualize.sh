#!/bin/bash

TRACE_FILE="trace.txt"
FORMAT="png"

module purge
module add anaconda3/5.1.0

source activate mlbd

# python bin/visualize.py \
#     hemelb-site-counts.txt \
#     hemelb-site-counts.${FORMAT} \
#     --plot-type bar \
#     --mapper files/visualize-mapper.txt \
#     --xaxis geometry \
#     --yaxis n_sites \
#     --select geometry=C0003,C0004,C0005,C0009,C0010,Cylinder

# python bin/visualize.py \
#     hemelb-sparsity.txt \
#     hemelb-sparsity.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis geometry \
#     --yaxis fluid_fraction_percent \
#     --select geometry=C0003,C0004,C0005,C0009,C0010,Cylinder

# python bin/visualize.py \
#     hemelb-cut-edges.txt \
#     hemelb-cut-edges.${FORMAT} \
#     --plot-type bar \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis edges \
#     --col geometry \
#     --select geometry=C0003,Cylinder

# python bin/visualize.py \
#     hemelb-load-times.txt \
#     hemelb-load-times.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis loadtime \
#     --row geometry

# python bin/visualize.py \
#     hemelb-run-times.txt \
#     hemelb-run-times.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis runtime \
#     --row geometry

# python bin/visualize.py \
#     ${TRACE_FILE} \
#     hemelb-blocksize.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis blocksize \
#     --yaxis realtime \
#     --row geometry \
#     --col gpu_model \
#     --select status=CACHED,COMPLETED \
#     --select gpu_model=p100,v100 \
#     --select latticetype=D3Q15 \
#     --select np=1

# python bin/visualize.py \
#     ${TRACE_FILE} \
#     hemelb-latticetype.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis latticetype \
#     --yaxis realtime \
#     --row geometry \
#     --col gpu_model \
#     --select status=CACHED,COMPLETED \
#     --select gpu_model=p100,v100 \
#     --select np=1

python bin/visualize.py \
    speedup.txt \
    hemelb-throughput.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis throughput \
    --col gpu_model \
    --row geometry

# python bin/visualize.py \
#     speedup.txt \
#     hemelb-efficiency.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis efficiency \
#     --col gpu_model \
#     --row geometry

python bin/visualize.py \
    speedup.txt \
    hemelb-speedup-np.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_np \
    --col gpu_model \
    --row geometry

# python bin/visualize.py \
#     speedup.txt \
#     hemelb-efficiency-np.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis efficiency_np \
#     --col gpu_model \
#     --row geometry

python bin/visualize.py \
    speedup.txt \
    hemelb-speedup-gpu.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis speedup_gpu \
    --col gpu_model \
    --row geometry \
    --select gpu_model=p100,v100

python bin/visualize.py \
    ${TRACE_FILE} \
    hemelb-realtime.${FORMAT} \
    --mapper files/visualize-mapper.txt \
    --xaxis np \
    --yaxis realtime \
    --col gpu_model \
    --row geometry \
    --select status=CACHED,COMPLETED \
    --select gpu_model=cpu,p100,v100 \
    --select latticetype=D3Q15

# python bin/visualize.py \
#     ${TRACE_FILE} \
#     hemelb-realtime-cpu.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis realtime \
#     --col gpu_model \
#     --row geometry \
#     --select status=CACHED,COMPLETED \
#     --select gpu_model=cpu \
#     --select latticetype=D3Q15

# python bin/visualize.py \
#     ${TRACE_FILE} \
#     hemelb-realtime-gpu.${FORMAT} \
#     --mapper files/visualize-mapper.txt \
#     --xaxis np \
#     --yaxis realtime \
#     --col gpu_model \
#     --row geometry \
#     --select status=CACHED,COMPLETED \
#     --select gpu_model=p100,v100 \
#     --select latticetype=D3Q15
