# Windows 上 C++20 + CUDA 开发环境完全指南

> 一套可复用的 VSCode 配置模板，解决 MSVC + Ninja + clangd + nvcc 的工具链兼容性问题。编译零错误，IntelliSense 零报错。

## 目录

- [为什么需要这套配置](#为什么需要这套配置)
- [环境概览](#环境概览)
- [快速开始](#快速开始)
- [架构设计：工具链依赖链](#架构设计师工具链依赖链)
- [配置文件详解](#配置文件详解)
- [适配你自己的环境](#适配你自己的环境)
- [CUDA 性能验证](#cuda-性能验证)

---

## 为什么需要这套配置

在 Windows 上用 VSCode 做 C++/CUDA 开发，默认配置会遇到三个核心矛盾：

### 矛盾 1：两个 IntelliSense 引擎互抢

Microsoft C/C++ 扩展和 clangd 扩展同时激活时，VSCode 弹窗报冲突，头文件全部红色波浪线。**必须二选一**——clangd 对 C++20 和 CUDA 的支持更好，选它。

### 矛盾 2：编译器体系不兼容

MSYS2 的工具链（cmake、ninja、bash）工作在 Unix 模式下，而 Windows 上 CUDA 的 host compiler 必须是 MSVC。混用会导致路径转义、shell 不兼容等问题。**关键工具必须用 Windows 原生版本**。

### 矛盾 3：构建和 IntelliSense 走两条路

`compile_commands.json` 是 clangd 的"眼睛"——没有它，clangd 找不到标准库。Visual Studio 生成器虽然开箱即用，但**不输出** `compile_commands.json`。Ninja 生成器能输出，但需要手动设置 MSVC 环境。这条依赖链就是整套配置的核心骨架。

---

## 环境概览

| 组件 | 版本 |
|------|------|
| OS | Windows 11 / 10 |
| GPU | NVIDIA RTX 4060 (sm_89) / 任意 CUDA 兼容 GPU |
| C++ 编译器 | MSVC 2022 |
| CUDA 编译器 | nvcc 12.8 |
| 构建系统 | CMake 4.0 + Ninja 1.12（均为 Windows 原生版） |
| 语言服务器 | clangd（LLVM） |
| C++ 标准 | C++20 |
| CUDA 标准 | C++17 |

---

## 快速开始

```batch
# 1. 克隆仓库
git clone https://github.com/dadaziwei/cpp-cuda-vscode-setup-guide.git
cd cpp-cuda-vscode-setup-guide

# 2. 按你的本机路径修改这三个文件中的路径（见「适配你自己的环境」一节）
#    - CMakePresets.json
#    - .clangd
#    - .vscode/settings.json

# 3. 一键构建
.\build.bat

# 4. 重载 VSCode
# Ctrl+Shift+P → Developer: Reload Window
```

---

## 架构设计：工具链依赖链

```
clangd 工作
  └→ 依赖 compile_commands.json
       └→ 只有 Ninja 生成器产出
            ├─ 需要 Windows 原生 cmake
            │   └→ MSYS2 cmake 无法检测 VS 工具链
            ├─ 需要 Windows 原生 ninja
            │   └→ MSYS2 ninja 用 bash 当 shell，破坏 MSVC 路径
            └─ 需要 vcvars64.bat
                 └→ MSVC 不注册系统 PATH
```

### 工具选型依据

| 工具 | 选型 | 排除的理由 |
|------|------|-----------|
| **cmake** | Windows 原生版 | MSYS2 版不带 VS 生成器，也无法检测 MSVC 工具链 |
| **ninja** | Windows 原生版 | MSYS2 版默认 shell 是 bash，会把 `C:\Program Files\...` 的反斜杠当转义符吃掉 |
| **IntelliSense** | clangd 独占 | 与 Microsoft C/C++ 同时启用会冲突弹窗 |
| **构建生成器** | Ninja | VS 生成器不产生 `compile_commands.json`，clangd 无法工作 |
| **Host Compiler** | MSVC | CUDA on Windows 的 nvcc 官方只支持 MSVC 做 host compiler |

### 为什么不能"全用 MSYS2"

MSYS2 提供的 clang + cmake + ninja 在纯 C++ 项目里可用，但一旦加入 CUDA：

- nvcc 在 Windows 上**只支持 MSVC 作为 host compiler**
- MSYS2 cmake 无法自动发现 VS 安装位置
- MSYS2 ninja 的 bash shell 会损坏 MSVC 命令行中的路径

所以正确的策略是：**用 MSVC 工具链编译，用 Windows 原生工具构建，用 clangd 做代码提示**。

---

## 配置文件详解

### 项目结构

```
.
├── CMakeLists.txt          # 构建定义
├── CMakePresets.json       # CMake 预设（编译器 + 生成器）
├── .clangd                 # clangd 配置（分文件类型）
├── build.bat               # 一键构建脚本
├── .vscode/
│   └── settings.json       # VSCode 设置
├── main.cpp                # C++ 示例入口
├── src/
│   ├── hello_cuda.cu       # GPU 设备检测
│   └── vector_add.cu       # 向量加法性能测试
└── .gitignore
```

### `CMakePresets.json` — 编译器 + 构建工具指定

```json
{
    "version": 6,
    "configurePresets": [{
        "name": "default",
        "generator": "Ninja",
        "binaryDir": "${sourceDir}/out/build/${presetName}",
        "cacheVariables": {
            "CMAKE_C_COMPILER":   "<你的 MSVC cl.exe 完整路径>",
            "CMAKE_CXX_COMPILER": "<同上>",
            "CMAKE_MAKE_PROGRAM": "<Windows 原生 ninja.exe 路径>",
            "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
        }
    }]
}
```

三个关键点：
- **`generator: "Ninja"`**：只有 Ninja 产出 `compile_commands.json`
- **编译器用完整绝对路径**：不依赖 PATH，避免 vcvars 注入的短路径
- **ninja 用 Windows 原生版**：MSYS2 的 ninja 会调用 bash 破坏 MSVC 命令行

### `.clangd` — 分文件类型的 IntelliSense 配置

```yaml
# === 全局：所有文件共享 ===
CompileFlags:
  CompilationDatabase: out/build/default
  Add:
    # C++ 标准库路径（clangd 进程没有 MSVC 环境变量，必须显式指定）
    - -I<MSVC include 路径>
    - -I<Windows SDK ucrt 路径>
    - -I<Windows SDK shared 路径>
    - -I<Windows SDK um 路径>
    - -I<Windows SDK winrt 路径>
  Remove:
    # 去掉 nvcc 独有而 clang 不认识的 flag
    - -forward-unknown-to-host-compiler
    - --generate-code*
    - -rdc=true

---
# === 仅 .cu / .cuh 文件 ===
If:
  PathMatch: .*\.(cu|cuh)$
CompileFlags:
  Add:
    - -xcuda
    - --cuda-path=<CUDA Toolkit 路径>
    - --cuda-gpu-arch=sm_89
```

两个关键设计：

1. **全局 `Add` 不加 `-xcuda`**：`CompileFlags.Add` 对所有文件生效。如果在这里加了 `-xcuda`，`.cpp` 会被当成 CUDA 解析，标准库全部找不到。

2. **用 `---` + `If` 隔离 CUDA 标志**：`-xcuda` 和 `--cuda-path` 只对 `.cu`/`.cuh` 文件添加，C++ 文件不受影响。

3. **显式指定 MSVC 头文件路径**：clangd 是独立进程，不继承终端的环境变量（`INCLUDE`、`LIB`）。即使你在终端跑了 `vcvars64`，clangd 也看不到。必须把路径写死在 `.clangd` 里。

### `.vscode/settings.json` — 扩展管理

```json
{
    "C_Cpp.intelliSenseEngine": "disabled",
    "clangd.path": "<clangd.exe 路径>",
    "clangd.arguments": [
        "--compile-commands-dir=out/build/default"
    ],
    "cmake.configureOnOpen": false
}
```

- **`C_Cpp.intelliSenseEngine: "disabled"`**：彻底禁用 Microsoft C/C++ 的 IntelliSense，避免与 clangd 冲突
- **`cmake.configureOnOpen: false`**：因为配置需要 vcvars 环境，不能自动触发

### `build.bat` — 一键构建

```batch
call "C:\...\vcvars64.bat"          # 注入 MSVC 环境
cmake --preset default               # Ninja 配置 + 生成 compile_commands.json
cmake --build --preset default       # 编译全部目标
```

每次新增 `.cpp` 或 `.cu` 后运行一次，clangd 会自动重新索引。

---

## 适配你自己的环境

这是一个模板工程，你只需要改三个文件中的路径。以下是查找方法：

### 1. 找到你的 MSVC 版本

```batch
# 运行 VS 的 vcvars64.bat，然后查看环境变量
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
echo %VCToolsInstallDir%
echo %WindowsSdkDir%
```

### 2. 找到你的 CUDA 路径和 GPU 架构

```batch
where nvcc           # → CUDA 安装位置
nvidia-smi           # → 查看 GPU 型号
```
然后查 [NVIDIA GPU 计算能力表](https://developer.nvidia.com/cuda-gpus) 获取 `sm_xx` 值。

### 3. 下载 Windows 原生工具

| 工具 | 下载 |
|------|------|
| CMake | [cmake-*-windows-x86_64.zip](https://github.com/Kitware/CMake/releases)（便携版，解压即用） |
| Ninja | [ninja-win.zip](https://github.com/ninja-build/ninja/releases)（单个 exe） |

### 4. 需要修改的字段汇总

| 文件 | 字段 | 示例值 |
|------|------|--------|
| `CMakePresets.json` | `CMAKE_C_COMPILER` | `C:/.../MSVC/14.44.35207/bin/Hostx64/x64/cl.exe` |
| `CMakePresets.json` | `CMAKE_CXX_COMPILER` | 同上 |
| `CMakePresets.json` | `CMAKE_MAKE_PROGRAM` | `C:/Tools/ninja/ninja.exe` |
| `.clangd` | MSVC include 路径 | `C:/.../MSVC/14.44.35207/include` |
| `.clangd` | Windows SDK 路径 | `C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/...` |
| `.clangd` | `--cuda-path` | `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v12.8` |
| `.clangd` | `--cuda-gpu-arch` | `sm_89`（RTX 4060） |
| `.vscode/settings.json` | `clangd.path` | `C:/Program Files/LLVM/bin/clangd.exe` |
| `.vscode/settings.json` | `cmake.cmakePath` | Windows 原生 cmake 路径 |
| `build.bat` | `vcvars64.bat` 路径 | VS 安装位置决定 |

---

## CUDA 性能验证

在 RTX 4060 Laptop 上的运行结果：

```
Device 0: NVIDIA GeForce RTX 4060 Laptop GPU
  Compute Capability:    8.9
  Multiprocessors (SM):  24
  Global Memory:         8.00 GB

CUDA Vector Addition: C = A + B
  Elements: 16777216 (64.0 MB)
  GPU Time:   0.959 ms
  Bandwidth:  210.02 GB/s
  Errors:     0
  Result:     PASSED
```

---

## 许可

MIT
