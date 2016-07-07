#!/bin/bash -e
# Create the getGoodSpurNsvm.sh script.
GetSpurScript=getGoodSpurNsvm.sh

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
for a in "Newspeak Spur Virtual Machine.app-$TAG.tgz" nsvmspurlinuxht-$TAG.tgz nsvmspurwin-$TAG.zip
do
	test -f "../products/$a" || echo $a does not exist
	test -f "../products/$a" && (cd "$SD" >/dev/null;
		case "$a" in
		*.zip)	unzip -q "../../products/$a";;
		*)	tar xzf "../../products/$a"
		esac)
	ABORT=true
done
test -n "$ABORT" || rm -rf "$SD"
test -n "$ABORT" || exit 1


echo $GetSpurScript

cat >$GetSpurScript <<END
#!/bin/sh -e
# Sets the VM env var to the r$REV Newspeak Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
LSBINDIR=5.0-$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            "Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" ' >>$GetSpurScript
echo -n `quietmd5 "$SD/Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine"` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            "Newspeak Spur Virtual Machine.app-$TAG.tgz" ' >>$GetSpurScript
quietmd5 "../products/Newspeak Spur Virtual Machine.app-$TAG.tgz" >>$GetSpurScript

cat >>$GetSpurScript <<END
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \\
END

echo -n '        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm ' >>$GetSpurScript
echo -n `quietmd5 $SD/nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '        nsvmspurlinuxht-$TAG.tgz ' >>$GetSpurScript
quietmd5 ../products/nsvmspurlinuxht-$TAG.tgz >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            nsvmspurwin/nsvmConsole.exe ' >>$GetSpurScript
echo -n `quietmd5 $SD/nsvmspurwin/nsvmConsole.exe` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            nsvmspurwin-$TAG.zip ' >>$GetSpurScript
quietmd5 ../products/nsvmspurwin-$TAG.zip >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
END

rm -rf "$SD"
chmod a+x $GetSpurScript
