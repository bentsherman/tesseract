#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
GMY_FILES = Channel.fromFilePairs("${params.input_dir}/*.gmy", size: 1, flat: true)
XML_FILES = Channel.fromFilePairs("${params.input_dir}/*.xml", size: 1, flat: true)



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
	tag "${geometry}/${blocksize}"
	publishDir "${params.output_dir}/${geometry}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_BLOCKSIZE
		set val(geometry), file(xml_file) from XML_FILES_FOR_BLOCKSIZE
		each(blocksize) from Channel.from( params.blocksize.values )

	when:
		params.blocksize.enabled == true

	script:
		"""
		mpirun -np 1 hemelb -in ${xml_file} -out results
		"""
}



/**
 * The latticetype process performs a single run of HemelB with a
 * specific lattice type.
 */
process latticetype {
	tag "${geometry}/${latticetype}"
	publishDir "${params.output_dir}/${geometry}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_LATTICETYPE
		set val(geometry), file(xml_file) from XML_FILES_FOR_LATTICETYPE
		each(latticetype) from Channel.from( params.latticetype.values )

	when:
		params.latticetype.enabled == true

	script:
		"""
		module add hemelb/dev-${latticetype} || true

		mpirun -np 1 hemelb -in ${xml_file} -out results
		"""
}



/**
 * The oversubscribe process performs a single run of HemelB with a
 * specific number of processes per GPU.
 */
process oversubscribe {
	tag "${geometry}/${np}"
	publishDir "${params.output_dir}/${geometry}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_OVERSUBSCRIBE
		set val(geometry), file(xml_file) from XML_FILES_FOR_OVERSUBSCRIBE
		each(np) from Channel.from( params.oversubscribe.values )

	when:
		params.oversubscribe.enabled == true

	script:
		"""
		export CUDA_VISIBLE_DEVICES=0

		mpirun -np ${np} hemelb -in ${xml_file} -out results
		"""
}



/**
 * The scalability_cpu process performs a single run of HemelB with a
 * specific number of CPU processes.
 */
process scalability_cpu {
	tag "${geometry}/${latticetype}/${np}"
	publishDir "${params.output_dir}/${geometry}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_SCALABILITY_CPU
		set val(geometry), file(xml_file) from XML_FILES_FOR_SCALABILITY_CPU
		each(np) from Channel.from( params.scalability_cpu.values )
		each(latticetype) from Channel.from( params.latticetype.values )

	when:
		params.scalability_cpu.enabled == true

	script:
		"""
		module add hemelb/dev-${latticetype} || true

		mpirun -np ${np} hemelb -in ${xml_file} -out results
		"""
}



/**
 * The scalability_gpu process performs a single run of HemelB with a
 * specific number of GPU processes.
 */
process scalability_gpu {
	tag "${geometry}/${latticetype}/${np}"
	publishDir "${params.output_dir}/${geometry}"

	input:
		set val(geometry), file(gmy_file) from GMY_FILES_FOR_SCALABILITY_GPU
		set val(geometry), file(xml_file) from XML_FILES_FOR_SCALABILITY_GPU
		each(np) from Channel.from( params.scalability_gpu.values )
		each(latticetype) from Channel.from( params.latticetype.values )

	when:
		params.scalability_gpu.enabled == true

	script:
		"""
		module add hemelb/dev-${latticetype} || true

		mpirun -np ${np} hemelb -in ${xml_file} -out results
		"""
}
