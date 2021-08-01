#include <cuda_runtime.h>
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
#define MATMUL_CPU_ARRAY_SIZE (1<<9)
#define MATMUL_CPU_NTIMES 4

#define ELEM(M, n, i, j) ((M)[(i) * (n) + (j)])

double benchmark_cpu_iops()
{
    int n = MATMUL_CPU_ARRAY_SIZE;
    int_t * A = (int_t *)malloc(n * n * sizeof(int_t));
    int_t * B = (int_t *)malloc(n * n * sizeof(int_t));
    int_t * C = (int_t *)malloc(n * n * sizeof(int_t));

    for ( int i = 0; i < MATMUL_CPU_ARRAY_SIZE; i++ )
    {
        for ( int j = 0; j < MATMUL_CPU_ARRAY_SIZE; j++ )
        {
            ELEM(A, n, i, j) = 1;
            ELEM(B, n, i, j) = 2;
            ELEM(C, n, i, j) = 0;
        }
    }

    double iops = 2.0 * n * n * n;
    double min_time = INFINITY;

    for ( int l = 0; l < MATMUL_CPU_NTIMES; l++ )
    {
        double t = mysecond();

        for ( int i = 0; i < MATMUL_CPU_ARRAY_SIZE; i++ )
        {
            for ( int j = 0; j < MATMUL_CPU_ARRAY_SIZE; j++ )
            {
                ELEM(C, n, i, j) = 0;

                for ( int k = 0; k < MATMUL_CPU_ARRAY_SIZE; k++ )
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
    int n = MATMUL_CPU_ARRAY_SIZE;
    real_t * A = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * B = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * C = (real_t *)malloc(n * n * sizeof(real_t));

    for ( int i = 0; i < MATMUL_CPU_ARRAY_SIZE; i++ )
    {
        for ( int j = 0; j < MATMUL_CPU_ARRAY_SIZE; j++ )
        {
            ELEM(A, n, i, j) = 1.0;
            ELEM(B, n, i, j) = 2.0;
            ELEM(C, n, i, j) = 0.0;
        }
    }

    double flops = 2.0 * n * n * n;
    double min_time = INFINITY;

    for ( int l = 0; l < MATMUL_CPU_NTIMES; l++ )
    {
        double t = mysecond();

        for ( int i = 0; i < MATMUL_CPU_ARRAY_SIZE; i++ )
        {
            for ( int j = 0; j < MATMUL_CPU_ARRAY_SIZE; j++ )
            {
                ELEM(C, n, i, j) = 0.0;

                for ( int k = 0; k < MATMUL_CPU_ARRAY_SIZE; k++ )
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

double benchmark_cpu_mem_bw()
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

    double bytes = 3.0 * sizeof(real_t) * STREAM_ARRAY_SIZE;
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
    const char * filename = "tmp";
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
    const char * filename = "tmp";
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



/**
 * GPU kernel for gpu_flops benchmark.
 */
#define TILE_DIM 16

__global__
void benchmark_gpu_flops_kernel(int n, real_t * A, real_t * B, real_t * C)
{
    // blockDim.x = TILE_DIM
    // blockDim.y = TILE_DIM
    __shared__ real_t tile_A[TILE_DIM][TILE_DIM];
    __shared__ real_t tile_B[TILE_DIM][TILE_DIM];

    int tx = threadIdx.x;
    int ty = threadIdx.y;
    int offset_x = blockIdx.x * blockDim.x + tx;
    int offset_y = blockIdx.y * blockDim.y + ty;
    int stride_x = blockDim.x * gridDim.x;
    int stride_y = blockDim.y * gridDim.y;

    for ( int i = offset_y; i < n; i += stride_y ) {
        for ( int j = offset_x; j < n; j += stride_x ) {
            real_t C_ij = 0;

            // iterate through each tile pair in A, B
            for ( int offset_t = 0; offset_t < n; offset_t += TILE_DIM ) {
                // load tiles into shared memory
                tile_A[ty][tx] = A[i * n + (offset_t + tx)];
                tile_B[ty][tx] = B[(offset_t + ty) * n + j];

                __syncthreads();

                // update sum of products
                for ( int k = 0; k < TILE_DIM; k++ ) {
                    C_ij += tile_A[ty][k] * tile_B[k][tx];
                }

                __syncthreads();
            }

            // save output value
            C[i * n + j] = C_ij;
        }
    }
}



/**
 * Floating-point matrix multiplication benchmark based on HPL.
 *
 *   http://www.netlib.org/benchmark/hpl/
 */
#define MATMUL_GPU_ARRAY_SIZE (1<<12)
#define MATMUL_GPU_NTIMES 4

double benchmark_gpu_flops()
{
    int n_devices;
    cudaGetDeviceCount(&n_devices);

    if ( n_devices == 0 ) {
        return 0.0;
    }

    int n = MATMUL_GPU_ARRAY_SIZE;
    real_t * A = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * B = (real_t *)malloc(n * n * sizeof(real_t));
    real_t * C = (real_t *)malloc(n * n * sizeof(real_t));

    real_t * d_A;
    real_t * d_B;
    real_t * d_C;
    cudaMalloc(&d_A, n * n * sizeof(real_t));
    cudaMalloc(&d_B, n * n * sizeof(real_t));
    cudaMalloc(&d_C, n * n * sizeof(real_t));

    for ( int i = 0; i < MATMUL_GPU_ARRAY_SIZE; i++ )
    {
        for ( int j = 0; j < MATMUL_GPU_ARRAY_SIZE; j++ )
        {
            ELEM(A, n, i, j) = 1.0;
            ELEM(B, n, i, j) = 2.0;
            ELEM(C, n, i, j) = 0.0;
        }
    }

    cudaMemcpy(d_A, A, n * n * sizeof(real_t), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, n * n * sizeof(real_t), cudaMemcpyHostToDevice);

    double flops = 2.0 * n * n * n;
    double min_time = INFINITY;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    int nSMs;
    cudaDeviceGetAttribute(&nSMs, cudaDevAttrMultiProcessorCount, 0);

    for ( int l = 0; l < MATMUL_GPU_NTIMES; l++ )
    {
        cudaEventRecord(start);

        dim3 block(TILE_DIM, TILE_DIM);
        dim3 grid(2 * nSMs, 4);
        benchmark_gpu_flops_kernel<<<grid, block>>>(n, d_A, d_B, d_C);

        cudaEventRecord(stop);

        cudaMemcpy(C, d_C, n * n * sizeof(real_t), cudaMemcpyDeviceToHost);

        float t;
        cudaEventElapsedTime(&t, start, stop);

#ifdef VERBOSE
        printf("%f\n", t / 1000);

        // double max_error = 0.0;
        // for ( int i = 0; i < n * n; i++ ) {
        //     max_error = max(max_error, abs(C[i] - 2.0 * n));
        // }

        // printf("max_error = %f\n", max_error);
#endif

        if ( l > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(A);
    free(B);
    free(C);

    return flops / min_time / 1e6;
}



/**
 * GPU kernel for gpu_mem_bw benchmark.
 */
__global__
void benchmark_gpu_mem_bw_kernel(int n, real_t * a, real_t * b, real_t * c, real_t scalar)
{
    int offset = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    for ( int i = offset; i < n; i += stride ) {
        a[i] = b[i] + scalar * c[i];
    }
}



/**
 * Vector arithmetic benchmark based on STREAM Triad.
 *
 *   http://www.cs.virginia.edu/stream/
 */
double benchmark_gpu_mem_bw()
{
    int n_devices;
    cudaGetDeviceCount(&n_devices);

    if ( n_devices == 0 ) {
        return 0.0;
    }

    int n = STREAM_ARRAY_SIZE;
    real_t * a = (real_t *)malloc(n * sizeof(real_t));
    real_t * b = (real_t *)malloc(n * sizeof(real_t));
    real_t * c = (real_t *)malloc(n * sizeof(real_t));
    real_t scalar = 3.0f;

    real_t * d_a;
    real_t * d_b;
    real_t * d_c;
    cudaMalloc(&d_a, n * sizeof(real_t));
    cudaMalloc(&d_b, n * sizeof(real_t));
    cudaMalloc(&d_c, n * sizeof(real_t));

    for ( int j = 0; j < n; j++ )
    {
        a[j] = 1.0;
        b[j] = 2.0;
        c[j] = 0.0;
    }

    cudaMemcpy(d_a, a, n * sizeof(real_t), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, n * sizeof(real_t), cudaMemcpyHostToDevice);

    double bytes = 3.0 * sizeof(real_t) * n;
    double min_time = INFINITY;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    int nSMs;
    cudaDeviceGetAttribute(&nSMs, cudaDevAttrMultiProcessorCount, 0);

    for ( int k = 0; k < STREAM_NTIMES; k++ )
    {
        cudaEventRecord(start);

        dim3 block(256);
        dim3 grid(8 * nSMs);
        benchmark_gpu_mem_bw_kernel<<<grid, block>>>(n, d_a, d_b, d_c, scalar);

        cudaEventRecord(stop);

        cudaMemcpy(a, d_a, n * sizeof(real_t), cudaMemcpyDeviceToHost);

        float t;
        cudaEventElapsedTime(&t, start, stop);

#ifdef VERBOSE
        printf("%f\n", t / 1000);

        // double max_error = 0.0;
        // for ( int i = 0; i < n; i++ ) {
        //     max_error = max(max_error, abs(a[i] - 2.0));
        // }

        // printf("max_error = %f\n", max_error);
#endif

        if ( k > 0 && t < min_time )
        {
            min_time = t;
        }
    }

    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    free(a);
    free(b);
    free(c);

    return bytes / min_time / 1e6;
}



typedef struct {
    const char * name;
    const char * format;
} format_t;



typedef struct {
    const char * name;
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
        { "cpu_mem_bw", benchmark_cpu_mem_bw }, // GiB/s
        { "disk_read",  benchmark_disk_read },  // GB/s
        { "disk_write", benchmark_disk_write }, // GB/s
        { "gpu_flops",  benchmark_gpu_flops },  // GFLOPS/s
        { "gpu_mem_bw", benchmark_gpu_mem_bw }  // GB/s
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