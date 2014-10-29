#!/bin/sh
# Upload a trunk46-spur.image/.changes to mirandabanda.org
RemoteUser=eliotmiranda@highland-park.dreamhost.com
RemoteRoot=mirandabanda.org/files/Cog/SpurImages
IFS="	
"
DATE=`date +%Y-%m-%d`
BASENAME=trunk46-spur

test "$1" = -here || cd `dirname $0`
echo uploading trunk46-spur from `pwd`

DIR=$RemoteRoot/$DATE
echo ssh -x $RemoteUser mkdir $DIR
ssh -x $RemoteUser mkdir $DIR
echo scp -p $BASENAME.image $BASENAME.changes "$@" $RemoteUser:$DIR
scp -p $BASENAME.image $BASENAME.changes "$@" $RemoteUser:$DIR
echo ssh $RemoteUser chmod a-w $DIR/* \\\; ls -al $DIR
ssh $RemoteUser chmod a-w $DIR/* \; ls -al $DIR
echo ssh $RemoteUser rm $RemoteRoot/{$BASENAME.image,$BASENAME.changes}
ssh $RemoteUser rm $RemoteRoot/{$BASENAME.image,$BASENAME.changes}
echo ssh $RemoteUser cd $RemoteRoot \\\; ln -s $DATE/{$BASENAME.image,$BASENAME.changes} .
ssh $RemoteUser cd $RemoteRoot \; ln -s $DATE/{$BASENAME.image,$BASENAME.changes} .
ssh $RemoteUser ls -l $RemoteRoot $RemoteRoot/$DATE
