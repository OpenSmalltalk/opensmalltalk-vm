#!/bin/sh -e
# Upload a trunk46-spur.image/.changes to mirandabanda.org
RemoteUser=eliotmiranda@highland-park.dreamhost.com
RemoteRoot=mirandabanda.org/files/Cog/SpurImages
IFS="	
"
DATE=`date +%Y-%m-%d`
BASENAME=trunk46-spur

test "$1" = -here || cd `dirname $0`
echo uploading $BASENAME from `pwd`
cksum $BASENAME.[ci]* >$BASENAME.sum

DIR=$RemoteRoot/$DATE
echo ssh -x $RemoteUser mkdir $DIR
ssh -x $RemoteUser mkdir $DIR
echo scp -p $BASENAME.image $BASENAME.changes $BASENAME.sum "$@" $RemoteUser:$DIR
scp -p $BASENAME.image $BASENAME.changes $BASENAME.sum "$@" $RemoteUser:$DIR
echo ssh $RemoteUser chmod a-w $DIR/* \\\; ls -al $DIR
ssh $RemoteUser chmod a-w $DIR/* \; ls -al $DIR
echo ssh $RemoteUser rm -f \
	$RemoteRoot/{$BASENAME.image,$BASENAME.changes,$BASENAME.sum} \
	$RemoteRoot/{$BASENAME-64.image,$BASENAME-64.changes,$BASENAME-64.sum}
ssh $RemoteUser rm -f \
	$RemoteRoot/{$BASENAME.image,$BASENAME.changes,$BASENAME.sum} \
	$RemoteRoot/{$BASENAME-64.image,$BASENAME-64.changes,$BASENAME-64.sum}
echo ssh $RemoteUser cd $RemoteRoot \\\; ln -s $DATE/{$BASENAME.image,$BASENAME.changes} .
ssh $RemoteUser cd $RemoteRoot \; ln -s $DATE/{$BASENAME.image,$BASENAME.changes,$BASENAME.sum} .

if [ "$BASENAME-64.changes" -nt "$BASENAME.changes" \
	-a \( "$BASENAME-64.image" -nt "$BASENAME.image" ]; then
	echo uploading $BASENAME-64 from `pwd`
	cksum $BASENAME-64.[ci]* >$BASENAME-64.sum
	echo scp -p $BASENAME-64.image $BASENAME-64.changes $BASENAME-64.sum $RemoteUser:$DIR
	scp -p $BASENAME-64.image $BASENAME-64.changes $BASENAME-64.sum $RemoteUser:$DIR
	echo ssh $RemoteUser cd $RemoteRoot \\\; ln -s $DATE/{$BASENAME-64.image,$BASENAME-64.changes} .
	ssh $RemoteUser cd $RemoteRoot \; ln -s $DATE/{$BASENAME-64.image,$BASENAME-64.changes,$BASENAME-64.sum} .
fi
ssh $RemoteUser ls -l $RemoteRoot $RemoteRoot/$DATE
