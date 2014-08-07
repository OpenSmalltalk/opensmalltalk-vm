#!/bin/sh
# Create the getGoodCogVM.sh & getGoodSpurVM.sh scripts.

cd `dirname $0`
REV=`grep 'SvnRawRevisionString.*Rev:' ../platforms/Cross/vm/sqSCCSVersion.h \
	| sed 's/^.*Rev: \([0-9][0-9]*\) $";/\1/'`

if [ "$1" = "-r" -a -n "$2" ]; then
	REV="$2"
	shift;shift
fi

TAG=`date +%g.%U.`$REV
echo REV=$REV TAG=$TAG

. ./envvars.sh

ABORT=
for a in Cog.app-$TAG.tgz coglinuxht-$TAG.tgz coglinux-$TAG.tgz cogwin-$TAG.zip\
		CogSpur.app-$TAG.tgz cogspurlinuxht-$TAG.tgz cogspurwin-$TAG.zip
do
	test -f ../products/$a || echo $a does not exist
	ABORT=true
done
test -n "$ABORT" || exit 1

cat >getGoodCogVM.sh <<END
#!/bin/sh
# Sets the VM env var to the r$REV Cog VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

if wget --help >/dev/null ; then
    true
else
    echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
     exit 1
fi

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            Cog.app/Contents/MacOS/Squeak ' >>getGoodCogVM.sh
echo -n `quietmd5 ../products/Cog.app/Contents/MacOS/Squeak` >>getGoodCogVM.sh
echo ' \' >>getGoodCogVM.sh
echo -n '            Cog.app-$TAG.tgz ' >>getGoodCogVM.sh
quietmd5 ../products/Cog.app-$TAG.tgz >>getGoodCogVM.sh

cat >>getGoodCogVM.sh <<END
        VM=Cog.app/Contents/MacOS/Squeak;;
Linux)
    if expr \$OSREL \\> 2.6.12; then
        get_vm_from_tar \\
END

echo -n '        coglinuxht/lib/squeak/4.0-$REV/squeak ' >>getGoodCogVM.sh
echo -n `quietmd5 ../products/coglinuxht/lib/squeak/4.0-$REV/squeak` >>getGoodCogVM.sh
echo ' \' >>getGoodCogVM.sh
echo -n '        coglinuxht-$TAG.tgz ' >>getGoodCogVM.sh
quietmd5 ../products/coglinuxht-$TAG.tgz >>getGoodCogVM.sh

cat >>getGoodCogVM.sh <<END
    else
        get_vm_from_tar \\
END

echo -n '        coglinux/lib/squeak/4.0-$REV/squeak ' >>getGoodCogVM.sh
echo -n `quietmd5 ../products/coglinux/lib/squeak/4.0-$REV/squeak` >>getGoodCogVM.sh
echo ' \' >>getGoodCogVM.sh
echo -n '        coglinux-$TAG.tgz ' >>getGoodCogVM.sh
quietmd5 ../products/coglinux-$TAG.tgz >>getGoodCogVM.sh
cat >>getGoodCogVM.sh <<END
    fi;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            cogwin/SqueakConsole.exe ' >>getGoodCogVM.sh
echo -n `quietmd5 ../products/cogwin/SqueakConsole.exe` >>getGoodCogVM.sh
echo ' \' >>getGoodCogVM.sh
echo -n '            cogwin-$TAG.zip ' >>getGoodCogVM.sh
quietmd5 ../products/cogwin-$TAG.zip >>getGoodCogVM.sh

cat >>getGoodCogVM.sh <<END
    VM=cogwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
END

chmod a+x getGoodCogVM.sh

cat >getGoodSpurVM.sh <<END
#!/bin/sh
# Sets the VM env var to the r$REV Cog Spur VM for the current platform.
# will download and install the VM in this directory if necessary.

TAG=$TAG
REV=$REV
URL=http://www.mirandabanda.org/files/Cog/VM/VM.r\$REV/

. ./envvars.sh

if wget --help >/dev/null ; then
    true
else
    echo 'could not find wget.  you can find instructions on how to install it on google.' 1>&2
     exit 1
fi

case "\$OS" in
Darwin) get_vm_from_tar \\
END

echo -n '            CogSpur.app/Contents/MacOS/Squeak ' >>getGoodSpurVM.sh
echo -n `quietmd5 ../products/CogSpur.app/Contents/MacOS/Squeak` >>getGoodSpurVM.sh
echo ' \' >>getGoodSpurVM.sh
echo -n '            CogSpur.app-$TAG.tgz ' >>getGoodSpurVM.sh
quietmd5 ../products/CogSpur.app-$TAG.tgz >>getGoodSpurVM.sh

cat >>getGoodSpurVM.sh <<END
        VM=CogSpur.app/Contents/MacOS/Squeak;;
Linux) get_vm_from_tar \\
END

echo -n '        cogspurlinuxht/lib/squeak/4.0-$REV/squeak ' >>getGoodSpurVM.sh
echo -n `quietmd5 ../products/cogspurlinuxht/lib/squeak/4.0-$REV/squeak` >>getGoodSpurVM.sh
echo ' \' >>getGoodSpurVM.sh
echo -n '        cogspurlinuxht-$TAG.tgz ' >>getGoodSpurVM.sh
quietmd5 ../products/cogspurlinuxht-$TAG.tgz >>getGoodSpurVM.sh

cat >>getGoodSpurVM.sh <<END
    VM=cogspurlinuxht/squeak;;
CYGWIN*) get_vm_from_zip \\
END

echo -n '            cogspurwin/SqueakConsole.exe ' >>getGoodSpurVM.sh
echo -n `quietmd5 ../products/cogspurwin/SqueakConsole.exe` >>getGoodSpurVM.sh
echo ' \' >>getGoodSpurVM.sh
echo -n '            cogspurwin-$TAG.zip ' >>getGoodSpurVM.sh
quietmd5 ../products/cogspurwin-$TAG.zip >>getGoodSpurVM.sh

cat >>getGoodSpurVM.sh <<END
    VM=cogspurwin/SqueakConsole.exe;;
*)  echo "don't know how to run Squeak on your system.  bailing out." 1>&2; exit 2
esac
END

chmod a+x getGoodSpurVM.sh
