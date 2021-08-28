Name:		pharo7-ui-common
Version:	1
Release:	1%{?dist}
Summary:	Pharo7 VM

Group:		VM
License:	MIT
URL:		http://www.pharo.org
Source0:	DEB_VERSION

#BuildRequires:	libmpeg3-devel
BuildRequires:	pharo6-sources-files
BuildRequires:	SDL-devel
BuildRequires:  openssl-devel
%if 0%{?suse_version}
BuildRequires:	libpulse-devel
BuildRequires:	freetype2-devel
BuildRequires:  -post-build-checks
%else
BuildRequires:	pulseaudio-libs-devel
BuildRequires:	freetype-devel
%endif
BuildRequires:	libICE-devel
BuildRequires:	libSM-devel
BuildRequires:	alsa-lib-devel
Requires:	pharo6-sources-files
Requires:	bash

%global _configure ../../../platforms/unix/config/configure
%global vm_cppflags -DNDEBUG -DDEBUGVM=0 -D_GNU_SOURCE -DCOGMTVM=0 -DPharoVM -DIMMUTABILITY=1 -DITIMER_HEARTBEAT=1

%ifarch x86_64
%global vmsources src/spur64.cog
%global vm_cflags -msse2
%global vm_extra_cppflags %{nil}
%endif
%ifarch %{ix86}
%global vmsources src/spur32.cog
%global vm_cflags -msse2
%global vm_extra_cppflags -D_FILE_OFFSET_BITS=64
%endif

%description
Pharo7 VM common files shared between the 32bit and 64bit flavor.
It will be installed automatically.

%ifarch x86_64
%package -n pharo7-64
Summary: Pharo7 VM for 64bit
%description -n pharo7-64
Description: Clean and innovative Smalltalk-inspired environment.
Pharo's goal is to deliver a clean, innovative, free open-source
Smalltalk-inspired environment. By providing a stable and small core
system, excellent dev tools, and maintained releases, Pharo is an
attractive platform to build and deploy mission critical applications.

%package -n pharo7-64-ui
Summary: Pharo7 VM for 64bit with UI
Requires: pharo7-64 pharo7-ui-common
%description -n pharo7-64-ui
Description: Clean and innovative Smalltalk-inspired environment.
Pharo's goal is to deliver a clean, innovative, free open-source
Smalltalk-inspired environment. By providing a stable and small core
system, excellent dev tools, and maintained releases, Pharo is an
attractive platform to build and deploy mission critical applications.

Installs the 64bit pharo7 VM with GUI support.

%endif
%ifarch %{ix86}
%package -n pharo7-32
Summary: Pharo7 VM for 32bit
%description -n pharo7-32
Description: Clean and innovative Smalltalk-inspired environment.
Pharo's goal is to deliver a clean, innovative, free open-source
Smalltalk-inspired environment. By providing a stable and small core
system, excellent dev tools, and maintained releases, Pharo is an
attractive platform to build and deploy mission critical applications.

%package -n pharo7-32-ui
Summary: Pharo7 VM for 32bit with UI
Requires: pharo7-32 pharo7-ui-common
%description -n pharo7-32-ui
Description: Clean and innovative Smalltalk-inspired environment.
Pharo's goal is to deliver a clean, innovative, free open-source
Smalltalk-inspired environment. By providing a stable and small core
system, excellent dev tools, and maintained releases, Pharo is an
attractive platform to build and deploy mission critical applications.

Installs the 32bit pharo7 VM with GUI support.
%endif

%prep
%setup -q -n pharo7-vm-core


%build
export CPPFLAGS="%vm_cppflags %vm_extra_cppflags"
export CFLAGS="%{optflags} %vm_cflags"
mkdir -p build/debian/build
cp building/linux32x86/pharo.cog.spur/plugins.* build/debian/build/
cd build/debian/build
echo "foo %{_builddir}"
%configure \
		--without-npsqueak \
		--with-vmversion=5.0 \
		--with-src=%vmsources
make %{?_smp_mflags}


%install
make -C build/debian/build install-squeak install-plugins ROOT=%{?buildroot}
rm %{?buildroot}/usr/squeak
rm %{?buildroot}/usr/bin/squeak

