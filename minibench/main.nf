#!/usr/bin/env nextflow



/**
 * The minibench process runs minibench in a given compute environment.
 */
process minibench {
    publishDir "${params.output.dir}"

    input:
        each(c) from Channel.from( params.input.conditions )
        each(trial) from Channel.from( 0 .. params.input.trials-1 )

    script:
        """
        # specify input features
        echo "#TRACE phase=${c.phase}"
        echo "#TRACE hostname=`hostname`"

        # verify that beforeScript isn't included in nextflow trace
        sleep 10
        """
}
