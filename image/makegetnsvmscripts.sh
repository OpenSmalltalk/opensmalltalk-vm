#!/bin/sh
# Create the getGoodCogNsvm.sh & getGoodSpurNsvm.sh scripts.
GetCogScript=getGoodCogNsvm.sh
GetSpurScript=getGoodSpurNsvm.sh

cd `dirname $0`

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

test -n "$REV" || REV=`grep 'SvnRawRevisionString.*Rev:' ../platforms/Cross/vm/sqSCCSVersion.h \
	| sed 's/^.*Rev: \([0-9][0-9]*\) $";/\1/'`
test -n "$TAG" || TAG=`date +%g.%U.`$REV

LCBINDIR=4.0-$REV
LSBINDIR=5.0-$REV
echo REV=$REV TAG=$TAG

. ./envvars.sh

ABORT=
for a in "Newspeak Virtual Machine.app-$TAG.tgz" "Newspeak Virtual Machine-$TAG.dmg" nsvmlinuxht-$TAG.tgz nsvmlinux-$TAG.tgz nsvmwin-$TAG.zip\
		"Newspeak Spur Virtual Machine.app-$TAG.tgz" "Newspeak Spur Virtual Machine-$TAG.dmg" nsvmspurlinuxht-$TAG.tgz nsvmspurwin-$TAG.zip
do
	test -f "../products/$a" || echo $a does not exist
	ABORT=true
done
test -n "$ABORT" || exit 1


echo $GetCogScript $GetSpurScript

cat >$GetCogScript <<END
#!/bin/sh
# Sets the VM env var to the r$REV Newspeak VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
LCBINDIR=4.0-$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            "Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine" ' >>$GetCogScript
echo -n `quietmd5 "../products/Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine"` >>$GetCogScript
echo ' \' >> $GetCogScript
echo -n '            "Newspeak Virtual Machine.app-$TAG.tgz" ' >>$GetCogScript
quietmd5 "../products/Newspeak Virtual Machine.app-$TAG.tgz" >>$GetCogScript

cat >>$GetCogScript <<END
        VM="Newspeak Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux)
    if expr \$OSREL \\> 2.6.12; then
        get_vm_from_tar \\
END

echo -n '        nsvmlinuxht/lib/nsvm/$LCBINDIR/nsvm ' >>$GetCogScript
echo -n `quietmd5 ../products/nsvmlinuxht/lib/nsvm/$LCBINDIR/nsvm` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '        nsvmlinuxht-$TAG.tgz ' >>$GetCogScript
quietmd5 ../products/nsvmlinuxht-$TAG.tgz >>$GetCogScript

cat >>$GetCogScript <<END
    else
        get_vm_from_tar \\
END

echo -n '        nsvmlinux/lib/nsvm/$LCBINDIR/nsvm ' >>$GetCogScript
echo -n `quietmd5 ../products/nsvmlinux/lib/nsvm/$LCBINDIR/nsvm` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '        nsvmlinux-$TAG.tgz ' >>$GetCogScript
quietmd5 ../products/nsvmlinux-$TAG.tgz >>$GetCogScript
cat >>$GetCogScript <<END
    fi;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            nsvmwin/nsvmConsole.exe ' >>$GetCogScript
echo -n `quietmd5 ../products/nsvmwin/nsvmConsole.exe` >>$GetCogScript
echo ' \' >>$GetCogScript
echo -n '            nsvmwin-$TAG.zip ' >>$GetCogScript
quietmd5 ../products/nsvmwin-$TAG.zip >>$GetCogScript

cat >>$GetCogScript <<END
    VM=nsvmwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
END

chmod a+x $GetCogScript

cat >$GetSpurScript <<END
#!/bin/sh
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
echo -n `quietmd5 ../products/"Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine"` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            "Newspeak Spur Virtual Machine.app-$TAG.tgz" ' >>$GetSpurScript
quietmd5 "../products/Newspeak Spur Virtual Machine.app-$TAG.tgz" >>$GetSpurScript

cat >>$GetSpurScript <<END
        VM="Newspeak Spur Virtual Machine.app/Contents/MacOS/Newspeak Virtual Machine";;
Linux) get_vm_from_tar \\
END

echo -n '        nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm ' >>$GetSpurScript
echo -n `quietmd5 ../products/nsvmspurlinuxht/lib/nsvm/$LSBINDIR/nsvm` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '        nsvmspurlinuxht-$TAG.tgz ' >>$GetSpurScript
quietmd5 ../products/nsvmspurlinuxht-$TAG.tgz >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=nsvmspurlinuxht/nsvm;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            nsvmspurwin/nsvmConsole.exe ' >>$GetSpurScript
echo -n `quietmd5 ../products/nsvmspurwin/nsvmConsole.exe` >>$GetSpurScript
echo ' \' >>$GetSpurScript
echo -n '            nsvmspurwin-$TAG.zip ' >>$GetSpurScript
quietmd5 ../products/nsvmspurwin-$TAG.zip >>$GetSpurScript

cat >>$GetSpurScript <<END
    VM=nsvmspurwin/nsvmConsole.exe;;
*)  echo "don't know how to run nsvm on your system.  bailing out." 1>&2; exit 2
esac
END

chmod a+x $GetSpurScript
