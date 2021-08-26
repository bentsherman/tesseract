#!/usr/bin/env nextflow



/**
 * Extract each set of input conditions from file.
 */
CONDITIONS_FILE = Channel.fromPath("${params.conditions_file}")

CONDITIONS_FILE
    .splitCsv(sep: "\t", header: true)
    .set { CONDITIONS }



/**
 * The run_pipeline process performs a single run of the
 * pipeline under test.
 */
process run_pipeline {
    input:
        each(c) from CONDITIONS
        each(trial) from Channel.from( 0 .. params.trials-1 )

    script:
        """
        # initialize environment
        module purge
        module load anaconda3/5.1.0-gcc/8.3.1
        module load nextflow/21.04.1

        # change to launch directory
        cd ${workflow.launchDir}/${params.launch_dir}

        # create params file from conditions
        echo "${c.toString().replace('[': '', ']': '', ', ': '\n', ':': ': ')}" > params.yaml

        make-params.py params.yaml

        # run nextflow pipeline
        nextflow run \
            ${params.pipeline_name} \
            -ansi-log false \
            -params-file params.yaml \
            -profile ${params.pipeline_profiles} \
            -resume

        # save trace file to trace directory
        HASH=\$(printf %04x%04x \${RANDOM} \${RANDOM})

        cp ${params.pipeline_trace_file} ${params.trace_dir}/trace.\${HASH}.txt

        # cleanup
        rm -rf params.yaml ${params.pipeline_output_dir}
        """
}
