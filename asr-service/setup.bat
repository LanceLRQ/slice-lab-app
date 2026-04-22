@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo ==========================================
echo   Qwen3-ASR Service Windows Setup
echo ==========================================
echo.

:: 1. Detect Python environment
set PYTHON_MODE=
set PYTHON_BIN=

:: Check portable Python (bin\python + lib)
if exist "bin\python\python.exe" (
    if exist "lib\site-packages" (
        echo [INFO] Portable Python environment detected, using portable mode
        set PYTHON_MODE=portable
        set PYTHON_BIN=bin\python\python.exe
        set PIP_TARGET=--target=lib\site-packages
        goto :python_ready
    )
)

:: No portable environment, ask user
echo.
echo [INFO] Portable Python environment not detected (bin + lib directories missing)
echo.
echo Select Python environment setup method:
echo   1) Download portable package (recommended, ready to use)
echo   2) Use system Python + venv
echo.
set /p ENV_CHOICE="Enter choice [1/2] (default 1): "
if "%ENV_CHOICE%"=="" set ENV_CHOICE=1

if "%ENV_CHOICE%"=="2" goto :setup_venv

:: --- Option 1: Portable package ---
echo.
echo [INFO] Please download the portable package from:
echo.
echo   Baidu Pan: https://pan.baidu.com/s/1ahqW1mxIoNJTG2k6b4PkkA?pwd=6cth
echo   Access code: 6cth
echo.
echo   Download file: qwen3-asr-service-python3.12-pytorch2.6-cu124-bin.7z
echo.
echo [INFO] After extracting, place the bin and lib directories into the asr-service directory:
echo.
echo   asr-service\
echo   +-- bin\
echo   ^|   +-- python\
echo   ^|   ^|   +-- python.exe
echo   ^|   +-- ...
echo   +-- lib\
echo   ^|   +-- site-packages\
echo   ^|       +-- ...
echo   +-- setup.bat
echo   +-- start.bat
echo   +-- ...
echo.
echo [INFO] Once done, run start.bat to launch the service
echo.
pause
exit /b 0

:: --- Option 2: venv ---
:setup_venv
echo.
:: Check system python3/python version
set SYS_PYTHON=
where python >nul 2>&1
if %errorlevel%==0 (
    set SYS_PYTHON=python
) else (
    where python3 >nul 2>&1
    if %errorlevel%==0 (
        set SYS_PYTHON=python3
    )
)

if "%SYS_PYTHON%"=="" (
    echo [ERROR] System Python not found. Please install Python 3.12 first
    echo [ERROR] Download: https://www.python.org/downloads/
    pause
    exit /b 1
)

:: Check version is 3.12
for /f "tokens=*" %%v in ('%SYS_PYTHON% -c "import sys; print(f\"{sys.version_info.major}.{sys.version_info.minor}\")"') do set PY_VER=%%v
echo [INFO] Detected system Python version: %PY_VER%

if not "%PY_VER%"=="3.12" (
    echo.
    echo [ERROR] Current Python version is %PY_VER%, but 3.12 is required
    echo [ERROR] Please download Python 3.12: https://www.python.org/downloads/release/python-31213/
    echo [ERROR] Or use the portable package method - re-run setup.bat and select option 1
    pause
    exit /b 1
)

:: Check existing venv
if exist "venv" (
    echo [INFO] Existing venv virtual environment detected
    set /p REINSTALL_VENV="Delete and reinstall? [y/N]: "
    if /i "!REINSTALL_VENV!"=="y" (
        echo [INFO] Removing old virtual environment...
        rmdir /s /q venv
    ) else if /i "!REINSTALL_VENV!"=="yes" (
        echo [INFO] Removing old virtual environment...
        rmdir /s /q venv
    ) else (
        echo [INFO] Keeping existing virtual environment, skipping creation
        goto :venv_activate
    )
)

echo [INFO] Creating virtual environment...
%SYS_PYTHON% -m venv venv

:venv_activate
call venv\Scripts\activate.bat
set PYTHON_MODE=venv
set PYTHON_BIN=venv\Scripts\python.exe
set PIP_TARGET=
echo [INFO] venv virtual environment activated

