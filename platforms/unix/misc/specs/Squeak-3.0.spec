Summary:       Squeak Virtual Machine
Name:          SqueakVM
Version:       3.0
Release:       1
License:       Free with restrictions (http://www.squeak.org/download/license.html)
Group:         Development/Languages
Source0:       ftp://st.cs.uiuc.edu/Smalltalk/Squeak/%version/unix-linux/src/Squeak-%version-src.tar.gz
Source1:       http://www.csc.tntech.edu/~skhanna/RPMs/Squeak/misc/Squeak-gicons.tar.gz
URL:           www.squeak.org
Distribution:  Redhat 7.2
Vendor:        The Squeak Team
Packager:      Sumit Khanna <skhanna@csc.tntech.edu>
Requires:      Squeak-sources >= 3
Requires:      Squeak-image   >= 3.0.3552
BuildRequires: gcc3
BuildRoot:     /var/tmp/%name-%version-buildroot

%description
Squeak is an open, highly-portable Smalltalk-80 implementation whose virtual machine is written entirely in Smalltalk, making it easy to debug, analyze, and change. To achieve practical performance, a translator produces an equivalent C program whose performance is comparable to commercial Smalltalks.

%prep
rm -rf $RPM_BUILD_DIR/Squeak-%version
%setup -n Squeak-%version
tar xvfz $RPM_SOURCE_DIR/Squeak-gicons.tar.gz
mkdir build;
cd build;
../src/unix/configure --prefix=/usr

%build
cd build
make CC=gcc3 RPM_OPT_FLAGS="$RPM_OPT_FLAGS"

%install
cd build
make DESTDIR=$RPM_BUILD_ROOT docdir=/tmp/Scrap mandir=/usr/share/man install
rm $RPM_BUILD_ROOT/tmp/Scrap -rf
cd ..
mkdir -p $RPM_BUILD_ROOT/usr/share/pixmaps
install -m 0644 ./squeak.xpm $RPM_BUILD_ROOT/usr/share/pixmaps
mkdir -p $RPM_BUILD_ROOT/usr/share/gnome/apps/Applications/
install -m 0644 ./squeak.desktop $RPM_BUILD_ROOT/usr/share/gnome/apps/Applications/

%files
%defattr(-,root,root)
%doc BUILD.UnixSqueak COPYING COPYRIGHT LICENSE README.CodingStandards
/usr/share/man/man1/squeak.1.gz
%dir /usr/lib/squeak
%dir /usr/lib/squeak/3.0
/usr/lib/squeak/3.0/inisqueak  
/usr/lib/squeak/3.0/Profiler.la  
/usr/lib/squeak/3.0/Profiler.so  
/usr/lib/squeak/3.0/squeak  
/usr/lib/squeak/3.0/squeak.map  
/usr/lib/squeak/3.0/System.la  
/usr/lib/squeak/3.0/System.so
/usr/bin/inisqueak
/usr/bin/squeak
/usr/share/gnome/apps/Applications/squeak.desktop
/usr/share/pixmaps/squeak.xpm

%clean
rm -rf $RPM_BUILD_DIR/Squeak-%version;
rm -rf $RPM_BUILD_ROOT -rf;

%changelog
* Thu Jan 03 2002 Sumit Khanna <skhanna@csc.tntech.edu>
- Created Initial RPM Spec file
