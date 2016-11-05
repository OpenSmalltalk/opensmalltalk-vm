#!/bin/bash
set -e

if [[ "${FLAVOR}" = "newspeak"* ]]; then
  case "$(uname -s)" in
    "Linux")
      if [[ "${ARCH}" != *"ARM"* ]]; then
        sudo bash -c "ulimit -r 2 && ./tests/newspeakBootstrap.sh"
      fi
      ;;
    "Darwin")
      ./tests/newspeakBootstrap.sh
      ;;
  esac
fi
