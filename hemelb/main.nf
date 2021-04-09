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
 * The hemelb process performs a single run of hemelb
 * for each set of input conditions.
 */
process hemelb {
    publishDir "${params.output.dir}"

    input:
        each(c) from CONDITIONS
        set val(geometry), file(gmy_file), file(xml_file) from DATASETS
        each(trial) from Channel.from( 0 .. params.input.trials-1 )

    script:
        """
        # specify input features for the execution trace
        echo "#TRACE blocksize=${c.blocksize}"
        echo "#TRACE geometry=${geometry}"
        echo "#TRACE hardware_type=${c.hardware_type}"
        echo "#TRACE latticetype=${c.latticetype}"
        echo "#TRACE ngpus=${c.ngpus}"
        echo "#TRACE np=${c.np}"

        # modify config file
        cp ${xml_file} config.xml

        if [[ ${c.hardware_type} == "cpu" ]]; then
            sed 's/use_gpu value="1"/use_gpu value="0"/' config.xml > tmp; mv tmp config.xml
        else
            sed 's/use_gpu value="0"/use_gpu value="1"/' config.xml > tmp; mv tmp config.xml
        fi

        sed 's/blocksize="[0-9]\\+"/blocksize="${c.blocksize}"/' config.xml > tmp; mv tmp config.xml

        # run hemelb
        mpirun -np ${c.np} \
        hemelb \
            -in config.xml \
            -out results
        """
}
