#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
EMX_FILES = Channel.fromFilePairs("${params.input_dir}/*.emx", size: 1, flat: true)



/**
 * Send input files to each process that uses them.
 */
EMX_FILES
	.into {
		EMX_FILES_FOR_THREADS;
		EMX_FILES_FOR_BSIZE;
		EMX_FILES_FOR_GSIZE;
		EMX_FILES_FOR_LSIZE;
		EMX_FILES_FOR_SCALABILITY_V1;
		EMX_FILES_FOR_SCALABILITY_CPU;
		EMX_FILES_FOR_SCALABILITY_GPU
	}



/**
 * The threads process performs a single run of KINC with a
 * specific number of host threads.
 */
process threads {
	tag "${dataset}/${gpu_model}/${threads}"
	publishDir "${params.output_dir}/${dataset}/${gpu_model}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_THREADS
		each(gpu_model) from Channel.from( params.gpu_models )
		each(threads) from Channel.from( params.threads.values )

	when:
		params.threads.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${threads}
		kinc settings set buffer 4
		kinc settings set logging off

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
 * The bsize process performs a single run of KINC with a
 * specific work block size.
 */
process bsize {
	tag "${dataset}/${gpu_model}/${bsize}"
	publishDir "${params.output_dir}/${dataset}/${gpu_model}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_BSIZE
		each(gpu_model) from Channel.from( params.gpu_models )
		each(bsize) from Channel.from( params.bsize.values )

	when:
		params.bsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		kinc run similarity \
			--input ${emx_file} \
			--ccm ${dataset}.ccm \
			--cmx ${dataset}.cmx \
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
	tag "${dataset}/${gpu_model}/${gsize}"
	publishDir "${params.output_dir}/${dataset}/${gpu_model}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_GSIZE
		each(gpu_model) from Channel.from( params.gpu_models )
		each(gsize) from Channel.from( params.gsize.values )

	when:
		params.gsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		kinc run similarity \
			--input ${emx_file} \
			--ccm ${dataset}.ccm \
			--cmx ${dataset}.cmx \
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
	tag "${dataset}/${gpu_model}/${lsize}"
	publishDir "${params.output_dir}/${dataset}/${gpu_model}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_LSIZE
		each(gpu_model) from Channel.from( params.gpu_models )
		each(lsize) from Channel.from( params.lsize.values )

	when:
		params.lsize.enabled == true

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

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
			--lsize ${lsize}
		"""
}



/**
 * The scalability_v1 process performs a single run of KINCv1 with a
 * specific number of processes.
 */
process scalability_v1 {
	tag "${dataset}/${np}"
	publishDir "${params.output_dir}/${dataset}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_V1
		each(np) from Channel.from( params.scalability_v1.values )

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
	tag "${dataset}/${np}"
	publishDir "${params.output_dir}/${dataset}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_CPU
		each(np) from Channel.from( params.scalability_cpu.values )

	when:
		params.scalability_cpu.enabled == true

	beforeScript "mpirun sleep 10"

	script:
		"""
		kinc settings set cuda none
		kinc settings set opencl none
		kinc settings set logging off

		mpirun -np ${np} kinc run similarity \
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
 * The scalability_gpu process performs a single run of KINC with a
 * specific number of GPU processes.
 */
process scalability_gpu {
	tag "${dataset}/${gpu_model}/${np}"
	publishDir "${params.output_dir}/${dataset}/${gpu_model}"

	input:
		set val(dataset), file(emx_file) from EMX_FILES_FOR_SCALABILITY_GPU
		each(gpu_model) from Channel.from( params.gpu_models )
		each(np) from Channel.from( params.scalability_gpu.values )

	when:
		params.scalability_gpu.enabled == true

	beforeScript "mpirun sleep 10"

	script:
		"""
		kinc settings set cuda 0
		kinc settings set threads ${params.defaults.threads}
		kinc settings set buffer 4
		kinc settings set logging off

		mpirun -np ${np} kinc run similarity \
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
