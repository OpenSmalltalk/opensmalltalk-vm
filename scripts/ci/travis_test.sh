#!/bin/bash
set -e

# Don't run tests on ARM (ARM builds already take a long time)
[[ "${ARCH}" == *"ARM"* ]] && exit 0

./tests/smalltalkCI.sh
