################################################################################
# This script downloads and build gurobipy linux-64 py27 and py34 wheels
################################################################################
# Run:
# E.g. ./build_gurobipy_linux_wheels.sh 6.5.2 

if [[ $# -eq 0 ]]; then
  echo "Usage: ./build_gurobipy_linux_wheels.sh GUROBI_VERSION (e.g. 6.5.2)"
  exit 1
fi

GUROBI_VERSION=$1
GUROBU_MAJOR_MINOR_VERSION_STR=${GUROBI_VERSION%.*}
GUROBI_FILE=gurobi${GUROBI_VERSION}_linux64.tar.gz
GUROBI_DOWNLOAD_URL=http://packages.gurobi.com/${GUROBU_MAJOR_MINOR_VERSION_STR}/${GUROBI_FILE}

set -e

WORK_DIR=work_dir
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "######################################################################"
echo BUILD STEP: Download and extract $GUROBI_DOWNLOAD_URL
echo "######################################################################"

wget -c $GUROBI_DOWNLOAD_URL

tar -xzvf $GUROBI_FILE

SRC_DIR=gurobi${GUROBI_VERSION//.}/linux64
cd $SRC_DIR

echo "######################################################################"
echo BUILD STEP: Update ${SRC_DIR}/setup.py
echo "######################################################################"

sed -i -e 's/distutils.core/setuptools/g' setup.py

echo "######################################################################"
echo BUILD STEP: Build py27 wheel
echo "######################################################################"

virtualenv py2_wheelmaker --python=python2
. py2_wheelmaker/bin/activate
python setup.py bdist_wheel

FILE_FROM=gurobipy-${GUROBI_VERSION}-py2-none-any.whl
FILE_TO=gurobipy-${GUROBI_VERSION}-cp27-none-linux_x86_64.whl
echo Renaming $FILE_FROM to $FILE_TO  ... 
mv dist/$FILE_FROM dist/$FILE_TO

deactivate

rm -rf build

echo "######################################################################"
echo BUILD STEP: Build py34 wheel
echo "######################################################################"

if [[ $(grep "version != (3, 4)" setup.py) ]]; then
  virtualenv py3_wheelmaker --python=python3
  . py3_wheelmaker/bin/activate
  python setup.py bdist_wheel

  FILE_FROM=gurobipy-${GUROBI_VERSION}-py3-none-any.whl
  FILE_TO=gurobipy-${GUROBI_VERSION}-cp34-none-linux_x86_64.whl
  echo Renaming $FILE_FROM to $FILE_TO  ...
  mv dist/$FILE_FROM dist/$FILE_TO

  deactivate
else
  echo Gurobi ${GUROBI_VERSION} does not support Python 3.4. See setup.py for details.
  echo Skip building wheel for Python 3.4.
fi

echo "######################################################################"
echo Output wheels ${WORK_DIR}/${SRC_DIR}/dist
echo "######################################################################"

