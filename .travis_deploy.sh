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

    # Clean out old versions from bintray, leaving only the last version per month
    if [[ "${TRAVIS_OS_NAME}" == "linux" ]] && [[ "${ARCH}" == "linux64x64" ]] && [[ "${FLAVOR}" == "squeak.cog.spur" ]]; then
	ruby -rdate -rnet/http -rjson -e "lastver=DateTime.now;
            user='timfel';
            pass='${BINTRAYAPIKEY}';
            url='https://api.bintray.com/packages/opensmalltalk/vm/cog';
            uri=URI(url);
            json=nil;
            http=Net::HTTP.new(uri.host,uri.port);
            http.use_ssl=true;
            http.start {
                req=Net::HTTP::Get.new(uri.request_uri);
                req.basic_auth(user,pass);
                resp=http.request(req);
                json=JSON.parse(resp.body)
            };
            (json['versions'][10..-1] || []).each { |v|
                ver=DateTime.parse(v);
                if ver.month != lastver.month then
                    lastver=ver; next
                else
                    lastver=ver
                end;
                uri=URI(url+'/versions/'+v);
                http=Net::HTTP.new(uri.host,uri.port);
                http.use_ssl=true;
                http.start {
                    req=Net::HTTP::Delete.new(uri.request_uri);
                    req.basic_auth(user,pass);
                    resp=http.request(req);
                    puts 'Deleted ' + v + ' ' + resp.body
                }
            }"
    fi
fi
