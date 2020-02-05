# tesseract

A Nextflow pipeline for benchmarking scientific applications and understanding their performance characteristics.

## Usage

### Select an Application

The first step is to select an application to benchmark. It can really be anything: a binary executable, a script, or even a Nextflow pipeline. You must create an "auxiliary pipeline" which will run the application many times under different conditions in order to collect performance data. Two examples are provided for KINC and HemeLB.

### Generate Input Conditions

Once you have an application, you must define all of the input conditions under which to run the application. These conditions include command-line parameters, input data characteristics, and system characteristics. You can use the `make-conditions.py` to generate conditions via parameter sweeps. This script will create a "conditions file", which is essentially an incomplete performance dataset -- all that's missing is the performance data, the output.

### Benchmark Application

Once you have a pipeline to run your application and a conditions file, run the pipeline! It will run the application repeatedly for each set of input conditions listed in the conditions file, and produce a "trace file" of performance data for each run. Additionally you can instrument your pipeline to collect additional performance data using tools such as `gprof` or `nvprof`.

### Aggregate Performance Data

Use the main pipeline in this repo to combine the conditions file with the collected performance data. This process will produce for you a complete performance dataset, which you can then use for normal data science tasks such as visualization and training models.
