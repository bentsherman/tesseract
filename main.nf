#!/usr/bin/env nextflow



/**
 * Load conditions file and split each line into
 * a set of input conditions.
 */
Channel.fromPath("${params.run_conditions_file}")
    .splitCsv(sep: "\t", header: true)
    .set { CONDITIONS }



/**
 * The run_pipeline process performs a single run of a Nextflow
 * pipeline for each set of input conditions. All trace
 * files are saved to the '_trace' directory.
 */
process run_pipeline {
    publishDir "_trace", mode: "copy"
    echo true

    input:
        each(c) from CONDITIONS
        each(trial) from Channel.fromList( 0 .. params.run_trials-1 )

    output:
        file("${params.pipeline_name}.*.txt") into TRACE_FILES_FROM_RUN

    when:
        params.run == true

    script:
        """
        # initialize environment
        module purge
        module load anaconda3/5.1.0-gcc/8.3.1
        module load nextflow/21.04.1

        # create params file from conditions
        echo "${c.toString().replace('[': '', ']': '', ', ': '\n', ':': ': ')}" > params.yaml

        make-params.py params.yaml

        # change to launch directory
        cd ${workflow.launchDir}/${params.pipeline_name}

        # run nextflow pipeline
        nextflow run \
            ${params.run_pipeline} \
            -ansi-log false \
            -latest \
            -params-file \${OLDPWD}/params.yaml \
            -profile ${params.run_profiles} \
            -resume

        # save trace file
        HASH=`printf %04x%04x \${RANDOM} \${RANDOM}`

        cp ${params.run_trace_file} \${OLDPWD}/${params.pipeline_name}.trace.\${HASH}.txt

        # cleanup
        rm -rf ${params.run_output_dir}
        """
}



/**
 * Load trace files for the current pipeline from the
 * '_trace' directory and merge with trace files from
 * the run process.
 *
 * Remove duplicate files as trace files from run are
 * saved to the '_trace' directory.
 *
 * Group trace files into a list.
 */
Channel.fromPath("_trace/${params.pipeline_name}.*.txt")
    .mix ( TRACE_FILES_FROM_RUN.flatMap() )
    .unique { it -> it.name }
    .map { it -> [it.name.split(/\./)[0], it] }
    .groupTuple ()
    .set { TRACE_FILES }



/**
 * The aggregate process combines the input features from
 * execution logs with resource metrics from trace files to
 * produce a performance dataset for each process in the
 * pipeline under test. All performance datasets are saved
 * to the '_datasets' directory.
 */
process aggregate {
    publishDir "_datasets", mode: "copy"
    echo true

    input:
        set val(pipeline_name), file(trace_files) from TRACE_FILES

    output:
        file("${params.pipeline_name}.*.trace.txt") into DATASETS_FROM_AGGREGATE

    when:
        params.aggregate == true

    script:
        """
        # initialize environment
        module purge
        module load anaconda3/5.1.0-gcc/8.3.1

        # run aggregate script
        aggregate.py \
            ${trace_files} \
            --pipeline-name ${pipeline_name} \
            --fix-exit-na -1
        """
}



/**
 * Load dataset files for the current pipeline from the
 * '_datasets' directory and merge with dataset files from
 * the aggregate process.
 *
 * Remove duplicate files as dataset files from aggregate
 * are saved to the '_datasets' directory.
 */
Channel.fromPath("_datasets/${params.pipeline_name}.*.txt")
    .mix ( DATASETS_FROM_AGGREGATE.flatMap() )
    .unique { it -> it.name }
    .map { it -> [it.name.split(/\./), it] }
    .map { it -> [it[0][0], it[0][1], it[1]] }
    .set { DATASETS }



/**
 * The train process creates a prediction model for each
 * resource metric for each performance dataset. All models
 * are saved to the '_models' directory.
 */
process train {
    publishDir "_models", mode: "copy"
    echo true

    input:
        set val(pipeline_name), val(process_name), file(dataset) from DATASETS
        each(target) from Channel.fromList( params.train_targets )

    output:
        set val(pipeline_name), file("*.json"), file("*.pkl") into MODELS_FROM_TRAIN

    when:
        params.train == true && params.train_inputs.containsKey(process_name)

    script:
        """
        # initialize environment
        module purge
        module load anaconda3/5.1.0-gcc/8.3.1

        source activate ${params.conda_env}

        # train model
        export TF_CPP_MIN_LOG_LEVEL="3"

        echo
        echo ${pipeline_name} ${process_name} ${target}
        echo

        train.py \
            ${dataset} \
            --base-dir ${workflow.launchDir}/_datasets \
            ${params.train_merge_arg != null ? "--merge ${params.train_merge_arg}" : ""} \
            --inputs ${params.train_inputs[process_name].join(' ')} \
            --target ${target} \
            --scaler ${params.train_scaler} \
            --model-type ${params.train_model_type} \
            --model-name ${pipeline_name}.${process_name}.${target} \
            ${params.train_intervals == true ? "--intervals" : ""}
        """
}



/**
 * Create a single resource prediction query from the params.
 */
PREDICT_QUERIES = Channel.value([
    params.pipeline_name,
    params.predict_process,
    params.predict_inputs
])



/**
 * The predict process queries the predicted resource usage
 * of a process from a trained model, if one is available in
 * the '_models' directory.
 */
process predict {
    echo true

    input:
        set val(pipeline_name), val(process_name), val(inputs) from PREDICT_QUERIES

    when:
        params.predict == true

    script:
        """
        # initialize environment
        module purge
        module load anaconda3/5.1.0-gcc/8.3.1

        source activate ${params.conda_env}

        # query predicted usage for each resource metric
        export TF_CPP_MIN_LOG_LEVEL="3"

        for TARGET in ${params.predict_targets.join(' ')}; do
            predict.py \
                ${workflow.launchDir}/_models/${pipeline_name}.${process_name}.\${TARGET} \
                ${inputs}
        done
        """
}
