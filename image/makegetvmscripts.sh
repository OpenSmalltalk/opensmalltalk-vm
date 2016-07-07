#!/bin/bash -e
# Create the getGoodCogVM.sh & getGoodSpurVM.sh scripts.
GetCogScript=getGoodCogVM.sh
GetSpurScript=getGoodSpurVM.sh

REV=
TAG=
while getopts 'r:t:?' opt "$@"; do
	case "$opt" in
	r)	REV="$OPTARG";;
	t)	TAG="$OPTARG";;
	h|\?|*)	echo usage: $0 [-r SVNREV] [-t YR.WK.SVNREV]
			exit 0;;
	esac
done
shift `expr $OPTIND - 1`

cd `dirname $0` >/dev/null
SD=`basename $0 .sh`.$$
trap 'rm -rf "$SD"; exit 2' HUP INT PIPE TERM 0
mkdir $SD

test -n "$REV" || REV=`grep 'SvnRawRevisionString.*Rev:' ../platforms/Cross/vm/sqSCCSVersion.h \
	| sed 's/^.*Rev: \([0-9][0-9]*\) $";/\1/'`
test -n "$TAG" || TAG=`date +%g.%U.`$REV

LCBINDIR=4.0-$REV
LSBINDIR=5.0-$REV
echo REV=$REV TAG=$TAG

. ./envvars.sh

ABORT=
for a in Cog.app-$TAG.tgz coglinuxht-$TAG.tgz coglinux-$TAG.tgz cogwin-$TAG.zip\
		CogSpur.app-$TAG.tgz cogspurlinuxht-$TAG.tgz cogspurwin-$TAG.zip
do
	test -f ../products/$a || echo $a does not exist
	test -f ../products/$a && (cd "$SD" >/dev/null; tar xzf ../../products/$a)
	ABORT=true
done
test -n "$ABORT" || rm -rf "$SD"
test -n "$ABORT" || exit 1


echo $GetCogScript $GetSpurScript

cat >$GetCogScript <<END
#!/bin/sh -e
# Sets the VM env var to the r$REV Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
LCBINDIR=4.0-$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            Cog.app/Contents/MacOS/Squeak ' >>$GetCogScript
echo -n `quietmd5 "$SD/Cog.app/Contents/MacOS/Squeak"` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '            Cog.app-$TAG.tgz ' >>$GetCogScript
quietmd5 ../products/Cog.app-$TAG.tgz >>$GetCogScript

cat >>$GetCogScript <<END
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr \$OSREL \\> 2.6.12; then
        get_vm_from_tar \\
END

echo -n '        coglinuxht/lib/squeak/$LCBINDIR/squeak ' >>$GetCogScript
echo -n `quietmd5 $SD/coglinuxht/lib/squeak/$LCBINDIR/squeak` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '        coglinuxht-$TAG.tgz ' >>$GetCogScript
quietmd5 ../products/coglinuxht-$TAG.tgz >>$GetCogScript

cat >>$GetCogScript <<END
    else
        get_vm_from_tar \\
END

echo -n '        coglinux/lib/squeak/$LCBINDIR/squeak ' >>$GetCogScript
echo -n `quietmd5 $SD/coglinux/lib/squeak/$LCBINDIR/squeak` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '        coglinux-$TAG.tgz ' >>$GetCogScript
quietmd5 ../products/coglinux-$TAG.tgz >>$GetCogScript
cat >>$GetCogScript <<END
    fi;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            cogwin/SqueakConsole.exe ' >>$GetCogScript
echo -n `quietmd5 $SD/cogwin/SqueakConsole.exe` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '            cogwin-$TAG.zip ' >>$GetCogScript
quietmd5 ../products/cogwin-$TAG.zip >>$GetCogScript

cat >>$GetCogScript <<END
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
END

chmod a+x $GetCogScript

cat >$GetSpurScript <<END
#!/bin/sh -e
# Sets the VM env var to the r$REV Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
LSBINDIR=5.0-$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            CogSpur.app/Contents/MacOS/Squeak ' >>$GetSpurScript
echo -n `quietmd5 $SD/CogSpur.app/Contents/MacOS/Squeak` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            CogSpur.app-$TAG.tgz ' >>$GetSpurScript
quietmd5 ../products/CogSpur.app-$TAG.tgz >>$GetSpurScript

cat >>$GetSpurScript <<END
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \\
END

echo -n '        cogspurlinuxht/lib/squeak/$LSBINDIR/squeak ' >>$GetSpurScript
echo -n `quietmd5 $SD/cogspurlinuxht/lib/squeak/$LSBINDIR/squeak` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '        cogspurlinuxht-$TAG.tgz ' >>$GetSpurScript
quietmd5 ../products/cogspurlinuxht-$TAG.tgz >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            cogspurwin/SqueakConsole.exe ' >>$GetSpurScript
echo -n `quietmd5 $SD/cogspurwin/SqueakConsole.exe` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            cogspurwin-$TAG.zip ' >>$GetSpurScript
quietmd5 ../products/cogspurwin-$TAG.zip >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
END

rm -rf "$SD"
chmod a+x $GetSpurScript
