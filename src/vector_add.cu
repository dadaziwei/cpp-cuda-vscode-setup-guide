//
// vector_add.cu - Classic CUDA Introduction: Vector Addition
// Performs C = A + B in parallel on the GPU.
//

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <cuda_runtime.h>

// GPU kernel: each thread computes one element
__global__ void vectorAddKernel(const float* A, const float* B,
                                 float* C, int N) {
    int idx = blockDim.x * blockIdx.x + threadIdx.x;
    if (idx < N) {
        C[idx] = A[idx] + B[idx];
    }
}

// CPU reference implementation (for validation)
void vectorAddCPU(const float* A, const float* B, float* C, int N) {
    for (int i = 0; i < N; ++i) {
        C[i] = A[i] + B[i];
    }
}

int main() {
    const int N = 1 << 24;  // 16M elements
    const size_t bytes = N * sizeof(float);

    printf("========================================\n");
    printf("  CUDA Vector Addition: C = A + B\n");
    printf("  Elements: %d (%.1f MB)\n",
           N, bytes / (1024.0 * 1024.0));
    printf("========================================\n\n");

    // 1. Allocate host memory
    float *h_A = (float*)malloc(bytes);
    float *h_B = (float*)malloc(bytes);
    float *h_C_gpu = (float*)malloc(bytes);
    float *h_C_cpu = (float*)malloc(bytes);

    // 2. Initialize data
    for (int i = 0; i < N; ++i) {
        h_A[i] = rand() / (float)RAND_MAX;
        h_B[i] = rand() / (float)RAND_MAX;
    }

    // 3. Allocate device memory
    float *d_A, *d_B, *d_C;
    cudaMalloc(&d_A, bytes);
    cudaMalloc(&d_B, bytes);
    cudaMalloc(&d_C, bytes);

    // 4. Host -> Device data transfer
    cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice);

    // 5. Launch GPU kernel
    const int threadsPerBlock = 256;
    const int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    printf("  Launch config: %d blocks x %d threads\n\n",
           blocksPerGrid, threadsPerBlock);

    // CUDA events for timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    vectorAddKernel<<<blocksPerGrid, threadsPerBlock>>>(
        d_A, d_B, d_C, N);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float gpuTime = 0;
    cudaEventElapsedTime(&gpuTime, start, stop);

    // 6. Device -> Host retrieve results
    cudaMemcpy(h_C_gpu, d_C, bytes, cudaMemcpyDeviceToHost);

    // 7. CPU validation
    vectorAddCPU(h_A, h_B, h_C_cpu, N);

    int errors = 0;
    for (int i = 0; i < N; ++i) {
        if (fabs(h_C_gpu[i] - h_C_cpu[i]) > 1e-5) {
            errors++;
            if (errors < 5) {
                printf("  MISMATCH at %d: GPU=%f, CPU=%f\n",
                       i, h_C_gpu[i], h_C_cpu[i]);
            }
        }
    }

    // 8. Print results
    float bandwidth = (3.0f * bytes) / (gpuTime / 1000.0f) / 1e9;
    printf("  GPU Time:   %.3f ms\n", gpuTime);
    printf("  Bandwidth:  %.2f GB/s\n", bandwidth);
    printf("  Errors:     %d\n", errors);
    printf("  Result:     %s\n",
           errors == 0 ? "PASSED" : "FAILED");
    printf("========================================\n");

    // 9. Cleanup
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C_gpu);
    free(h_C_cpu);
    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return errors ? 1 : 0;
}
