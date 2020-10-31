#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>



typedef double (*benchmark_func_t)(void);

typedef long   int_t;
typedef double real_t;



/**
 * Helper function to get current timestamp,
 * taken from STREAM Triad.
 */
double mysecond()
{
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);

    return (double) tp.tv_sec + (double) tp.tv_usec * 1.e-6;
}



/**
 * Integer matrix multiplication benchmark.
 *
 * See also:
 *
 *   https://www.math.utah.edu/~mayer/linux/bmark.html
 */
#define MATMUL_ARRAY_SIZE 1000
#define MATMUL_NTIMES 4

#define ELEM(M, n, i, j) ((M)[(i) * (n) + (j)])

double benchmark_cpu_iops()
{
    int n = MATMUL_ARRAY_SIZE;
    int_t * A = (int_t *)malloc(n * n * sizeof(int_t));
    int_t * B = (int_t *)malloc(n * n * sizeof(int_t));
    int_t * C = (int_t *)malloc(n * n * sizeof(int_t));

    for ( int i = 0; i < MATMUL_ARRAY_SIZE; i++ )
    {
        for ( int j = 0; j < MATMUL_ARRAY_SIZE; j++ )
        {
            ELEM(A, n, i, j) = 1;
            ELEM(B, n, i, j) = 2;
            ELEM(C, n, i, j) = 0;
        }
    }

    double iops = 2 * n * n * n;
    double min_time = INFINITY;

    for ( int l = 0; l < MATMUL_NTIMES; l++ )
    {
        double t = mysecond();

        for ( int i = 0; i < MATMUL_ARRAY_SIZE; i++ )
        {
            for ( int j = 0; j < MATMUL_ARRAY_SIZE; j++ )
            {
                ELEM(C, n, i, j) = 0;

                for ( int k = 0; k < MATMUL_ARRAY_SIZE; k++ )
                {
                    ELEM(C, n, i, j) += ELEM(A, n, i, j) * ELEM(B, n, i, j);
                }
            }
        }

        t = mysecond() - t;

#ifdef VERBOSE
        printf("%f\n", t);
#endif

        if ( l > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    free(A);
    free(B);
    free(C);

    return iops / min_time / 1e9;
}



/**
 * Floating-point matrix multiplication benchmark based on HPL.
 *
 *   http://www.netlib.org/benchmark/hpl/
 */
double benchmark_cpu_flops()
{
    int n = MATMUL_ARRAY_SIZE;
    real_t * A = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * B = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * C = (real_t *)malloc(n * n * sizeof(real_t));

    for ( int i = 0; i < MATMUL_ARRAY_SIZE; i++ )
    {
        for ( int j = 0; j < MATMUL_ARRAY_SIZE; j++ )
        {
            ELEM(A, n, i, j) = 1.0;
            ELEM(B, n, i, j) = 2.0;
            ELEM(C, n, i, j) = 0.0;
        }
    }

    double flops = 2 * n * n * n;
    double min_time = INFINITY;

    for ( int l = 0; l < MATMUL_NTIMES; l++ )
    {
        double t = mysecond();

        for ( int i = 0; i < MATMUL_ARRAY_SIZE; i++ )
        {
            for ( int j = 0; j < MATMUL_ARRAY_SIZE; j++ )
            {
                ELEM(C, n, i, j) = 0.0;

                for ( int k = 0; k < MATMUL_ARRAY_SIZE; k++ )
                {
                    ELEM(C, n, i, j) += ELEM(A, n, i, j) * ELEM(B, n, i, j);
                }
            }
        }

        t = mysecond() - t;

#ifdef VERBOSE
        printf("%f\n", t);
#endif

        if ( l > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    free(A);
    free(B);
    free(C);

    return flops / min_time / 1e9;
}



/**
 * Vector arithmetic benchmark based on STREAM Triad.
 *
 *   http://www.cs.virginia.edu/stream/
 */
#define STREAM_ARRAY_SIZE 10000000
#define STREAM_NTIMES 4

double benchmark_mem_bw()
{
    real_t * a = (real_t *)malloc(STREAM_ARRAY_SIZE * sizeof(real_t));
    real_t * b = (real_t *)malloc(STREAM_ARRAY_SIZE * sizeof(real_t));
    real_t * c = (real_t *)malloc(STREAM_ARRAY_SIZE * sizeof(real_t));
    real_t scalar = 3.0f;

    for ( int j = 0; j < STREAM_ARRAY_SIZE; j++ )
    {
        a[j] = 1.0;
        b[j] = 2.0;
        c[j] = 0.0;
    }

    double bytes = 3 * sizeof(real_t) * STREAM_ARRAY_SIZE;
    double min_time = INFINITY;

    for ( int k = 0; k < STREAM_NTIMES; k++ )
    {
        double t = mysecond();

        for ( int j = 0; j < STREAM_ARRAY_SIZE; j++ )
        {
            a[j] = b[j] + scalar * c[j];
        }

        t = mysecond() - t;

#ifdef VERBOSE
        printf("%f\n", t);
#endif

        if ( k > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    free(a);
    free(b);
    free(c);

    return bytes / min_time / (1 << 30);
}



/**
 * Read a file from disk.
 */
#define READ_FILE_SIZE (1<<30)
#define READ_NTIMES 4

double benchmark_disk_read()
{
    char * filename = "tmp";
    FILE * file;
    char * data = (char *)malloc(READ_FILE_SIZE * sizeof(char));

    for ( int i = 0; i < READ_FILE_SIZE; i++ )
    {
        data[i] = rand();
    }

    file = fopen(filename, "w");
    fwrite(data, sizeof(char), READ_FILE_SIZE, file);
    fclose(file);

    double min_time = INFINITY;

    for ( int k = 0; k < READ_NTIMES; k++ )
    {
        double t = mysecond();

        file = fopen(filename, "r");
        fread(data, sizeof(char), READ_FILE_SIZE, file);
        fclose(file);

        t = mysecond() - t;

#ifdef VERBOSE
        printf("%f\n", t);
#endif

        if ( k > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    free(data);
    remove(filename);

    return READ_FILE_SIZE / min_time / 1e9;
}



/**
 * Write a file to disk.
 */
#define WRITE_FILE_SIZE (1<<30)
#define WRITE_NTIMES 4

double benchmark_disk_write()
{
    char * filename = "tmp";
    FILE * file;
    char * data = (char *)malloc(WRITE_FILE_SIZE * sizeof(char));

    for ( int i = 0; i < WRITE_FILE_SIZE; i++ )
    {
        data[i] = rand();
    }

    double min_time = INFINITY;

    for ( int k = 0; k < WRITE_NTIMES; k++ )
    {
        double t = mysecond();

        file = fopen(filename, "w");
        fwrite(data, sizeof(char), WRITE_FILE_SIZE, file);
        fclose(file);

        t = mysecond() - t;

#ifdef VERBOSE
        printf("%f\n", t);
#endif

        if ( k > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    free(data);
    remove(filename);

    return WRITE_FILE_SIZE / min_time / 1e9;
}



typedef struct {
    char * name;
    char * format;
} format_t;



typedef struct {
    char * name;
    benchmark_func_t func;
} benchmark_t;



int main(int argc, char **argv)
{
    // parse command-line arguments
    if ( argc != 2 )
    {
        fprintf(stderr, "usage: ./minibench <output-format>\n");
        exit(-1);
    }

    char * fmt_name = argv[1];

    // define output formats
    format_t formats[] = {
        { "csv",   "%s\t%0.6f" },
        { "trace", "#TRACE %s=%0.6f" }
    };
    int n_formats = sizeof(formats) / sizeof(format_t);

    // select output format
    format_t * fmt = NULL;

    for ( int i = 0; i < n_formats; i++ )
    {
        if ( strcmp(formats[i].name, fmt_name) == 0 )
        {
            fmt = &formats[i];
        }
    }

    if ( fmt == NULL )
    {
        fprintf(stderr, "error: invalid output format %s\n", fmt_name);
        exit(-1);
    }

    // define benchmarks
    benchmark_t benchmarks[] = {
        { "cpu_iops",   benchmark_cpu_iops },   // GIOP/s
        { "cpu_flops",  benchmark_cpu_flops },  // GFLOP/s
        { "mem_bw",     benchmark_mem_bw },     // GiB/s
        { "disk_read",  benchmark_disk_read },  // GB/s
        { "disk_write", benchmark_disk_write }  // GB/s
    };
    int n_benchmarks = sizeof(benchmarks) / sizeof(benchmark_t);

    // run benchmarks
    for ( int i = 0; i < n_benchmarks; i++ )
    {
        benchmark_t *b = &benchmarks[i];

        printf(fmt->format, b->name, b->func());
        printf("\n");
    }

    return 0;
}