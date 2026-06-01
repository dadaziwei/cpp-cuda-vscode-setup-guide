cmake_minimum_required(VERSION 3.21)

project(CppLearn
    VERSION 1.0
    DESCRIPTION "C++ & CUDA Learning Project"
    LANGUAGES CXX CUDA
)

# ---- 标准 ----
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# ---- GPU 架构 (RTX 4060 = sm_89) ----
set(CMAKE_CUDA_ARCHITECTURES 89)

# ---- clangd 所需 ----
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_INCLUDES OFF)
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_LIBRARIES OFF)
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_OBJECTS OFF)

# ---- 避免 CRT 冲突 ----
set(CMAKE_CUDA_RUNTIME_LIBRARY Shared)

# ---- 编译选项 ----
if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /utf-8")
endif()
if(CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA")
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Wno-deprecated-gpu-targets")
endif()

# ---- C++ 示例 ----
add_executable(cpp_hello main.cpp)
set_property(TARGET cpp_hello PROPERTY
    MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# ---- CUDA 示例 ----
add_executable(cuda_hello src/hello_cuda.cu)
add_executable(cuda_vector_add src/vector_add.cu)

set_target_properties(cuda_hello cuda_vector_add PROPERTIES
    CUDA_SEPARABLE_COMPILATION OFF)

# ---- 配置摘要 ----
message(STATUS "CppLearn | C++${CMAKE_CXX_STANDARD} CUDA${CMAKE_CUDA_STANDARD} | sm_${CMAKE_CUDA_ARCHITECTURES} | ${CMAKE_BUILD_TYPE}")
