@echo off
echo Building Galaga CPC...

set TOOLS_PATH=G:\Amstrad

REM Delete old DSK to ensure a 100% clean image with no leftover dummy files
if exist build\galaga.dsk del /f /q build\galaga.dsk

REM Create the raw one-sector backing file; it must be first so its data is #C5
python tools\make_highscore_seed.py build\highscore_seed.bin
if %ERRORLEVEL% NEQ 0 (
    echo Could not create the high-score disk sector!
    exit /b %ERRORLEVEL%
)

REM Assemble the source code using rasm
"%TOOLS_PATH%\rasm_w64.exe" src\main.asm -s -os build\galaga.sym -ob build\galaga.bin

REM Check for compilation errors
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

REM Import the raw score sector before the executable so it occupies track 0, #C5.
REM iDSK is run from WSL; it must be installed there.
wsl --cd "%CD%" -e iDSK build/galaga.dsk -n -i build/highscore_seed.bin -t 2
if %ERRORLEVEL% NEQ 0 (
    echo Could not create the DSK score sector!
    exit /b %ERRORLEVEL%
)

wsl --cd "%CD%" -e iDSK build/galaga.dsk -i build/galaga.bin -t 1 -c 2000 -e 2000 -f
if %ERRORLEVEL% NEQ 0 (
    echo Could not add GALAGA.BIN to the DSK!
    exit /b %ERRORLEVEL%
)

python tools\dsk2ext.py build\galaga.dsk
if %ERRORLEVEL% NEQ 0 (
    echo Could not convert the DSK to extended format!
    exit /b %ERRORLEVEL%
)

echo Build successful! The DSK image is in build\galaga.dsk.
