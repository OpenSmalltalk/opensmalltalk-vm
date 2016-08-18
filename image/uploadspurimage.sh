#!/bin/bash -e
# Upload a trunk46-spur.image/.changes to mirandabanda.org
RemoteUser=eliotmiranda@highland-park.dreamhost.com
RemoteRoot=mirandabanda.org/files/Cog/SpurImages
IFS="	
"
DATE=`date +%Y-%m-%d`
BASENAME=trunk46-spur

test "$1" = -here || cd `dirname $0`

DIR=$RemoteRoot/$DATE
echo ssh -x $RemoteUser mkdir $DIR
ssh -x $RemoteUser mkdir $DIR
for BASENAME in "$@"; do
	echo uploading $BASENAME from `pwd`
	cksum $BASENAME.[ci]* >$BASENAME.sum
	echo scp -p $BASENAME.image $BASENAME.changes $BASENAME.sum "$@" $RemoteUser:$DIR
	scp -p $BASENAME.image $BASENAME.changes $BASENAME.sum "$@" $RemoteUser:$DIR
done

echo ssh $RemoteUser chmod a-w $DIR/* \\\; ls -al $DIR
ssh $RemoteUser chmod a-w $DIR/* \; ls -al $DIR
echo ssh $RemoteUser rm -f $RemoteRoot/{*.image,*.changes,*.sum}
ssh $RemoteUser rm -f $RemoteRoot/{*.image,*.changes,*.sum}
echo ssh $RemoteUser cd $RemoteRoot \\\; ln -s $DATE/{*.image,*.changes,*.sum} .
ssh $RemoteUser cd $RemoteRoot \; ln -s $DATE/{*.image,*.changes,*.sum} .

ssh $RemoteUser ls -l $RemoteRoot $RemoteRoot/$DATE
