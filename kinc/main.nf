#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
EMX_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.emx_files}", size: 1, flat: true)
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
		set val(dataset), file(emx_file) from EMX_FILES
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
		# ${c.dataset = dataset}
		# ${c.trial = trial}

		kinc settings set cuda ${c.gpu_model == "cpu" ? "none" : "0"}
		kinc settings set opencl none
		kinc settings set threads ${c.threads}
		kinc settings set buffer 4
		kinc settings set logging off

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
		kinc run similarity \
			--input ${emx_file} \
			--ccm ${dataset}.ccm \
			--cmx ${dataset}.cmx \
			--clusmethod ${c.clusmethod} \
			--corrmethod ${c.corrmethod} \
			--preout ${c.preout} \
			--postout ${c.postout} \
			--bsize ${c.bsize} \
			--gsize ${c.gsize} \
			--lsize ${c.lsize}
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
