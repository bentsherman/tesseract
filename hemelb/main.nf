#!/usr/bin/env nextflow



/**
 * Load gmy and xml file for each input dataset.
 */
GMY_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.gmy_files}", size: 1, flat: true)
XML_FILES = Channel.fromFilePairs("${params.input.dir}/${params.input.xml_files}", size: 1, flat: true)

DATASETS = GMY_FILES.join(XML_FILES)



/**
 * Extract each set of input conditions from file.
 */
CONDITIONS_FILE = Channel.fromPath("${params.input.dir}/${params.input.conditions_file}")

CONDITIONS_FILE
    .splitCsv(sep: "\t", header: true)
    .set { CONDITIONS }



/**
 * The run_experiment process performs a single run of the
 * application under test for each set of input conditions.
 */
process run_experiment {
    publishDir "${params.output.dir}"

    input:
        set val(geometry), file(gmy_file), file(xml_file) from DATASETS
        each(c) from CONDITIONS
        each(trial) from Channel.from( 0 .. params.input.trials-1 )

    output:
        val(c) into CONDITIONS_AUGMENTED

    script:
        """
        # augment conditions with additional features
        # ${c = c.clone()}
        # ${c.task_id = task.index}
        # ${c.geometry = geometry}
        # ${c.trial = trial}

        # temporary workaround for .bashrc issue
        module use \${HOME}/modules

        if [[ ${c.gpu_model} == "cpu" ]]; then
            module load hemelb/${c.latticetype}-p100
        else
            module load hemelb/${c.latticetype}-${c.gpu_model}
        fi

        # modify config file
        cp ${xml_file} config.xml

        if [[ ${c.gpu_model} == "cpu" ]]; then
            sed 's/use_gpu value="1"/use_gpu value="0"/' config.xml > tmp; mv tmp config.xml
        else
            sed 's/use_gpu value="0"/use_gpu value="1"/' config.xml > tmp; mv tmp config.xml
        fi

        sed 's/blocksize="[0-9]+"/blocksize="${c.blocksize}"/' config.xml > tmp; mv tmp config.xml

        # use only gpu 0 if ngpus is 1
        if [[ ${c.ngpus} == 1 ]]; then
            export CUDA_VISIBLE_DEVICES=0
        fi

        # run application
        mpirun -np ${c.np} \
        hemelb \
            -in config.xml \
            -out results
        """
}



/**
 * Collect augmented conditions into a csv file.
 */
CONDITIONS_AUGMENTED
    .into {
        CONDITIONS_AUGMENTED_INDIVIDUAL;
        CONDITIONS_AUGMENTED_MERGED
    }

CONDITIONS_AUGMENTED_INDIVIDUAL
    .subscribe {
        f = file("${params.output.dir}/${it.task_id}.txt")
        f.text = it.keySet().join('\t') + '\n' + it.values().join('\t') + '\n'
    }

CONDITIONS_AUGMENTED_MERGED
    .map {
        it.keySet().join('\t') + '\n' + it.values().join('\t') + '\n'
    }
    .collectFile(
        keepHeader: true,
        name: "conditions.txt",
        storeDir: "${params.output.dir}"
    )
