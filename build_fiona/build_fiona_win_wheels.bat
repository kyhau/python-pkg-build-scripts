@ECHO OFF
SETLOCAL

REM ###############################################################################################
REM Notes: build gdal with build_gdal_win_wheels.bat first.

REM ###############################################################################################
REM Package specification

SET "PYTHON2=c:\Python27\python.exe"
SET "PYTHON3=c:\Python34\python.exe"

REM Visual Studio version and environment configs
set "VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 10.0"
set VCINSTALLDIR=%VSINSTALLDIR%\VC
set DevEnvDir=%VSINSTALLDIR%\Common7\IDE
set PATH=%VCINSTALLDIR%\bin;%VSINSTALLDIR%\Common7\Tools;%VSINSTALLDIR%\Common7\IDE;%VCINSTALLDIR%\VCPackages;%PATH%
set INCLUDE=%VCINSTALLDIR%\include;%INCLUDE%

CALL "%VSINSTALLDIR%\Common7\Tools\vsvars32.bat"

REM ###############################################################################################
REM Preparing work directory

SET "ROOT=%CD%"
SET "WORKDIR=%ROOT%\workdir"
SET "DIST=%WORKDIR%\dist"

CD %WORKDIR%

REM ###############################################################################################
REM Preparing directory for storing dependent package bin/lib/include

SET "GDAL_BUILD_OUT=%WORKDIR%\out"
SET "GDAL_BIN=%GDAL_BUILD_OUT%\bin"
SET "GDAL_DATA=%GDAL_BUILD_OUT%\data"
SET "GDAL_INCLUDE=%GDAL_BUILD_OUT%\include"
SET "GDAL_LIB=%GDAL_BUILD_OUT%\lib"

SET "PATH=%GDAL_BIN%;%GDAL_DATA%;%GDAL_INCLUDE%;%PATH%"

CD %WORKDIR%

ECHO Downloading Fiona source ...
git clone git://github.com/Toblerity/Fiona.git

SET "FIONA_SRC=%WORKDIR%\Fiona"
CD %FIONA_SRC%

ECHO ######################################################################
ECHO BUILD_STEP: Building py2 wheels
ECHO ######################################################################

virtualenv py2_wheelmaker --python="%PYTHON2%"
CALL py2_wheelmaker\Scripts\activate.bat
pip install cython
python setup.py build_ext -I%GDAL_INCLUDE% -lgdal_i -L%GDAL_LIB% install --gdalversion 2
python setup.py build_ext -I%GDAL_INCLUDE% -lgdal_i -L%GDAL_LIB% --gdalversion 2 bdist_wheel -d %DIST%
CALL deactivate

ECHO ######################################################################
ECHO BUILD_STEP: Building py3 wheels
ECHO ######################################################################

virtualenv py3_wheelmaker --python="%PYTHON3%"
CALL py3_wheelmaker\Scripts\activate.bat
::python -m pip install --upgrade pip
pip install cython
python setup.py build_ext -I%GDAL_INCLUDE% -lgdal_i -L%GDAL_LIB% install --gdalversion 2
python setup.py build_ext -I%GDAL_INCLUDE% -lgdal_i -L%GDAL_LIB% --gdalversion 2 bdist_wheel -d %DIST%
CALL deactivate.bat
