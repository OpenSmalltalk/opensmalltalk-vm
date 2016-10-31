#!/bin/bash
set -e

if [[ "${FLAVOR}" = "newspeak"* ]]; then
  ./tests/newspeak/bootstrap.sh
fi
