PR=${TRAVIS_PULL_REQUEST:-${APPVEYOR_PULL_REQUEST_NUMBER:-false}}
BR=${TRAVIS_BRANCH:-${APPVEYOR_REPO_BRANCH}}

if [[ $PR == "false" ]] && ( [[ "$BR" == "Cog" || "$BR" == "master" ]] ); then
    echo "`cat .bintray.json | .git_filters/RevDateURL.smudge`" > .bintray.json
    sed -i.bak 's/$Rev: \([0-9][0-9]*\) \$/\1/' .bintray.json
    sed -i.bak 's/$Date: \(.*\) \$/\1/' .bintray.json
    rm -f .bintray.json.bak

    if [[ "${APPVEYOR}" ]]; then
        appveyor DownloadFile https://curl.haxx.se/ca/cacert.pem
        export SSL_CERT_FILE=cacert.pem
        export PATH="C:\\Ruby23\\bin:$PATH"
        export CMDSHELL="cmd /C "
    fi
    $CMDSHELL gem install dpl
    $CMDSHELL dpl --provider=bintray --user=timfel --key=$BINTRAYAPIKEY --file=.bintray.json
fi