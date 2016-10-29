@ECHO OFF
SETLOCAL

REM ###############################################################################################
REM This script builds gdal windows wheels
REM 1. Download proj.4 source and build and output include, bin, lib into pkg folder
REM 2. Download libgeos source, fix the source and build and output include, bin, lib into pkg folder
REM 3. Download filegdb (1.4) and output include, bin, lib into pkg folder
REM 4. Download gdal and build and create py27 and py34 wheels with setup_32_win.py or setup_64_win.py (to include dlls)
REM 5. The wheels will be created in workdir_<arch>\dist
REM
REM Run from the directory containing the setup_32_win.py/setup_64_win.py and this script.
REM E.g. build_gdal_win_wheels.bat x86
REM E.g. build_gdal_win_wheels.bat amd64
REM
REM Other Required tools:
REM swigwin-3.0.10
REM 7-Zip\7z.exe

REM ###############################################################################################
REM Retrieving arguments

SET "ARCHITECTURE=%1"

REM ###########################################################################
REM Package specifications
REM
REM Note-1: For build environment details see https://biarrinetworks.atlassian.net/browse/DEV-2308
REM Note-2: When you need to change GDAL_VERSION, don't forget to check/update setup_32_win.py and setup_64_win.py

SET "GDAL_VERSION=2.0.3"
SET "GDAL_SRC_ZIP=gdal203.zip"

SET "PROJ_VERSION=4.9.3"
SET "PROJ_SRC_ZIP=%PROJ_VERSION%.zip"

SET "GEOS_VERSION=3.5.0"
SET "GEOS_SRC_ZIP=%GEOS_VERSION%.zip"
SET "GEOS_SVN_REVISION=3867"

SET "FILEGDB_NAME=filegdb_api_vs2010_1_4"
SET "FILEGDB_ZIP=%FILEGDB_NAME%.zip"

SET "PATH=C:\swigwin-3.0.10;%PATH%"

SET ZIP_EXE=C:\Program Files\7-Zip\7z.exe

ECHO ##########################################################################
ECHO BUILD_STEP: Preparing environment for using %ARCHITECTURE% VS and Python tools
ECHO ##########################################################################

REM Visual Studio version and environment configs
SET "VSINSTALLDIR=C:\Program Files (x86)\Microsoft Visual Studio 10.0"
SET VCINSTALLDIR=%VSINSTALLDIR%\VC
SET DEVENVDIR=%VSINSTALLDIR%\Common7\IDE
SET "INCLUDE=%VCINSTALLDIR%\include;%INCLUDE%"
SET "PATH=%VSINSTALLDIR%\Common7\Tools;%DEVENVDIR%;%VCINSTALLDIR%\VCPackages;%PATH%"

SET "MSVC_VER=1600"

IF "%ARCHITECTURE%"=="x86" (
  SET "PYTHON27=c:\Python27\python.exe"
  SET "PYTHON34=c:\Python34\python.exe"
  SET BIT_TAG="32"

  ECHO Using 32-bit vsvars32 ...
  SET "PATH=%VCINSTALLDIR%\bin;%PATH%"
  CALL "%VSINSTALLDIR%\Common7\Tools\vsvars32.bat"
) ELSE (
  IF "%ARCHITECTURE%"=="amd64" (
    SET "PYTHON27=c:\Python27_64\python.exe"
    SET "PYTHON34=c:\Python34_64\python.exe"
    SET BIT_TAG="64"

    SET "INCLUDE=C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include;%INCLUDE%"
    SET "PATH=%VCINSTALLDIR%\bin\amd64;%PATH%"
    ECHO Using 64-bit vsvars64 ...
    CALL "%VCINSTALLDIR%\bin\amd64\vcvars64.bat"
  ) ELSE (
    ECHO Unsupported architecture %ARCHITECTURE%.
    EXIT /B -1
  )
)

ECHO ##########################################################################
ECHO BUILD_STEP: Preparing work space workdir_%ARCHITECTURE%
ECHO ##########################################################################

SET "ROOT=%CD%"
SET "WORKDIR=%ROOT%\workdir_%ARCHITECTURE%"
SET "DIST=%WORKDIR%\dist"
IF EXIST "%WORKDIR%" (RD /S /Q "%WORKDIR%")
MKDIR %WORKDIR%
CD %WORKDIR%

