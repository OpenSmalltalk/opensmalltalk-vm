Name: Squeak
Version: {sqversion}
Release: {sqrelease}
Requires: Squeak-image, Squeak-sources
Summary: A portable implementation of the Smalltalk programming system.
Vendor: {sqvendor}
Source: {sqftp}/Squeak-{sqversion}{sqprerel}.tar.gz
Copyright: Squeak Software License
Group: Development/Languages
BuildRoot: /var/tmp/%{name}-root

%description
Squeak is a full-featured implementation of the Smalltalk programming
language and environment based on (and largely compatible with) the original
Smalltalk-80 system.  Squeak has very powerful 2- and 3-D graphics, sound,
MIDI, animation and other multimedia capabilities, and one of the most
impressive development environments ever created.  It also includes a
customisable framework for creating interactively extensible Web sites.
The entire Squeak system is open source software, distributed freely with a
liberal license.  See <http://Squeak.org> for further information.

This package contains the binaries and libraries needed to run version {sqversion}
of Squeak.  You will need to install the packages Squeak-image-{sqversion}-{sqrelease}
and Squeak-sources-{sqmajor}-1 before installing this package.

%package ffi
Summary: Squeak plugins for use with libffi.
Group: Development/Languages
Requires: Squeak

%description ffi
Squeak-ffi contains shared libraries that allow the Squeak Smalltalk system
to use foreign function calls based on libffi from Cygnus Solutions.

Install this package if you want to use Squeak's FFI primitives.  You'll
need to install Squeak-{sqversion}-{sqrelease} and libffi before installing this package.

%prep
%setup -q

%build
mkdir build
cd build
../src/unix/configure --prefix=/usr
make

%install
rm -rf $RPM_BUILD_ROOT
cd build
make install DESTDIR=$RPM_BUILD_ROOT
cd ..
# 
# package file lists
# 
find $RPM_BUILD_ROOT \( -type f -o -type l \) -print |
  fgrep -v SqueakFFIPrims |
  sed "s,$RPM_BUILD_ROOT,,;s,^//,/," > sq-files
ls $RPM_BUILD_ROOT{vsqlibdir}/* |
  fgrep SqueakFFIPrims |
  sed "s,$RPM_BUILD_ROOT,,;s,^//,/," > ffi-files

%clean
rm -rf $RPM_BUILD_ROOT

%files -f sq-files
%files -f ffi-files ffi
