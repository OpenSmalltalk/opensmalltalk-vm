Name: Squeak
Version: 2.8
Release: 2
Requires: Squeak-image
Requires: Squeak-sources
Summary: A portable implementation of the Smalltalk programming system.
Vendor: Squeak.org
Source: ftp.inria.fr/INRIA/Projects/SOR/users/piumarta/squeak/Squeak-2.8pre2.tar.gz
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
liberal license.

See <http://Squeak.org> for further information.

%prep
%setup -q

%build
mkdir build
cd build
../src/unix/configure
make

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local
cd build
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%doc BUILD.UnixSqueak COPYING COPYRIGHT LICENSE README.CodingStandards
/usr/local/bin/inisqueak
/usr/local/bin/inisqueak%{version}
/usr/local/bin/squeak
/usr/local/bin/squeak%{version}
/usr/local/lib/squeak%{version}/*.so
/usr/local/lib/squeak%{version}/*.la
/usr/local/lib/squeak%{version}/squeak%{version}.map
