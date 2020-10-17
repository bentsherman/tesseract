# tesseract

Tesseract is a machine learning system for predicting resource usage of scientific applications and workflows. Tesseract provides a generic and user-friendly way to create prediction models from performance data collected from application runs. This repository contains the code for Tesseract as well as some Nextflow workflows that have been instrumented to generate performance data for visualization and model training. Tesseract can be used for tasks such as predicting resource usage, detecting execution anomalies, and predicting failures.

_Note: Not to be confused with the [Tesseract OCR Engine](https://github.com/tesseract-ocr)._

## Usage

### Select an Application

### Creating a Nextflow Pipeline

Tesseract can be applied to any application or Nextflow workflow. Individual applications can be easily wrapped into a Nextflow pipeline, refer to the examples in this repository. Workflows based on a different workflow manager must be converted into a Nextflow pipeline, which should also not be difficult as Nextflow is highly generic and easy to use. Tesseract relies on Nextflow's trace feature, which automatically collects a performance trace of every process that is executed. Again, refer to the example pipelines in this repository. In particular, the `trace` section in any of the example config files shows how to enable this feature.

### Annotating Your Pipeline

Once you have your application in a Nextflow pipeline, you must annotate each process statement by adding "trace" directives to the process script. These directives will specify the input conditions of the execution, which will be parsed by Tesseract and supplied as the input features of your performance dataset. You can specify whatever conditions you like, and each process can have different conditions, as Tesseract will create separate prediction models for each process.

Trace directives can be static or dynamic. Static directives are for values that are known by the process script, such as input parameters or values from input channels. Dynamic directives are for values that must be computed during execution, such as the size of input and output files.

Here are some trace directives that might be used for the KINC example pipeline:
```bash
# static trace directives
#TRACE dataset=${dataset}
#TRACE gpu_model=${c.gpu_model}
#TRACE np=${c.np}

# dynamic trace directives
echo "#TRACE n_rows=`tail -n +1 ${emx_txt_file} | wc -l`"
echo "#TRACE n_cols=`head -n +1 ${emx_txt_file} | wc -w`"
```

In this example, `dataset`, `gpu_model`, and `np` are Nextflow variables supplied by input channels. They can be supplied as static directives, which means they will simply be comments in the process script. On the other hand, `emx_file` is a tab-delimited text file, also supplied by an input channel, but the dimensions of this dataset must be computed by the script itself. As a result, these two directives must be printed to the execution log. After the workflow completes, Tesseract will parse both the process script and the execution log to obtain the input conditions for each executed task.

The variables in this example have been determined to be the most relevant input conditions for KINC. You will have to make a similar selection for each process in your pipeline. It is better to be inclusive rather than exclusive at this stage; you can include as many conditions as you want and you can always remove them from your dataset later, but to add a new condition after the fact you will have to redo all of your application runs.

Keep in mind that dynamic directives should be fast and easy to compute, otherwise they may affect the execution trace.

### Collect Performance Data

Once you have an annotated Nextflow pipeline, you just need to run it many times to generate plenty of performance data. There are multiple ways to do this; you can do a parameter sweep like the examples in this repo, or you can simply use it in your normal work and allow the performance data to accumulate. In any case, each workflow run will create a performance trace called `trace.txt`. You must collect these trace files into one location and aggregate them into a performance dataset:
```bash
python bin/aggregate.py <trace-files>
```

This script will concatenate the trace files, obtain the input conditions for each individual run, and output a performance dataset for each process in your pipeline. These datasets can then be used for normal data science tasks such as visualization and training models.

_Note_: Tesseract parses the `#TRACE` directives from the process scripts, which are located in Nextflow's work directory tree. If you delete this work directory, or if it gets automatically deleted by some data retention policy, the input conditions for your application runs will be lost. So make sure to aggregate your performance data in a timely fashion!

### Visualization

The `visualize.py` script provides a simple but powerful interface for creating many kinds of visualizations from a dataframe. You can visualize one or two variables, and you can disaggregate across up to three dimensions. The script supports both discrete and continuous variables, and it will by default select the most appropriate type of plot for the variables that you specify. Refer to the example pipelines for example uses of this script.

### Train Prediction Models

TODO

### Deploy Prediction Models

TODO