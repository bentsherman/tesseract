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
		GMY_FILES_FOR_BLOCKSIZE
	}

XML_FILES
	.into {
		XML_FILES_FOR_BLOCKSIZE
	}



/**
 * The blocksize process performs a single run of HemelB with a set block size.
 */
process blocksize {
	tag "${geometry}/blocksize/${blocksize}"
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