install -d %{?buildroot}/%{_mandir}/man1
install -m 0644 debian/*.1 %{?buildroot}/%{_mandir}/man1/

install -d %{?buildroot}/%{_datadir}/
cp -a debian/pharo7-vm-core-resources/usr %{?buildroot}/

# need to do renaming of the binaries
%ifarch x86_64
install -d %{?buildroot}/usr/lib64/pharo7-vm/
rm %{?buildroot}/usr/bin/pharo7-32*
rm %{?buildroot}%{_datadir}/applications/pharo7-32-ui.desktop
rm %{?buildroot}%{_datadir}/man/man1/pharo7-32.1
mv %{?buildroot}/usr/lib64/squeak/*/* %{?buildroot}/usr/lib64/pharo7-vm/
rm %{?buildroot}/usr/lib64/pharo7-vm/*.a
mv %{?buildroot}/usr/lib64/pharo7-vm/squeak %{?buildroot}/usr/lib64/pharo7-vm/pharo
ln -s /usr/share/pharo6-vm/PharoV60.sources %{?buildroot}/usr/lib64/pharo7-vm/
sed -i s,lib/x86_64-linux-gnu,lib64, %{?buildroot}/usr/bin/*
%endif


%ifarch %{ix86}
install -d %{?buildroot}/usr/lib/pharo7-vm/
rm %{?buildroot}/usr/bin/pharo7-64*
rm %{?buildroot}%{_datadir}/applications/pharo7-64-ui.desktop
rm %{?buildroot}%{_datadir}/man/man1/pharo7-64.1
mv %{?buildroot}/usr/lib/squeak/*/* %{?buildroot}/usr/lib/pharo7-vm/ 
rm %{?buildroot}/usr/lib/pharo7-vm/*.a
mv %{?buildroot}/usr/lib/pharo7-vm/squeak %{?buildroot}/usr/lib/pharo7-vm/pharo
ln -s /usr/share/pharo6-vm/PharoV60.sources %{?buildroot}/usr/lib/pharo7-vm/
sed -i s,lib/i386-linux-gnu,lib, %{?buildroot}/usr/bin/*
%endif


%files
%doc
%{_datadir}/icons
%{_datadir}/mime

%ifarch x86_64
%files -n pharo7-64
%dir %{_libdir}/pharo7-vm
%{_bindir}/pharo7-64
%{_libdir}/pharo7-vm/pharo
%{_libdir}/pharo7-vm/AioPlugin.so
%{_libdir}/pharo7-vm/EventsHandlerPlugin.so
%{_libdir}/pharo7-vm/FileAttributesPlugin.so
%{_libdir}/pharo7-vm/FT2Plugin.so
%{_libdir}/pharo7-vm/InternetConfigPlugin.so
%{_libdir}/pharo7-vm/JPEGReadWriter2Plugin.so
%{_libdir}/pharo7-vm/JPEGReaderPlugin.so
%{_libdir}/pharo7-vm/PharoV60.sources
%{_libdir}/pharo7-vm/RePlugin.so
%{_libdir}/pharo7-vm/SqueakSSL.so
%{_libdir}/pharo7-vm/SurfacePlugin.so
%{_libdir}/pharo7-vm/vm-display-null.so
%{_libdir}/pharo7-vm/vm-sound-null.so
%{_mandir}/man1/pharo7-64.1.gz

%files -n pharo7-64-ui
%dir %{_libdir}/pharo7-vm
%{_bindir}/pharo7-64-ui
%{_libdir}/pharo7-vm/B3DAcceleratorPlugin.so
%{_libdir}/pharo7-vm/vm-display-X11.so
%{_libdir}/pharo7-vm/vm-display-fbdev.so
%{_libdir}/pharo7-vm/vm-sound-ALSA.so
%{_libdir}/pharo7-vm/vm-sound-OSS.so
%{_libdir}/pharo7-vm/vm-sound-pulse.so
%{_datadir}/applications/pharo7-64-ui.desktop
%endif

%ifarch %{ix86}
%files -n pharo7-32
%dir %{_libdir}/pharo7-vm
%{_bindir}/pharo7-32
%{_libdir}/pharo7-vm/pharo
%{_libdir}/pharo7-vm/AioPlugin.so
%{_libdir}/pharo7-vm/EventsHandlerPlugin.so
%{_libdir}/pharo7-vm/FileAttributesPlugin.so
%{_libdir}/pharo7-vm/FT2Plugin.so
%{_libdir}/pharo7-vm/InternetConfigPlugin.so
%{_libdir}/pharo7-vm/JPEGReadWriter2Plugin.so
%{_libdir}/pharo7-vm/JPEGReaderPlugin.so
%{_libdir}/pharo7-vm/PharoV60.sources
%{_libdir}/pharo7-vm/RePlugin.so
%{_libdir}/pharo7-vm/SqueakSSL.so
%{_libdir}/pharo7-vm/SurfacePlugin.so
%{_libdir}/pharo7-vm/vm-display-null.so
%{_libdir}/pharo7-vm/vm-sound-null.so
%{_mandir}/man1/pharo7-32.1.gz

%files -n pharo7-32-ui
%dir %{_libdir}/pharo7-vm
%{_bindir}/pharo7-32-ui
%{_libdir}/pharo7-vm/B3DAcceleratorPlugin.so
%{_libdir}/pharo7-vm/vm-display-X11.so
%{_libdir}/pharo7-vm/vm-display-fbdev.so
%{_libdir}/pharo7-vm/vm-sound-ALSA.so
%{_libdir}/pharo7-vm/vm-sound-OSS.so
%{_libdir}/pharo7-vm/vm-sound-pulse.so
%{_datadir}/applications/pharo7-32-ui.desktop
%endif

%changelog
