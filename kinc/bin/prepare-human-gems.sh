#!/bin/bash
# Merge GEMs from GTEX / TCGA studies for each tissue type.

# define inputs
INPUT_DIR="/zfs/lasernode/feltuslab/mrbende/all-gtex-tcga"
MERGE_PY="${HOME}/workspace/gemprep/bin/merge.py"
NORMALIZE_PY="${HOME}/workspace/gemprep/bin/normalize.py"

# initialize environment
module purge
module load anaconda3/5.1.0-gcc/8.3.1

source activate mlbd

# prepare merged GEM for each tissue type
${MERGE_PY} \
    ${INPUT_DIR}/bladder-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/blca-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/blca-rsem-fpkm-tcga.txt \
    bladder.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/breast-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/brca-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/brca-rsem-fpkm-tcga.txt \
    breast.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/cervix-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/cesc-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/cesc-rsem-fpkm-tcga.txt \
    cervix.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/chol-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/chol-rsem-fpkm-tcga.txt \
    bile-duct.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/colon-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/coad-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/coad-rsem-fpkm-tcga.txt \
    colon.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/esophagus_gas-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/esophagus_muc-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/esophagus_mus-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/esca-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/esca-rsem-fpkm-tcga.txt \
    esophagus.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/hnsc-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/hnsc-rsem-fpkm-tcga.txt \
    head-neck.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/kidney-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/kich-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/kich-rsem-fpkm-tcga.txt \
    ${INPUT_DIR}/kirc-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/kirc-rsem-fpkm-tcga.txt \
    ${INPUT_DIR}/kirp-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/kirp-rsem-fpkm-tcga.txt \
    kidney.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/liver-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/lihc-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/lihc-rsem-fpkm-tcga.txt \
    liver.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/lung-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/luad-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/luad-rsem-fpkm-tcga.txt \
    ${INPUT_DIR}/lusc-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/lusc-rsem-fpkm-tcga.txt \
    lung.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/prostate-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/prad-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/prad-rsem-fpkm-tcga.txt \
    prostate.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/read-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/read-rsem-fpkm-tcga.txt \
    rectum.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/salivary-rsem-fpkm-gtex.txt \
    salivary.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/stomach-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/stad-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/stad-rsem-fpkm-tcga.txt \
    stomach.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/thyroid-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/thca-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/thca-rsem-fpkm-tcga.txt \
    thyroid.fpkm.txt

${MERGE_PY} \
    ${INPUT_DIR}/uterus-rsem-fpkm-gtex.txt \
    ${INPUT_DIR}/ucec-rsem-fpkm-tcga-t.txt \
    ${INPUT_DIR}/ucec-rsem-fpkm-tcga.txt \
    ${INPUT_DIR}/ucs-rsem-fpkm-tcga-t.txt \
    uterus.fpkm.txt

# normalize each fpkm matrix
for FPKM_TXT_FILE in *.fpkm.txt; do
    BASENAME=$(basename ${FPKM_TXT_FILE} .fpkm.txt)

    ${NORMALIZE_PY} \
        ${FPKM_TXT_FILE} \
        ${BASENAME}.emx.txt \
        --log2 \
        --quantile
done

# cleanup
rm -f *.fpkm.txt