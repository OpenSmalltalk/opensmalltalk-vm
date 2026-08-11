#!/usr/bin/env bash
set -e

BASE=trunk6
BASE64=trunk6-64
BASESISTA64=trunk6-sista-64

# N.B. uname -r (OSREL) is not to be trusted on Mac OS X;

if test -x uname; then
	OS=$(uname -s)
	CPU=$(uname -m)
	OSREL=$(uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/')
elif test -x uname; then
	OS=$(uname -s)
	CPU=$(uname -m)
	OSREL=$(uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/')
else
	OS=$(uname -s)
	CPU=$(uname -m)
	OSREL=$(uname -r | sed 's/\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1.\2.\3/')
fi

function quietmd5() {
  if command -v md5 >/dev/null 2>&1; then
    # macOS / BSD
    md5 -q "$1" 2>/dev/null
  elif command -v md5sum >/dev/null 2>&1; then
    # Linux / BusyBox
    md5sum "$1" 2>/dev/null | cut -d ' ' -f 1
  else
    echo "quietmd5: neither md5 nor md5sum found in PATH" >&2
    return 1
  fi
}

function geturl() {
  local url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -C - -O "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -c "$url"
  else
    echo "geturl: neither curl nor wget found in PATH" >&2
    return 1
  fi
}

if ! command -v unzip >/dev/null 2>&1; then
	echo 'could not find unzip.  you can find instructions on how to install it on google.' 1>&2;
	exit 1
fi
