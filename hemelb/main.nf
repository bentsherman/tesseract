#!/usr/bin/env nextflow



/**
 * Load gmy and xml file for each input dataset.
 */
GMY_FILES = Channel.fromFilePairs("${params.input_dir}/${params.gmy_files}", size: 1, flat: true)
XML_FILES = Channel.fromFilePairs("${params.input_dir}/${params.xml_files}", size: 1, flat: true)

INPUTS = GMY_FILES.join(XML_FILES)



/**
 * The hemelb process performs a run of hemelb on a geometry file.
 */
process hemelb {
    input:
        set val(geometry), file(gmy_file), file(xml_file) from INPUTS

    script:
        """
        # specify input features for the execution trace
        echo "#TRACE geometry=${geometry}"
        echo "#TRACE blocksize=${params.blocksize}"
        echo "#TRACE latticetype=${params.latticetype}"
        echo "#TRACE np=${params.np}"
        echo "#TRACE hardware_type=${params.hardware_type}"

        # modify config file
        cp ${xml_file} config.xml

        if [[ ${params.hardware_type} == "cpu" ]]; then
            sed 's/use_gpu value="1"/use_gpu value="0"/' config.xml > tmp; mv tmp config.xml
        else
            sed 's/use_gpu value="0"/use_gpu value="1"/' config.xml > tmp; mv tmp config.xml
        fi

        sed 's/blocksize="[0-9]\\+"/blocksize="${params.blocksize}"/' config.xml > tmp; mv tmp config.xml

        # run hemelb
        mpirun -np ${params.np} \
        hemelb \
            -in config.xml \
            -out results
        """
}
