Summary:       Squeak Image 
Name:          Squeak-image
Version:       3.0.3552
Release:       1
License:       Free with restrictions (http://www.squeak.org/download/license.html)
Group:         Development/Languages
Source0:       ftp://st.cs.uiuc.edu/Smalltalk/Squeak/3.0/platform-independent/Squeak3.0-3552.zip
URL:           www.squeak.org
Distribution:  Redhat 7.2
Vendor:        The Squeak Team
Packager:      Sumit Khanna <skhanna@csc.tntech.edu>
BuildRequires: unzip
BuildArch:     noarch
Requires:      SqueakVM >= 3.0
Requires:      Squeak-sources   >= 3
BuildRoot:     /var/tmp/%name-%version-buildroot

%description
These are the image and change files needed for the Squeak Virtual Machiene.

%prep
mkdir -p $RPM_BUILD_ROOT
cd $RPM_BUILD_ROOT
cp $RPM_SOURCE_DIR/Squeak3.0-3552.zip . -f

%build
cd $RPM_BUILD_ROOT
unzip Squeak3.0-3552.zip 

%install
cd $RPM_BUILD_ROOT
mkdir -p usr/share/squeak/3.0
mv ./Squeak3.0.changes ./usr/share/squeak/3.0 
mv ./Squeak3.0.image   ./usr/share/squeak/3.0

%files
%defattr(0644,root,root,0755)
%dir /usr/share/squeak
%dir /usr/share/squeak/3.0
/usr/share/squeak/3.0/Squeak3.0.image
/usr/share/squeak/3.0/Squeak3.0.changes

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Thu Jan 03 2002 Sumit Khanna <skhanna@csc.tntech.edu>
- Created Initial RPM Spec file
