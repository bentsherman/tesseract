#!/usr/bin/env nextflow

nextflow.enable.dsl=2



workflow {
    // load gmy and xml file for each input dataset
    gmy_files = Channel.fromFilePairs("${params.input_dir}/${params.gmy_files}", size: 1, flat: true)
    xml_files = Channel.fromFilePairs("${params.input_dir}/${params.xml_files}", size: 1, flat: true)

    datasets = gmy_files.join(xml_files)

    // run hemelb for each dataset
    hemelb(datasets)
}



/**
 * The hemelb process performs a run of hemelb on a geometry file.
 */
process hemelb {
    input:
        tuple val(geometry), path(gmy_file), path(xml_file)

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
