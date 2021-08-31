#!/bin/bash
# Query the list of Nautilus nodes.

kubectl get nodes -L gpu-type | awk '{ printf("[ \"node_type\": \"%s\", \"gpu_model\": \"%s\" ],\n", $1, $6) }'