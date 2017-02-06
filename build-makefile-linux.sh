#! /bin/bash 
# I execute configure for linux platforms. 
# I am called in .travis.yml, script section

set -e

if [ "$TRAVIS_OS_NAME" != "linux" ]; then 
	exit
fi
cd ../opensmalltalk-vm/platforms/unix/config/ && $CHROOT make configure