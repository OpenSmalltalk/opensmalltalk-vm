#!/bin/bash
set -e

if [[ -n "${TRAVIS_TAG:-${APPVEYOR_REPO_TAG_NAME}}" ]]; then
  echo "Skipping a deployment to Bintray because build was pushed by a tag."
  exit
fi

echo "$(cat bintray.json | ../.git_filters/RevDateURL.smudge)" > bintray.json
sed -i.bak 's/$Rev: \([0-9][0-9]*\) \$/\1/' bintray.json
sed -i.bak 's/$Date: \(.*\) \$/\1/' bintray.json
rm -f bintray.json.bak

if [[ "${APPVEYOR}" ]]; then
    appveyor DownloadFile https://curl.haxx.se/ca/cacert.pem
    export SSL_CERT_FILE=cacert.pem
    export PATH="C:\\Ruby23\\bin:$PATH"
    export CMDSHELL="cmd /C "
fi

$CMDSHELL gem install dpl
$CMDSHELL dpl --provider=bintray --user=osvm --key=$BINTRAYAPIKEY --file=bintray.json --skip_cleanup=true
