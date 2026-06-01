@echo off
REM ============================================
REM  CppLearn - CMake Configure + Build
REM  Generates compile_commands.json for clangd
REM ============================================
echo ============================================
echo   CppLearn - Configure ^& Build
echo ============================================
echo.

echo [1/4] MSVC x64 environment...
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: vcvars64.bat failed
    exit /b 1
)

echo [2/4] Adding CUDA ^& Ninja to PATH...
set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin;C:\Users\13479\Tools\ninja;%PATH%"

echo [3/4] CMake Configure ^(Ninja + compile_commands.json^)...
"C:\Users\13479\Tools\cmake-4.0.1-windows-x86_64\bin\cmake.exe" --preset default -S "e:\CppLearn"
if %ERRORLEVEL% neq 0 (
    echo ERROR: CMake configure failed
    exit /b 1
)

echo.
echo [4/4] Building...
"C:\Users\13479\Tools\cmake-4.0.1-windows-x86_64\bin\cmake.exe" --build --preset default
if %ERRORLEVEL% neq 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo ============================================
echo   SUCCESS - All targets built
echo   compile_commands.json ready for clangd
echo ============================================
echo.
echo   Reload VSCode: Ctrl+Shift+P ^> "Developer: Reload Window"
echo.
