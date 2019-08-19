#!/bin/bash
# Generate a filename from a list of metadata values.

# parse command-line arguments
if [[ $# == 0 ]]; then
	echo "usage: $0 <tokens> ..."
	exit -1
fi

# create filename from metadata values
echo $@ | tr '.' '-' | tr ' ' '.'
