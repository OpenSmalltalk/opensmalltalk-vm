Summary:       Squeak Sources 
Name:          Squeak-sources
Version:       3
Release:       1
License:       Free with restrictions (http://www.squeak.org/download/license.html)
Group:         Development/Languages
Source0:       ftp://st.cs.uiuc.edu/Smalltalk/Squeak/3.0/platform-independent/SqueakV3.sources.gz
URL:           www.squeak.org
Distribution:  Redhat 7.2
Vendor:        The Squeak Team
Packager:      Sumit Khanna <skhanna@csc.tntech.edu>
BuildRequires: gzip
BuildArch:     noarch
Requires:      SqueakVM >= 3.0
Requires:      Squeak-image   >= 3.0.3552
BuildRoot:     /var/tmp/%name-%version-buildroot

%description
These are the source files needed for the Squeak Virtual Machiene.

%prep
mkdir -p $RPM_BUILD_ROOT
cd $RPM_BUILD_ROOT
cp $RPM_SOURCE_DIR/SqueakV3.sources.gz . 

%build
cd $RPM_BUILD_ROOT
gunzip -f SqueakV3.sources.gz

%install
cd $RPM_BUILD_ROOT
mkdir -p usr/share/squeak/3.0
mv ./SqueakV3.sources ./usr/share/squeak/3.0
ln -s /usr/share/squeak/3.0/SqueakV3.sources ./usr/share/squeak

%files
%defattr(0644,root,root,0755)
%dir /usr/share/squeak
%dir /usr/share/squeak/3.0
/usr/share/squeak/3.0/SqueakV3.sources
/usr/share/squeak/SqueakV3.sources

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Thu Jan 03 2002 Sumit Khanna <skhanna@csc.tntech.edu>
- Created Initial RPM Spec file
