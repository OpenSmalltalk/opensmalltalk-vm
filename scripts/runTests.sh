#!/usr/bin/env bash

set -ex

TEST_PACKAGES=".*"

extract_archive()
{
    ARCHIVE=$1
    case $ARCHIVE in
    *.zip)
        unzip $ARCHIVE -d .
        ;;
    *.*gz)
        tar -xvvzf $ARCHIVE
        ;;
    *.*bz2)
        tar -xvvjf $ARCHIVE
        ;;
    *)
        echo "Extraction of VM archive $ARCHIVE is unsupported."
        exit 1
        ;;
    esac
}

fetch_image()
{
    case $APPNAME in
    *)
        wget -O - https://get.pharo.org/64/80 | bash
        echo 80 > pharo.version
        TEST_IMAGE_NAME=$(ls Pharo*.image)
        ;;
    esac
}


case $(uname) in
Linux)
    TEST_VM_STAGE_NAME="unix64"
    if test "$APPNAME" = ""; then
        APPNAME="Pharo"
        VM_EXECUTABLE_NAME="pharo"
    fi
    TEST_VM_EXECUTABLE="./$VM_EXECUTABLE_NAME"
    VM_ARCHIVE=../artifacts/${APPNAME}VM-*-linux*-bin.zip
    ;;
Darwin)
    TEST_VM_STAGE_NAME="osx"
    if test "$APPNAME" = ""; then
        APPNAME="Pharo"
        VM_EXECUTABLE_NAME="Pharo"
    fi
    TEST_VM_EXECUTABLE="./$VM_EXECUTABLE_NAME.app/Contents/MacOS/$VM_EXECUTABLE_NAME"
    VM_ARCHIVE=../artifacts/${APPNAME}VM-*-mac*-bin.zip
    ;;
CYGWIN*)
    TEST_VM_STAGE_NAME="win64"
    if test "$APPNAME" = ""; then
        APPNAME="Pharo"
        VM_EXECUTABLE_NAME="Pharo"
    fi
    TEST_VM_EXECUTABLE="./${VM_EXECUTABLE_NAME}Console"
    VM_ARCHIVE=../artifacts/${APPNAME}VM-*-win*-bin.zip
    ;;
*)
    echo "Unsupported operating system $(uname) for running tests"
    exit 0
    ;;
esac

mkdir -p runTests
cd runTests

# Fetch VM
extract_archive $VM_ARCHIVE

# Fetch the image
fetch_image

# Run the tests
PHARO_CI_TESTING_ENVIRONMENT=true $TEST_VM_EXECUTABLE $TEST_IMAGE_NAME test --junit-xml-output --stage-name=$APPNAME-$TEST_VM_STAGE_NAME "$TEST_PACKAGES" || echo "Warning, some tests are failing"

# Copy the test results.
mkdir -p ../test-results
cp *.xml ../test-results
