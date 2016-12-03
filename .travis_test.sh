#!/bin/bash
set -e

# Don't run tests on ARM (ARM builds already take a long time)
[[ "${ARCH}" == *"ARM"* ]] && exit 0

# This can be dropped once https://github.com/travis-ci/travis-build/pull/879 is merged and in production
if [[ "$(uname -s)" = "Linux" ]]; then
  wget -q https://raw.githubusercontent.com/hpi-swa/smalltalkCI/master/utils/set_rtprio_limit.c
  gcc -o set_rtprio_limit set_rtprio_limit.c
  chmod +x ./set_rtprio_limit
  sudo ./set_rtprio_limit $$
fi

case "${FLAVOR}" in
  "squeak"*|"pharo"*)
    "./tests/smalltalkCI.sh"
    ;;
  "newspeak"*)
    "./tests/newspeakBootstrap.sh"
    ;;
esac