ECHO Preparing directory for storing packages' bin/lib/include ...
SET "PKG_ROOT=%WORKDIR%\pkg"
SET "PKG_INCLUDEDIR=%PKG_ROOT%\include"
SET "PKG_BINDIR=%PKG_ROOT%\bin%BIT_TAG%"
SET "PKG_LIBDIR=%PKG_ROOT%\lib%BIT_TAG%"
MKDIR %PKG_BINDIR% %PKG_INCLUDEDIR% %PKG_LIBDIR%


ECHO ##########################################################################
ECHO BUILD_STEP: Building Proj4
ECHO ##########################################################################

ECHO Downloading Proj4 ...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/OSGeo/proj.4/archive/%PROJ_SRC_ZIP%', 'proj4_%PROJ_SRC_ZIP%')"

ECHO Extracting Proj4 ...
CALL "%ZIP_EXE%" x -aoa "proj4_%PROJ_SRC_ZIP%"

SET "PROJ_SRC=%WORKDIR%\proj.4-%PROJ_VERSION%"
SET "INSTDIR=%PROJ_SRC%_out"
IF EXIST "%INSTDIR%" (RD /S /Q "%INSTDIR%")
CD %PROJ_SRC%

ECHO Building Proj4 ...
NMAKE /E /F makefile.vc
IF %ERRORLEVEL% NEQ 0 (
  ECHO Failed to build proj4
  EXIT /B -1
)
NMAKE /E /F makefile.vc install-all
IF %ERRORLEVEL% NEQ 0 (
  ECHO Failed to install proj4 in the output directory
  EXIT /B -1
)

ECHO Staging package ...
XCOPY /Y /S /E /I "%INSTDIR%\include" "%PKG_INCLUDEDIR%\proj4"
XCOPY /Y "%INSTDIR%\bin\*.dll" "%PKG_BINDIR%"
XCOPY /Y "%INSTDIR%\lib\*.lib" "%PKG_LIBDIR%"


ECHO ##########################################################################
ECHO BUILD_STEP: Building GEOS
ECHO ##########################################################################
CD %WORKDIR%

ECHO Downloading GEOS ...
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/libgeos/libgeos/archive//%GEOS_SRC_ZIP%', 'geos_%GEOS_SRC_ZIP%')"

ECHO Extracting GEOS ...
CALL "%ZIP_EXE%" x -aoa "geos_%GEOS_SRC_ZIP%"

SET "GEOS_SRC=%WORKDIR%\libgeos-%GEOS_VERSION%"
CD %GEOS_SRC%

ECHO Building GEOS ...
CALL autogen.bat

REM Need to create/add geos_svn_revision.h manually; see https://trac.osgeo.org/geos/wiki/BuildingOnWindowsWithNMake
ECHO #define GEOS_SVN_REVISION %GEOS_SVN_REVISION% > geos_svn_revision.h

NMAKE /E /F makefile.vc MSVC_VER=%MSVC_VER%
IF %ERRORLEVEL% NEQ 0 (
  ECHO Failed to build geos
  EXIT /B -1
)

ECHO Staging package ...
XCOPY /Y /S /E /I "%GEOS_SRC%\include" "%PKG_INCLUDEDIR%"
XCOPY /Y "%GEOS_SRC%\src\*.dll" "%PKG_BINDIR%"
XCOPY /Y "%GEOS_SRC%\src\*.lib" "%PKG_LIBDIR%"
REM Need to copy geos_c.h (which is in capi instead of include) manually; see https://trac.osgeo.org/geos/ticket/777
XCOPY /Y  "%GEOS_SRC%\capi\geos_c.h" "%PKG_INCLUDEDIR%"


ECHO ##########################################################################
ECHO BUILD_STEP: Downloading FileGDB_api from Esri
ECHO ##########################################################################
CD %WORKDIR%

ECHO Downloading FileGDB ...
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://downloads2.esri.com/Software/%FILEGDB_ZIP%', '%FILEGDB_ZIP%')"

ECHO Extracting FileGDB ...
SET "FGDB_DIR=%WORKDIR%\%FILEGDB_NAME%"
CALL "%ZIP_EXE%" x -aoa "%FILEGDB_ZIP%" -o%FGDB_DIR%

