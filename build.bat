@echo off
REM ============================================
REM  CppLearn - Build & Generate compile_commands.json
REM  1. Set up MSVC environment (vcvars64)
REM  2. CMake configure (Ninja + compile_commands.json)
REM  3. Build all targets
REM ============================================
echo ============================================
echo   CppLearn Build Script
echo ============================================
echo.

echo [1/3] Setting up MSVC environment...
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: vcvars64.bat not found - check VS2022 installation
    exit /b 1
)
echo         MSVC x64 environment ready.

echo [2/3] CMake Configure (Ninja)...
"C:\Users\13479\Tools\cmake-4.0.1-windows-x86_64\bin\cmake.exe" --preset default
if %ERRORLEVEL% neq 0 (
    echo ERROR: CMake configure failed
    exit /b 1
)

echo [3/3] Building all targets...
"C:\Users\13479\Tools\cmake-4.0.1-windows-x86_64\bin\cmake.exe" --build --preset default
if %ERRORLEVEL% neq 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo ============================================
echo   BUILD SUCCESSFUL
echo   compile_commands.json ready for clangd
echo ============================================
