#!/bin/bash
TESTSUITE_PATH=/home/chy/develop/testsuite2
DEVELOPER_NAME=chenyu
export CVSROOT=":ext:${DEVELOPER_NAME}@gro.clinux.org:/cvsroot/skyeye"
export CVS_RSH="ssh"
cd ${TESTSUITE_PATH}/

#Zero step: clean old files
rm -rf ./skyeye-v1
rm -f ./skyeye ./auto_test ./exec_skyeye.sh ./exec_skyeye_dbct.sh

#First step: check newest source from cvs
cvs -z3 -d:ext:${DEVELOPER_NAME}@cvs.gro.clinux.org:/cvsroot/skyeye co skyeye-v1
#build skyeye with DBCT function
#cp -f ${TESTSUITE_PATH}/Makefile_gcc-3.3_with_DBCT_X86_32 skyeye-v1/
#second step: build skyeye image
cd skyeye-v1
#make CC=gcc-3.3 -C skyeye-v1
make -f Makefile_gcc-3.3_with_DBCT_X86_32
cd ..

#third step: copy some files into testsuite path,and run
cp skyeye-v1/binary/skyeye ${TESTSUITE_PATH}/
cp skyeye-v1/utils/tools/auto_test/auto_test ${TESTSUITE_PATH}/
cp skyeye-v1/utils/tools/auto_test/exec_skyeye.sh ${TESTSUITE_PATH}/
cp skyeye-v1/utils/tools/auto_test/exec_skyeye_dbct.sh ${TESTSUITE_PATH}/

./auto_test
