@ECHO OFF
SETLOCAL

REM ###############################################################################################
REM Before you run this script
REM 1. Download and install http://packages.gurobi.com/x.x/Gurobi-x.x.x-win32.msi on Fenris
REM
REM This script builds gurobipy windows wheels
REM 1. Copy "GUROBI_ROOT_DIR" to the current directory
REM 2. Edit setup.py - change `distutils.core` to `setuptools`
REM 3. Create py27 and py34
REM 4. The wheels will be created in the `dist` folder
REM
REM Quick start:
REM E.g. build_gurobipy_win_wheels.bat 6.5.2 x86 C:\gurobi652

REM ###############################################################################################
REM Retrieving arguments

SET "GUROBI_VERSION=%1"
SET "ARCHITECTURE=%2"
SET "GUROBI_ROOT_DIR=%3"

REM ###########################################################################
REM Package specifications

SET "OUTPUT_DIST_DIR=dist"
SET "WORK_DIR=%CD%"

ECHO ##########################################################################
ECHO BUILD_STEP: Preparing environment for %ARCHITECTURE%
ECHO ##########################################################################

IF "%ARCHITECTURE%"=="x86" (
  SET "ARCH_TAG=win32"
  SET "PYTHON27=C:\Python27\python.exe"
  SET "PYTHON34=c:\Python34\python.exe"
) ELSE (
  ECHO Unsupported architecture %ARCHITECTURE%.
  EXIT /B -1
)

SET "GUROBI_HOME=%GUROBI_ROOT_DIR%\%ARCH_TAG%"
SET "PATH=%GUROBI_HOME%\bin;%PATH%"

ECHO ##########################################################################
ECHO BUILD_STEP: Copying %GUROBI_ROOT_DIR%\%ARCH_TAG% to workspace ...
ECHO ##########################################################################

XCOPY /Y /S /E /I "%GUROBI_ROOT_DIR%\%ARCH_TAG%" "%WORK_DIR%\%ARCH_TAG%"

PUSHD "%WORK_DIR%\%ARCH_TAG%"

ECHO ##########################################################################
ECHO BUILD_STEP: Editing setup.py - change `distutils.core` to `setuptools`
ECHO ##########################################################################
SET "SETUP_PY=%WORK_DIR%\%ARCH_TAG%\setup.py"
powershell -Command "(Get-Content %SETUP_PY%) -replace 'distutils.core', 'setuptools' | Set-Content %SETUP_PY%"

ECHO ##########################################################################
ECHO BUILD_STEP: Building py27 wheel
ECHO ##########################################################################
IF EXIST build (RD /S /Q build)
IF EXIST py27_wheelmaker (RD /S /Q py27_wheelmaker)

virtualenv py27_wheelmaker --python="%PYTHON27%"
CALL py27_wheelmaker\Scripts\activate.bat
python -m pip install -U pip
pip install wheel
python setup.py bdist_wheel -d %OUTPUT_DIST_DIR%

SET "FILE_FROM=%OUTPUT_DIST_DIR%\gurobipy-%GUROBI_VERSION%-py2-none-any.whl"
SET "FILE_TO=%OUTPUT_DIST_DIR%\gurobipy-%GUROBI_VERSION%-cp27-cp27m-%ARCH_TAG%.whl"
ECHO Renaming %FILE_FROM% to %FILE_TO ...%
MOVE /Y %FILE_FROM% %FILE_TO%

ECHO ##########################################################################
ECHO BUILD_STEP: Testing py27 wheel
ECHO ##########################################################################
pip install %FILE_TO%
python -c "import gurobipy"

CALL deactivate.bat

ECHO ##########################################################################
ECHO BUILD_STEP: Building py34 wheel
ECHO ##########################################################################
IF EXIST build (RD /S /Q build)
IF EXIST py34_wheelmaker (RD /S /Q py34_wheelmaker)

FIND /I "version != (3, 4)" setup.py
IF errorlevel 0 (
  ECHO Gurobi %GUROBI_VERSION% does not support Python 3.4. See setup.py for details.
  EXIT /B 0
)

virtualenv py34_wheelmaker --python="%PYTHON34%"
CALL py34_wheelmaker\Scripts\activate.bat
python -m pip install -U pip
pip install wheel
python setup.py bdist_wheel -d %OUTPUT_DIST_DIR%

SET "FILE_FROM=%OUTPUT_DIST_DIR%\gurobipy-%GUROBI_VERSION%-py3-none-any.whl"
SET "FILE_TO=%OUTPUT_DIST_DIR%\gurobipy-%GUROBI_VERSION%-cp34-cp34m-%ARCH_TAG%.whl"
ECHO Renaming %FILE_FROM% to %FILE_TO ...%
MOVE /Y %FILE_FROM% %FILE_TO%

ECHO ##########################################################################
ECHO BUILD_STEP: Testing py34 wheel
ECHO ##########################################################################
pip install %FILE_TO%
python -c "import gurobipy"

CALL deactivate.bat

POPD
