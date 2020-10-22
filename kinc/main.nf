#!/usr/bin/env nextflow



/**
 * Create channel for input files.
 */
EMX_TXT_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.emx_txt_files}", size: 1, flat: true)



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
        set val(dataset), file(emx_txt_file) from EMX_TXT_FILES
        each(trial) from Channel.from( 0 .. params.input.trials-1 )

    script:
        """
        # specify input features for the execution trace
        echo "#TRACE dataset=${dataset}"
        echo "#TRACE gpu_model=${c.gpu_model}"
        echo "#TRACE np=${c.np}"
        echo "#TRACE n_rows=`tail -n +1 ${emx_txt_file} | wc -l`"
        echo "#TRACE n_cols=`head -n +1 ${emx_txt_file} | wc -w`"

        # apply runtime settings
        kinc settings set cuda ${c.gpu_model == "cpu" ? "none" : "0"}
        kinc settings set opencl none
        kinc settings set threads ${c.threads}
        kinc settings set buffer 4
        kinc settings set logging off

        # convert input file into emx format
        kinc run import-emx \
            --input ${emx_txt_file} \
            --output ${dataset}.emx \
            > /dev/null

        # run kinc
        mpirun -np ${c.np.toInteger() + 1} \
        kinc run similarity \
            --input ${dataset}.emx \
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
