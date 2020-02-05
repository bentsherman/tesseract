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
	// tag "${revision}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES
		each(c) from CONDITIONS
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	output:
		file("*.nvprof.txt")

	script:
		"""
		kinc settings set cuda ${c.gpu_model == "cpu" ? "none" : "0"}
		kinc settings set opencl none
		kinc settings set threads ${c.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		# generate nvprof filename
		NVPROF_FILE=\$(make-filename.sh \
			"revision=${c.revision}" \
			"dataset=${dataset}" \
			"gpu_model=${c.gpu_model}" \
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
		taskset -c 0-${c.threads} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${c.clusmethod} \
			--corrmethod ${c.corrmethod} \
			--preout ${c.preout} \
			--postout ${c.postout} \
			--bsize ${c.bsize} \
			--gsize ${c.gsize} \
			--lsize ${c.lsize}
		"""
}
