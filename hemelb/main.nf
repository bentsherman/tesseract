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
	publishDir "${params.output.dir}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES
		set val(geometry), file(xml_file) from XML_FILES
		each(c) from CONDITIONS
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	output:
		val(c) into CONDITIONS_AUGMENTED
		file("*.nvprof.txt")

	script:
		"""
		# augment conditions with additional features
		# ${c = c.clone()}
		# ${c.task_id = task.index}
		# ${c.geometry = geometry}
		# ${c.trial = trial}

		# TODO: only use gpu 0 for oversubscribe experiment
		# export CUDA_VISIBLE_DEVICES=0

		# modify config file
		cp ${xml_file} config.xml

		if [[ ${c.gpu_model} == "cpu" ]]; then
			sed 's/use_gpu="1"/use_gpu="0"/' config.xml > tmp; mv tmp config.xml
		fi

		sed 's/blocksize="[0-9]+"/blocksize="${c.blocksize}"/' config.xml > tmp; mv tmp config.xml

		# generate nvprof filename
		NVPROF_FILE="${task.index}.%p.nvprof.txt"

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
			-out results
		"""
}



/**
 * Collect augmented conditions into a csv file.
 */
CONDITIONS_AUGMENTED
	.map {
		it.keySet().join('\t') + '\n' + it.values().join('\t') + '\n'
	}
	.collectFile(
		keepHeader: true,
		name: "conditions.txt",
		storeDir: "${params.output.dir}"
	)
