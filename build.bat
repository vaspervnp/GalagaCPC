@echo off
echo Building Galaga CPC...

set TOOLS_PATH=G:\Amstrad

REM Delete old DSK to ensure a 100% clean image with no leftover dummy files
if exist build\galaga.dsk del /f /q build\galaga.dsk

REM Assemble the source code using rasm
"%TOOLS_PATH%\rasm_w64.exe" src\main.asm -eo -o build\galaga

REM Check for compilation errors
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build successful! The DSK image is in build\galaga.dsk.
