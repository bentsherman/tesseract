#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
GMY_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.gmy_files}", size: 1, flat: true)
XML_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.xml_files}", size: 1, flat: true)



/**
 * Send input files to each process that uses them.
 */
GMY_FILES
	.into {
		GMY_FILES_FOR_BLOCKSIZE;
		GMY_FILES_FOR_LATTICETYPE;
		GMY_FILES_FOR_OVERSUBSCRIBE;
		GMY_FILES_FOR_SCALABILITY_CPU;
		GMY_FILES_FOR_SCALABILITY_GPU
	}

XML_FILES
	.into {
		XML_FILES_FOR_BLOCKSIZE;
		XML_FILES_FOR_LATTICETYPE;
		XML_FILES_FOR_OVERSUBSCRIBE;
		XML_FILES_FOR_SCALABILITY_CPU;
		XML_FILES_FOR_SCALABILITY_GPU
	}



/**
 * The blocksize process performs a single run of HemelB with a
 * specific block size.
 */
process blocksize {
	tag "${blocksize}/${geometry}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(blocksize) from Channel.from( params.blocksize.values )
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_BLOCKSIZE
		set val(geometry), file(xml_file) from XML_FILES_FOR_BLOCKSIZE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	output:
		file("*.nvprof.txt")

	when:
		params.blocksize.enabled == true

	script:
		"""
		sed 's/blocksize="[0-9]+"/blocksize="${blocksize}"/' ${xml_file} > config.xml

		NVPROF_FILE=\$(make-filename.sh blocksize "${blocksize}" "${geometry}" "${gpu_model}" "${trial}" "%p" nvprof txt)

		nvprof \
			--csv \
			--log-file \${NVPROF_FILE} \
			--normalized-time-unit ms \
			--profile-child-processes \
			--unified-memory-profiling off \
		mpirun -np 1 \
		hemelb \
			-in config.xml \
			-out \${TMPDIR}/results

		rename 's/\\.[0-9]+\\.nvprof\\.txt/.nvprof.txt/' *.nvprof.txt
		"""
}



/**
 * The latticetype process performs a single run of HemelB with a
 * specific lattice type.
 */
process latticetype {
	tag "${latticetype}/${geometry}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(latticetype) from Channel.from( params.latticetype.values )
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_LATTICETYPE
		set val(geometry), file(xml_file) from XML_FILES_FOR_LATTICETYPE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.latticetype.enabled == true

	script:
		"""
		mpirun -np 1 hemelb -in ${xml_file} -out \${TMPDIR}/results
		"""
}



/**
 * The oversubscribe process performs a single run of HemelB with a
 * specific number of processes per GPU.
 */
process oversubscribe {
	tag "${np}/${geometry}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.oversubscribe.values )
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_OVERSUBSCRIBE
		set val(geometry), file(xml_file) from XML_FILES_FOR_OVERSUBSCRIBE
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.oversubscribe.enabled == true

	script:
		"""
		export CUDA_VISIBLE_DEVICES=0

		mpirun -np ${np} hemelb -in ${xml_file} -out \${TMPDIR}/results
		"""
}



/**
 * The scalability_cpu process performs a single run of HemelB with a
 * specific number of CPU processes.
 */
process scalability_cpu {
	tag "${np}/${geometry}/cpu/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.scalability_cpu.values )
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_SCALABILITY_CPU
		set val(geometry), file(xml_file) from XML_FILES_FOR_SCALABILITY_CPU
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.scalability_cpu.enabled == true

	script:
		"""
		sed 's/use_gpu="1"/use_gpu="0"/' ${xml_file} > config.xml

		mpirun -np ${np} hemelb -in config.xml -out \${TMPDIR}/results
		"""
}



/**
 * The scalability_gpu process performs a single run of HemelB with a
 * specific number of GPU processes.
 */
process scalability_gpu {
	tag "${np}/${geometry}/${gpu_model}/${trial}"
	publishDir "${params.output.dir}"

	input:
		each(np) from Channel.from( params.scalability_gpu.values )
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_SCALABILITY_GPU
		set val(geometry), file(xml_file) from XML_FILES_FOR_SCALABILITY_GPU
		each(gpu_model) from Channel.from( params.input.gpu_models )
		each(trial) from Channel.from( 0 .. params.input.trials-1 )

	when:
		params.scalability_gpu.enabled == true

	script:
		"""
		mpirun -np ${np} hemelb -in ${xml_file} -out \${TMPDIR}/results
		"""
}