:: Upgrade pip in venv
echo [INFO] Upgrading pip...
%PYTHON_BIN% -m pip install --upgrade pip
goto :python_ready

:python_ready
:: Create necessary directories
if not exist "lib\site-packages" (
    if "%PYTHON_MODE%"=="portable" (
        mkdir lib\site-packages
        echo [INFO] Created lib\site-packages
    )
)

:: Install pip for portable mode
if "%PYTHON_MODE%"=="portable" (
    if not exist "bin\python\Scripts\pip.exe" (
        echo [INFO] Installing pip...
        if not exist "bin\get-pip.py" (
            echo [INFO] Downloading get-pip.py...
            powershell -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'bin\get-pip.py'"
        )
        bin\python\python.exe bin\get-pip.py
        echo [INFO] pip installed
    ) else (
        echo [INFO] pip already installed
    )
)

:: 4. Check CUDA
echo.
echo [INFO] Checking NVIDIA GPU...
nvidia-smi >nul 2>&1
if %errorlevel%==0 (
    echo [INFO] NVIDIA GPU detected, will install CUDA PyTorch
    set TORCH_INDEX=https://download.pytorch.org/whl/cu124
) else (
    echo [WARN] No GPU detected, will install CPU PyTorch
    set TORCH_INDEX=https://download.pytorch.org/whl/cpu
)

:: 5. Model source selection
echo.
echo ==========================================
echo   Model Configuration
echo ==========================================
echo.
echo Select model source:
echo   1) ModelScope (recommended for China)
echo   2) HuggingFace
echo   3) Manual (skip download)
echo.
set /p MODEL_CHOICE="Enter choice [1/2/3] (default 1): "
if "%MODEL_CHOICE%"=="" set MODEL_CHOICE=1

if "%MODEL_CHOICE%"=="1" (
    set MODEL_SOURCE=modelscope
    echo [INFO] Selected ModelScope
) else if "%MODEL_CHOICE%"=="2" (
    set MODEL_SOURCE=huggingface
    echo [INFO] Selected HuggingFace
) else if "%MODEL_CHOICE%"=="3" (
    set MODEL_SOURCE=manual
    echo [INFO] Selected manual mode
    echo.
    echo ==========================================
    echo   Manual Model Placement Guide
    echo ==========================================
    echo.
    echo Place model files in these directories:
    echo.
    echo   ASR 0.6B: %CD%\models\asr\0.6b\
    echo   ASR 1.7B: %CD%\models\asr\1.7b\
    echo   Align:    %CD%\models\align\0.6b\
    echo   VAD:      %CD%\models\vad\fsmn\
    echo   Punc:     %CD%\models\punc\ct-transformer\
    echo.
    echo Download from:
    echo   https://modelscope.cn/models/Qwen/Qwen3-ASR-0.6B
    echo   https://modelscope.cn/models/Qwen/Qwen3-ASR-1.7B
    echo.
    goto :end
) else (
    set MODEL_SOURCE=modelscope
    echo [INFO] Invalid option, using ModelScope
)

:: 6. Install PyTorch
echo.
echo [INFO] Installing PyTorch 2.6.0 (this may take several minutes)...
if "%TORCH_INDEX%"=="https://download.pytorch.org/whl/cu124" (
    %PYTHON_BIN% -m pip install %PIP_TARGET% torch==2.6.0+cu124 torchaudio==2.6.0+cu124 --index-url %TORCH_INDEX%
) else (
    %PYTHON_BIN% -m pip install %PIP_TARGET% torch torchaudio --index-url %TORCH_INDEX%
)

:: 7. Install other dependencies
echo.
echo [INFO] Installing project dependencies...
%PYTHON_BIN% -m pip install %PIP_TARGET% -r requirements.txt

:end
echo.
echo ==========================================
echo   Setup Complete
echo ==========================================
echo.
echo To start the service:
echo   start.bat --model-source %MODEL_SOURCE%
echo.
echo Or with custom options:
echo   start.bat --device cuda --model-size 0.6b --model-source %MODEL_SOURCE%
echo.
pause
