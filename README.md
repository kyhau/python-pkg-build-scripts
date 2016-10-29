# python-pkg-build-scripts

This repo contains scripts for building the following python packages.

## gurobipy
1. gurobipy win32 wheels for python-2.7, python-3.4  
2. gurobipy linux wheels for python-2.7, python-3.4

**Notes**

gurobi-7.0.0 supports python-2.7, python-3.5
gurobi-6.5.2 supports python-2.7, python-3.4, python-3.5

## gdal with filegdb
1. gdal win32 wheels for python-2.7, python 3.4 (including filegdb, libgeos and proj.4 dlls)
2. gdal win64 wheels for python-2.7, python 3.4 (including filegdb, libgeos and proj.4 dlls)

**Create a new build machine**

1. Install python-2.7.12.msi
2. Install python-2.7.12.amd64.msi
3. Install python-3.4.4.msi (MSC v.1600 32 bit (Intel) on win32)
4. Install python-3.4.4.amd64.msi
5. Install swigwin-3.0.10
6. Install Visual Studio 2010 (for MSC v.1600)
7. Require also VCForPython27.msi ("Microsoft Visual C++ 9.0 is required. Get it from http://aka.ms/vcpython27")
8. Git-2.10.1-64-bit.exe
9. 7z1604-x64.msi

**Notes on libgeos**

1. libgeos does not really support Windows (the [official windows builds](https://trac.osgeo.org/geos#BuildandInstall) are red!
2. Need to create/add geos_svn_revision.h for windows build; see [here](https://trac.osgeo.org/geos/wiki/BuildingOnWindowsWithNMake).
3. Need to copy geos_c.h (which is in capi instead of include) build; see [here](https://trac.osgeo.org/geos/ticket/777).

**Linux**

Don't forget to update LD_LIBRARY_PATH to /opt/gurobixxx/linux64/lib

**Windows**

Don't forget to set GUROBI_HOME=c:\gurobixxx\win32 and add c:\gurobixxx\win32\bin PATH

## fiona
1. fiona win32 wheels for python-2.7, python 3.4
