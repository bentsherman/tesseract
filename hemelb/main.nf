#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
GMY_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.gmy_files}", size: 1, flat: true)
XML_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.xml_files}", size: 1, flat: true)
CONDITIONS_FILE = Channel.fromPath("${params.input.dir}/${params.input.conditions_file}")



/**
 * Extract each set of input conditions from file.
 */
CONDITIONS_FILE
	.splitCsv(sep: "\t", header: true)
	.set { CONDITIONS }



/**
 * The run_experiment process performs a single run of the
 * application under test for each set of input conditions.
 */
process run_experiment {
	tag "geometry=${geometry}/blocksize=${c.blocksize}/gpu_model=${c.gpu_model}/latticetype=${c.latticetype}/np=${c.np}/trial=${trial}"
	publishDir "${params.output.dir}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES
		set val(geometry), file(xml_file) from XML_FILES
		each(c) from CONDITIONS
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	output:
		file("*.nvprof.txt")

	script:
		"""
		# TODO: only use gpu 0 for oversubscribe experiment
		# export CUDA_VISIBLE_DEVICES=0

		# modify config file
		cp ${xml_file} config.xml

		if [[ ${c.gpu_model} == "cpu" ]]; then
			sed 's/use_gpu="1"/use_gpu="0"/' config.xml > tmp; mv tmp config.xml
		fi

		sed 's/blocksize="[0-9]+"/blocksize="${c.blocksize}"/' config.xml > tmp; mv tmp config.xml

		# generate nvprof filename
		NVPROF_FILE=\$(make-filename.sh \
			"geometry=${geometry}" \
			"blocksize=${c.blocksize}" \
			"gpu_model=${c.gpu_model}" \
			"latticetype=${c.latticetype}" \
			"np=${c.np}" \
			"trial=${trial}" \
			"%p" nvprof txt)

		# run application
		nvprof \
			--csv \
			--log-file \${NVPROF_FILE} \
			--normalized-time-unit ms \
			--profile-child-processes \
			--unified-memory-profiling off \
		mpirun -np ${c.np} \
		hemelb \
			-in config.xml \
			-out \${TMPDIR}/results
		"""
}
