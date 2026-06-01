//
// hello_cuda.cu - CUDA Environment Verification
// Prints GPU device info to verify the CUDA toolchain is working.
//

#include <cstdio>
#include <cuda_runtime.h>

int main() {
    int deviceCount = 0;
    cudaError_t err = cudaGetDeviceCount(&deviceCount);

    if (err != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(err));
        return 1;
    }

    printf("========================================\n");
    printf("  CUDA Environment Check\n");
    printf("========================================\n");
    printf("  Number of CUDA devices: %d\n\n", deviceCount);

    for (int dev = 0; dev < deviceCount; ++dev) {
        cudaDeviceProp props;
        cudaGetDeviceProperties(&props, dev);

        printf("  Device %d: %s\n", dev, props.name);
        printf("    Compute Capability:    %d.%d\n",
               props.major, props.minor);
        printf("    Multiprocessors (SM):  %d\n",
               props.multiProcessorCount);
        printf("    Global Memory:         %.2f GB\n",
               props.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
        printf("    Max Threads per Block: %d\n",
               props.maxThreadsPerBlock);
        printf("    Clock Rate:            %.2f GHz\n",
               props.clockRate / 1e6);
        printf("    Warp Size:             %d\n",
               props.warpSize);
        printf("\n");
    }

    printf("  CUDA environment OK!\n");
    printf("========================================\n");
    return 0;
}
