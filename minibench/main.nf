#!/usr/bin/env nextflow



/**
 * The minibench process runs the minibench benchmark for
 * each node type in a compute environment.
 */
process minibench {
    publishDir "${params.output_dir}"

    input:
        each(c) from Channel.fromList( params.conditions )
        each(trial) from Channel.fromList( 0 .. params.trials-1 )

    script:
        """
        # specify node type
        echo "#TRACE node_type=${c.node_type}"

        # build and run minibench
        make -C ${workflow.launchDir}
        ${workflow.launchDir}/minibench trace
        """
}
