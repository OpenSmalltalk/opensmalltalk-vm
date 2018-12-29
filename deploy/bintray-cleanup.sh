#!/bin/bash
set -e

# Remove old versions from bintray, leaving only the last version per month
if [[ "${TRAVIS_OS_NAME}" == "linux" ]] && [[ "${ARCH}" == "linux64x64" ]] && [[ "${FLAVOR}" == "squeak.cog.spur" ]]; then
    ruby -rdate -rnet/http -rjson -e "lastver=DateTime.now;
        user='osvm';
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
