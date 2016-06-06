set -e

echo "`cat .bintray.json | .git_filters/RevDateURL.smudge`" > .bintray.json
sed -i 's/$Rev: \([0-9][0-9]*\) \$/\1/' .bintray.json
sed -i 's/$Date: \(.*\) \$/\1/' .bintray.json
