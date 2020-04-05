#!/bin/sh

TARGET=squeak5.0.1-solaris11.3.p5p 

if [ -f $TARGET ]
then
   echo "Please remove $TARGET."
   exit 0
fi

if [ ! -f squeak.ips ]
then
   echo "Please copy the squeak.ips script to this directory."
   exit 0
fi

if [ ! -f squeak5.p5m.mog ]
then
   echo "Please copy the squeak5.p5m.mog script to this directory."
   exit 0
fi

# create a reloc directory with 
if [ ! -d sqcogspursunosht ]
then
   echo "Please run this script in the 'products' directory."
   echo "Please build the 32bit binaries."
   exit 0
fi

if [ ! -d sqcogspur64sunosht ]
then
   echo "Please run this script in the 'products' directory."
   echo "Please build the 64bit binaries."
   exit 0
fi

if [ -d reloc ]
then
   echo "Please remove the reloc directory."
   exit 0
fi

if [ -d myrepo ]
then
   echo "Please remove the myrepo directory."
   exit 0
fi

mkdir reloc

(cd sqcogspursunosht; find . | cpio -mdvp ../reloc)
(cd sqcogspur64sunosht; find . | cpio -mdvp ../reloc)

# remove .a files (archives) from the build
# I don't understand why they are built
find reloc -name '*.a' -exec rm -f {} \;

# remove squeak script
rm -f reloc/usr/squeak

# now install our own IPS script for /usr/bin/squeak
# this script selects the 32bit or the 64bit vm
cp squeak.ips reloc/usr/bin/squeak

# the following p5m manifest should be edited
pkgsend generate reloc > squeak5.p5m.1

# remove all directories - except those that are specific to squeak
# if we don't do this, our IPS package will conflict with other IPS pkgs
sed -e '/path=usr$/d' -e '/path=usr\/bin$/d' -e '/path=usr\/lib$/d' -e '/path=usr\/share$/d' -e '/path=usr\/share\/doc$/d' -e '/path=usr\/share\/man$/d' -e '/path=usr\/share\/man\/man1$/d' < squeak5.p5m.1 > squeak5.p5m.2

# "mogrify" the package
cat squeak5.p5m.mog squeak5.p5m.2 | pkgfmt > squeak5.p5m

# publish
rm -rf myrepo
pkgrepo create -s myrepo 
pkgrepo -s myrepo set publisher/prefix=squeak
pkgsend publish -s myrepo -d reloc squeak5.p5m

# make a P5P archive file
pkgrecv -a -s myrepo -d $TARGET '*'

