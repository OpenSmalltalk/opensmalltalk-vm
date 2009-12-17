#!/bin/sh
# 
# Launch squeak from a menu, prompting for and/or installing an image
# 
# Last edited: 2009-12-17 10:21:38 by piumarta on ubuntu

PATH=/usr/bin:/bin

me=`basename $0`
bindir=`dirname $0`
bindir=`cd ${bindir}; pwd`
prefix=`dirname ${bindir}`
libdir="${prefix}/lib/squeak"
vm="squeak"

# find a way to display dialogues

if test -n "$DISPLAY" -a -x "`which kdialog 2>/dev/null`"; then
    error ()		{ kdialog --error "${me}: $*"; exit 1; }
    confirm ()		{ if kdialog --yesno "${1} ${2}?"; then result="${2}"; else result=""; fi; }
    chooseItem ()	{ title="$1"; shift; result=`kdialog --combobox "${title}" $*`; }
    findFile ()		{ result=`kdialog --title "$1" --getopenfilename . '*.image'`; }
    findDirectory ()	{ result=`kdialog --title "$1" --getexistingdirectory .`; }
elif [ -n "$DISPLAY" -a -x "`which zenity 2>/dev/null`" ]; then
    error ()		{ zenity --error --text "${me}: $*"; exit 1; }
    confirm ()		{ if zenity --question --text="${1} ${2}?"; then result="${2}"; else result=""; fi; }
    chooseItem ()	{ title="$1"; shift; result=`zenity --title "${title}" --list --column Images $*`; }
    findFile ()		{ result=`zenity --title "$1" --file-selection --file-filter='*.image'`; }
    findDirectory ()	{ result=`zenity --title "$1" --file-selection --directory`; }
else
    error ()		{ echo "${me}: $*" >&2; exit 1; }
    confirm ()		{ error "this cannot happen"; }
    chooseItem ()	{ error "this cannot happen"; }
    findFile ()		{ error "no image name specified"; }
    findDirectory ()	{ error "this cannot happen"; }
fi

# succeed if there are two or more arguments

plural () { test -n "$2"; }

# find the VM

if test -x "${bindir}/${vm}"; then
    vm="${bindir}/${vm}"
elif test -x "`which ${vm} 2>/dev/null`"; then
    vm="`which ${vm} 2>/dev/null`"
else
    error "Cannot find ${vm}"
fi

# if we have arguments then assume an image name was given or we came
# from a command line

if test $# -gt 0; then
    exec "${vm}" "$@"
fi

findFile "Choose a saved image to resume or cancel to install a new one"

if test -z "${result}"; then
    images=""
    if test -d "${libdir}"; then
	images=`cd "${libdir}"; ls *.image 2>/dev/null`
    fi
    if test -z "${images}"; then
	error "no image name specified and no images found in ${libdir}"
	exit 1
    fi
    if plural ${images}; then
	chooseItem "Choose an image to install" ${images}
    else
	confirm "Install image" ${images}
    fi
    if test -z "${result}"; then
	exit 0
    fi
    image=${result}
    changes=`basename ${image} .image`.changes
    findDirectory "Choose a destination directory for the image"
    if test -z "${result}"; then
	exit 0
    fi
    if test -e "${result}/${image}"; then
	confirm "Overwrite existing ${image} in" "${result}"
	if test -z "${result}"; then
	    exit 0;
	fi
    fi
    cp -p "${libdir}/${image}"   "${result}/."
    cp -p "${libdir}/${changes}" "${result}/."
    ln -s "${libdir}"/*.sources  "${result}/."
    image="${result}/${image}"
else
    image="${result}"
fi

cd "`dirname ${image}`"
exec "${vm}" "`basename ${image}`"