XCOPY /Y "%FGDB_DIR%\include\*" "%PKG_INCLUDEDIR%"
IF "%ARCHITECTURE%"=="x86" (
  XCOPY /Y "%FGDB_DIR%\bin\*.dll" "%PKG_BINDIR%"
  XCOPY /Y "%FGDB_DIR%\lib\*.lib" "%PKG_LIBDIR%"
) ELSE (
  XCOPY /Y "%FGDB_DIR%\bin64\*.dll" "%PKG_BINDIR%"
  XCOPY /Y "%FGDB_DIR%\lib64\*.lib" "%PKG_LIBDIR%"
)

ECHO ##########################################################################
ECHO Set up build configs
ECHO ##########################################################################

SET "GEOS_CFLAGS=-I%PKG_INCLUDEDIR% -DHAVE_GEOS"
SET "GEOS_LIB=%PKG_LIBDIR%\geos_c_i.lib"

SET "PROJ_FLAGS=-DPROJ_STATIC"
SET "PROJ_INCLUDE=-I%PKG_INCLUDEDIR%\proj4"
SET "PROJ_LIBRARY=%PKG_LIBDIR%\proj.lib"

SET "FGDB_ENABLED=YES"
SET "FGDB_PLUGIN=NO"
SET "FGDB_INC=%PKG_INCLUDEDIR%"
SET "FGDB_LIB=%PKG_LIBDIR%\FileGDBAPI.lib"

ECHO ##########################################################################
ECHO BUILD_STEP: Building GDAL
ECHO ##########################################################################
CD %WORKDIR%

SET "OUTDIR=%WORKDIR%\out"
SET "GDAL_HOME=%OUTDIR%"
MKDIR %OUTDIR%

ECHO Downloading GDAL source ...
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://download.osgeo.org/gdal/%GDAL_VERSION%/%GDAL_SRC_ZIP%', '%GDAL_SRC_ZIP%')"

ECHO Extracting GDAL source ...
CALL "%ZIP_EXE%" x -aoa "%GDAL_SRC_ZIP%"

SET "GDAL_SRC=%WORKDIR%\gdal-%GDAL_VERSION%"
CD %GDAL_SRC%

IF "%ARCHITECTURE%"=="x86" (
  SET "MAKEFILE_OPT=makefile.vc"
) ELSE (
  SET "MAKEFILE_OPT=makefile.vc WIN64=YES"
)

NMAKE /E /F %MAKEFILE_OPT%
IF %ERRORLEVEL% NEQ 0 (
  ECHO Build failed
  EXIT /B -1
)
NMAKE /E /F %MAKEFILE_OPT% devinstall

ECHO ##########################################################################
ECHO BUILD_STEP: Building python bindings
ECHO ##########################################################################
CD %WORKDIR%

virtualenv py27_wheelmaker --python="%PYTHON27%"
CALL py27_wheelmaker\Scripts\activate.bat
SET "PYDIR=%WORKDIR%\py27_wheelmaker\Scripts"

CD "%GDAL_SRC%\swig"
NMAKE /E /F %MAKEFILE_OPT% python
IF %ERRORLEVEL% NEQ 0 (
  ECHO Build failed
  EXIT /B -1
)

ECHO ##########################################################################
ECHO BUILD_STEP: Overwriting setup.py
ECHO ##########################################################################

CD "%GDAL_SRC%\swig\python"
IF EXIST build (RD /S /Q build)

XCOPY /Y "%ROOT%\setup_%BIT_TAG%.py" setup.py

ECHO ##########################################################################
ECHO BUILD_STEP: Building py2 wheel
ECHO ##########################################################################

python setup.py bdist_wheel -d %DIST%
CALL deactivate

ECHO ##########################################################################
ECHO BUILD_STEP: Building py3 wheel
ECHO ##########################################################################

CD %WORKDIR%
virtualenv py34_wheelmaker --python="%PYTHON34%"
CALL py34_wheelmaker\Scripts\activate.bat
pip install wheel
CD "%GDAL_SRC%\swig\python"
IF EXIST build (RD /S /Q build)
python setup.py bdist_wheel -d %DIST%
CALL deactivate.bat
