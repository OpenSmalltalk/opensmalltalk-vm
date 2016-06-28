set -e

travis_fold() {
  local action=$1
  local name=$2
  local title="${3:-}"

  if [[ "${TRAVIS:-}" = "true" ]]; then
    echo -en "travis_fold:${action}:${name}\r\033[0K"
  fi
  if [[ -n "${title}" ]]; then
    echo -e "\033[34;1m${title}\033[0m"
  fi
}

if [[ "${APPVEYOR}" ]]; then
    ARCH="win32x86"
    TRAVIS_BUILD_DIR="$(pwd)"
    TRAVIS_TAG="${APPVEYOR_REPO_TAG}"
    PLATFORM="Windows"

    # Appveyor's GCC is pretty new, patch the Makefiles and replace the tools to
    # make it work
    for i in gcc ar dlltool dllwrap strip objcopy nm windres; do
	OLD=$(which $i)
	NEW=$(which i686-w64-mingw32-$i)
	if [[ -z $OLD ]]; then
	    OLD=/usr/bin/$i
	    echo "No $i, setting..."
	fi
	echo "Setting $OLD as $NEW"
	rm $OLD
	ln -s $NEW $OLD
    done

    echo
    echo "Using gcc $(gcc --version)"
    echo
    test -d /usr/i686-w64-mingw32/sys-root/mingw/lib || echo "No lib dir"
    test -d /usr/i686-w64-mingw32/sys-root/mingw/include || echo "No inc dir"

    for i in build.win32x86/common/Makefile build.win32x86/common/Makefile.plugin; do
	sed -i 's#-L/usr/lib/mingw#-L/usr/i686-w64-mingw32/sys-root/mingw/lib#g' $i
	sed -i 's#INCLUDEPATH:=.*#INCLUDEPATH:= -I/usr/i686-w64-mingw32/sys-root/mingw/include#g' $i
	# sed -i 's/-fno-builtin-fprintf/-fno-builtin-fprintf -fno-builtin-bzero/g' $i
	sed -i 's/-lcrtdll/-lmsvcrt -lws2_32/g' $i
	sed -i 's/-mno-accumulate-outgoing-args/-maccumulate-outgoing-args -mstack-arg-probe/g' $i
	sed -i 's/-mno-cygwin//g' $i
	sed -i 's/#EXPORT:=--export-all-symbols/EXPORT:=--export-all-symbols/g' $i
	sed -i 's/EXPORT:=--export-dynamic/#EXPORT:=--export-dynamic/g' $i
    done

    sed -i 's/__BLOB_T_DEFINED/_BLOB_DEFINED/g' platforms/win32/plugins/SocketPlugin/winsock2.h

    sed -i 's/|| defined(WIN32)//g' platforms/Cross/plugins/Mpeg3Plugin/libmpeg/changesForSqueak.c
else
    PLATFORM="$(uname -s)"
fi

[[ -z "${ARCH}" ]] && exit 2
[[ -z "${FLAVOR}" ]] && exit 3

if [[ "${ARCH}" == "linux32ARM"* ]]; then
    # we're in  chroot at this point
    TRAVIS_BUILD_DIR="$(pwd)"
fi

echo "`cat platforms/Cross/vm/sqSCCSVersion.h | .git_filters/RevDateURL.smudge`" > platforms/Cross/vm/sqSCCSVersion.h
echo "`cat platforms/Cross/plugins/sqPluginsSCCSVersion.h | .git_filters/RevDateURL.smudge`" > platforms/Cross/plugins/sqPluginsSCCSVersion.h

REV=$(grep -m1 "SvnRawRevisionString" platforms/Cross/vm/sqSCCSVersion.h | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')

echo $PATH

output_file="${TRAVIS_BUILD_DIR}/cog_${ARCH}_${FLAVOR}_${REV}"

export COGVREV="$(git describe --tags --always)"
export COGVDATE="$(git show -s --format=%cd HEAD)"
export COGVURL="$(git config --get remote.origin.url)"
export COGVOPTS="-DCOGVREV=\"${COGVREV}\" -DCOGVDATE=\"${COGVDATE// /_}\" -DCOGVURL=\"${COGVURL//\//\\\/}\""

case "$PLATFORM" in
  "Linux")
    build_directory="./build.${ARCH}/${FLAVOR}/build"

    [[ ! -d "${build_directory}" ]] && exit 10

    pushd "${build_directory}"

    travis_fold start build_vm "Building OpenSmalltalk VM..."
    echo n | ./mvm
    travis_fold end build_vm

    # cat config.log
    popd

    output_file="${output_file}.tar.gz"
    tar czf "${output_file}" "./products"
    ;;
  "Darwin")
    build_directory="./build.${ARCH}/${FLAVOR}"

    [[ ! -d "${build_directory}" ]] && exit 50

    pushd "${build_directory}"

    travis_fold start build_vm "Building OpenSmalltalk VM..."
    ./mvm -f
    travis_fold end build_vm

    output_file="${output_file}.tar.gz"
    tar czf "${output_file}" ./Cocoa*.app
    popd
    ;;
  "Windows")
    build_directory="./build.${ARCH}/${FLAVOR}/"

    [[ ! -d "${build_directory}" ]] && exit 100

    pushd "${build_directory}"
    # remove bochs plugins
    sed -i 's/Bochs.* //g' plugins.ext
    ./mvm -f
    output_file="${output_file}.zip"
    zip -r "${output_file}" "./builddbg/vm/" "./buildast/vm/" "./build/vm/"
    popd
    ;;
  *)
    echo "Unsupported platform '${os_name}'." 1>&2
    exit 99
    ;;
esac
