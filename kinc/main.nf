#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
EMX_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.emx_files}", size: 1, flat: true)



/**
 * Send input files to each process that uses them.
 */
EMX_FILES
	.into {
		EMX_FILES_FOR_REVISION;
		EMX_FILES_FOR_THREADS;
		EMX_FILES_FOR_BSIZE;
		EMX_FILES_FOR_GSIZE;
		EMX_FILES_FOR_LSIZE;
		EMX_FILES_FOR_SCALABILITY_V1;
		EMX_FILES_FOR_SCALABILITY_CPU;
		EMX_FILES_FOR_SCALABILITY_GPU
	}



/**
 * The revision process performs a single run of a specific
 * revision of KINC.
 */
process revision {
	tag "${revision}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(revision) from Channel.from( params.revision.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_REVISION
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	output:
		file("*.nvprof.txt")

	when:
		params.revision.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		NVPROF_FILE=\$(make-filename.sh revision "${revision}" "${dataset}" "${gpu_model}" "${trial}" nvprof txt)

		nvprof \
			--csv \
			--log-file \${NVPROF_FILE} \
			--normalized-time-unit ms \
			--unified-memory-profiling off \
		taskset -c 0-1 \
		kinc run similarity \
			--input ${emx_file} \
			--ccm ${dataset}.ccm \
			--cmx ${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${params.defaults.lsize}
		"""
}



/**
 * The threads process performs a single run of KINC with a
 * specific number of host threads.
 */
process threads {
	tag "${threads}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(threads) from Channel.from( params.threads.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_THREADS
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.threads.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${threads}
		kinc settings set buffer 4
		kinc settings set logging off

		taskset -c 0-${threads} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${params.defaults.lsize}
		"""
}



/**
 * The bsize process performs a single run of KINC with a
 * specific work block size.
 */
process bsize {
	tag "${bsize}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(bsize) from Channel.from( params.bsize.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_BSIZE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.bsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		taskset -c 0-${params.defaults.threads} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${params.defaults.lsize}
		"""
}



/**
 * The gsize process performs a single run of KINC with a
 * specific global work size.
 */
process gsize {
	tag "${gsize}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(gsize) from Channel.from( params.gsize.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_GSIZE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.gsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		taskset -c 0-${params.defaults.threads} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${gsize} \
			--lsize ${params.defaults.lsize}
		"""
}



/**
 * The lsize process performs a single run of KINC with a
 * specific local work size.
 */
process lsize {
	tag "${lsize}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(lsize) from Channel.from( params.lsize.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_LSIZE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.lsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		taskset -c 0-${params.defaults.threads} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${lsize}
		"""
}



/**
 * The scalability_v1 process performs a single run of KINCv1 with a
 * specific number of processes.
 */
process scalability_v1 {
	tag "${np}/${dataset}/v1/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.scalability_v1.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_V1
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.scalability_v1.enabled == true

	script:
		"""
		ROWS=\$(wc -l < ${emx_file})
		COLS=\$(awk -F ' ' '{print NF ; exit}' ${emx_file})

		for i in \$(seq 1 ${np}); do
			kinc similarity \
				--ematrix ${emx_file} \
				--rows \$ROWS \
				--cols \$COLS \
				--headers \
				--clustering mixmod \
				--criterion ICL \
				--method sc \
				--min_obs 30 \
				--omit_na \
				--na_val NA \
				--num_jobs ${np} \
				--job_index \$i &
		done

		wait
		"""
}



/**
 * The scalability_cpu process performs a single run of KINC with a
 * specific number of CPU processes.
 */
process scalability_cpu {
	tag "${np}/${dataset}/cpu/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.scalability_cpu.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_CPU
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.scalability_cpu.enabled == true

	script:
		"""
		kinc settings set cuda none
		kinc settings set opencl none
		kinc settings set logging off

		mpirun -np ${np} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${params.defaults.lsize}
		"""
}



DEFAULT_THREADS = [
	"p100": 2,
	"v100": 4
]



/**
 * The scalability_gpu process performs a single run of KINC with a
 * specific number of GPU processes.
 */
process scalability_gpu {
	tag "${np}/${dataset}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.scalability_gpu.values )
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_GPU
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.scalability_gpu.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${DEFAULT_THREADS.containsKey(gpu_model) ? DEFAULT_THREADS[gpu_model] : 1}
		kinc settings set buffer 4
		kinc settings set logging off

		mpirun -np ${np} \
		kinc run similarity \
			--input ${emx_file} \
			--ccm \${TMPDIR}/${dataset}.ccm \
			--cmx \${TMPDIR}/${dataset}.cmx \
			--clusmethod ${params.defaults.clusmethod} \
			--corrmethod ${params.defaults.corrmethod} \
			--preout ${params.defaults.preout} \
			--postout ${params.defaults.postout} \
			--bsize ${params.defaults.bsize} \
			--gsize ${params.defaults.gsize} \
			--lsize ${params.defaults.lsize}
		"""
}
