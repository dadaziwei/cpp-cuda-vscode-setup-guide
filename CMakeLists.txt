cmake_minimum_required(VERSION 3.21)

# ---- 项目定义：同时启用 C++ 和 CUDA ----
project(CppLearn
    VERSION 1.0
    DESCRIPTION "C++ & CUDA Learning Project"
    LANGUAGES CXX CUDA
)

# ---- 语言标准 ----
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# ---- GPU 架构：RTX 4060 = sm_89 (Ada Lovelace) ----
set(CMAKE_CUDA_ARCHITECTURES 89)

# ---- 为 clangd 生成 compile_commands.json ----
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ---- CUDA 运行时库：Shared 避免 CRT 冲突 ----
set(CMAKE_CUDA_RUNTIME_LIBRARY Shared)

# ---- 禁止 CUDA response files（clangd 兼容性） ----
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_INCLUDES OFF)
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_LIBRARIES OFF)
set(CMAKE_CUDA_USE_RESPONSE_FILE_FOR_OBJECTS OFF)

# ---- 编译器选项 ----
# C++ (MSVC): /W4 警告级别, /utf-8 源码编码
if(MSVC)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4 /utf-8")
endif()

# CUDA (nvcc): 忽略已废弃 GPU 目标警告
if(CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA")
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Wno-deprecated-gpu-targets")
endif()

# ============================================================
# 目标：C++ 基础示例
# ============================================================
add_executable(cpp_hello main.cpp)

# ============================================================
# 目标：C++ 章节示例（现代 C++ 教程）
# ============================================================
add_executable(ch2_01_nullptr ch2/2.01.nullptr.cpp)
add_executable(ch2_02_constexpr ch2/2.02.constexpr.cpp)
add_executable(ch2_03_if_switch ch2/2.03.if.switch.cpp)
add_executable(ch2_04_init_list ch2/2.04.initializer.list.cpp)
add_executable(ch2_05_struct_bind ch2/2.05.structured.binding.cpp)
add_executable(ch2_06_auto ch2/2.06.auto.cpp)
add_executable(ch2_07_decltype ch2/2.07.decltype.cpp)
add_executable(ch2_08_tail_return ch2/2.08.tail.return.type.cpp)
add_executable(ch2_09_decltype_auto ch2/2.09.decltype.auto.cpp)
add_executable(ch2_11_for ch2/2.11.for.loop.cpp)
add_executable(ch2_12_ext_template ch2/2.12.external.template.cpp)
add_executable(ch2_13_alias ch2/2.13.alias.template.cpp)
add_executable(ch2_14_def_tparam ch2/2.14.default.template.param.cpp)
add_executable(ch2_15_variadic ch2/2.15.variadic.template.param.cpp)
add_executable(ch2_16_fold ch2/2.16.fold.expression.cpp)
add_executable(ch2_18_nt_template ch2/2.18.non.type.template.auto.cpp)
add_executable(ch2_19_delegate ch2/2.19.delegate.constructor.cpp)
add_executable(ch2_20_enum ch2/2.20.strong.type.enum.cpp)

# ---- 为所有 .cpp 目标设置 VS 运行时库 ----
function(set_msvc_runtime target)
    if(MSVC)
        set_property(TARGET ${target} PROPERTY
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()
endfunction()

set_msvc_runtime(cpp_hello)
set_msvc_runtime(ch2_01_nullptr)
set_msvc_runtime(ch2_02_constexpr)
set_msvc_runtime(ch2_03_if_switch)
set_msvc_runtime(ch2_04_init_list)
set_msvc_runtime(ch2_05_struct_bind)
set_msvc_runtime(ch2_06_auto)
set_msvc_runtime(ch2_07_decltype)
set_msvc_runtime(ch2_08_tail_return)
set_msvc_runtime(ch2_09_decltype_auto)
set_msvc_runtime(ch2_11_for)
set_msvc_runtime(ch2_12_ext_template)
set_msvc_runtime(ch2_13_alias)
set_msvc_runtime(ch2_14_def_tparam)
set_msvc_runtime(ch2_15_variadic)
set_msvc_runtime(ch2_16_fold)
set_msvc_runtime(ch2_18_nt_template)
set_msvc_runtime(ch2_19_delegate)
set_msvc_runtime(ch2_20_enum)

# ============================================================
# 目标：CUDA 入门示例
# ============================================================
# 示例 1：Hello CUDA —— 验证环境
add_executable(cuda_hello src/hello_cuda.cu)

# 示例 2：向量加法 —— CUDA 经典入门
add_executable(cuda_vector_add src/vector_add.cu)

# ---- CUDA 可分离编译（按需启用） ----
set_target_properties(cuda_hello cuda_vector_add PROPERTIES
    CUDA_SEPARABLE_COMPILATION OFF
)

# ============================================================
# 打印配置摘要
# ============================================================
message(STATUS "========================================")
message(STATUS "  CppLearn Configuration")
message(STATUS "  C++ Standard:    ${CMAKE_CXX_STANDARD}")
message(STATUS "  CUDA Standard:   ${CMAKE_CUDA_STANDARD}")
message(STATUS "  GPU Architecture: sm_${CMAKE_CUDA_ARCHITECTURES}")
message(STATUS "  CUDA Toolkit:    ${CMAKE_CUDA_COMPILER}")
message(STATUS "  Build Type:      ${CMAKE_BUILD_TYPE}")
message(STATUS "========================================")
