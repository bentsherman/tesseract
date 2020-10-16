# tesseract

Tesseract is a machine learning system for predicting resource usage of scientific applications and workflows. Tesseract provides a generic and user-friendly way to create prediction models from performance data collected from application runs. This repository contains the code for Tesseract as well as some Nextflow workflows that have been instrumented to generate performance data for visualization and model training. Tesseract can be used for tasks such as predicting resource usage, detecting execution anomalies, and predicting failures.

_Note: Not to be confused with the [Tesseract OCR Engine](https://github.com/tesseract-ocr)._

## Usage

### Select an Application

Tesseract can be applied to any application or Nextflow workflow. Individual applications can be easily wrapped into a Nextflow pipeline, refer to the examples in this repository. Workflows based on a different workflow manager must be converted into a Nextflow pipeline, which should also not be difficult as Nextflow is highly generic and easy to use. Again, refer to the example pipelines in this repository. Tesseract relies on Nextflow's trace feature, which automatically collects a performance trace of every process that is executed.

Once you have your application in a Nextflow pipeline, you must instrument each process statement by adding `#TRACE` directives to the process script. These directives will specify the input conditions of the execution, which will be parsed by Tesseract and supplied as the input features of your performance dataset. You can specify whatever conditions you like, and each process can have different conditions, as Tesseract will create separate prediction models for each process.

As an example, consider the `kinc` process in the example pipeline for KINC:
```bash
# specify input conditions to be appended to trace data
#TRACE dataset=${dataset}
#TRACE gpu_model=${c.gpu_model}
#TRACE np=${c.np}
```

In this example, `dataset`, `gpu_model`, and `np` are Nextflow variables supplied by input channels. The values of these variables will be written into the process script, and they will not affect execution since the `#TRACE` directives are comments. After the workflow completes, Tesseract will parse these process scripts to obtain the input conditions for each process execution.

The variables in this example have been determined to be the most relevant input conditions for KINC. You will have to make a similar selection for each process in your pipeline. It is better to be inclusive rather than exclusive at this stage; you can include as many conditions as you want and you can always remove them from your dataset later, but to add a new condition after the fact you will have to redo all of your application runs.

### Collect Performance Data

Once you have a Nextflow pipeline, you just need to run it many times to generate plenty of performance data. There are multiple ways to do this; you can do a parameter sweep like the examples in this repo, or you can simply use it in your normal work and allow the performance data to accumulate. In any case, each workflow run will create a performance trace called `trace.txt`. You must collect these trace files into one location and aggregate them into a performance dataset:
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