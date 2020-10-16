#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
EMX_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.emx_files}", size: 1, flat: true)



/**
 * Extract each set of input conditions from file.
 */
CONDITIONS_FILE = Channel.fromPath("${params.input.dir}/${params.input.conditions_file}")

CONDITIONS_FILE
    .splitCsv(sep: "\t", header: true)
    .set { CONDITIONS }



/**
 * The kinc process performs a single run of kinc
 * for each set of input conditions.
 */
process kinc {
    publishDir "${params.output.dir}"

    input:
        each(c) from CONDITIONS
        set val(dataset), file(emx_file) from EMX_FILES
        each(trial) from Channel.from( 0 .. params.input.trials-1 )

    script:
        """
        # specify input conditions to be appended to trace data
        #TRACE dataset=${dataset}
        #TRACE gpu_model=${c.gpu_model}
        #TRACE np=${c.np}

        # load environment modules
        module use \${HOME}/modules
        module load kinc/${c.revision}

        # apply runtime settings
        kinc settings set cuda ${c.gpu_model == "cpu" ? "none" : "0"}
        kinc settings set opencl none
        kinc settings set threads ${c.threads}
        kinc settings set buffer 4
        kinc settings set logging off

        # run application
        mpirun -np ${c.np.toInteger() + 1} \
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
