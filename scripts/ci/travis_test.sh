#!/bin/bash
set -e

if [[ "${TESTIMAGE}" = "skip" ]]; then
  echo "Skipping SUnit testing!"
  exit 0
fi

case "${FLAVOR}" in
  "squeak"*|"pharo"*)
    "./tests/smalltalkCI.sh"
    ;;
  "newspeak"*)
    "./tests/newspeakBootstrap.sh"
    ;;
esac
