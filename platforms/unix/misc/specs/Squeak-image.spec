Summary: The .image and .changes files needed to run Squeak.
Name: Squeak-image
Vendor: {sqvendor}
Version: {sqversion}
Release: {sqrelease}
Copyright: Squeak Software License
Group: Development/Languages
Source: {sqftp}/Squeak-{sqversion}{sqprerel}-image.tar.gz
BuildRoot: /var/tmp/%{name}-root
BuildArchitectures: noarch

%description
The persistent state of the Squeak environment is saved in a pair of ".image"
and ".changes" files.  This package contains these files for version {sqversion} of
Squeak.

You must install this package before installing Squeak-{sqversion}.

%prep
%setup -q -n Squeak-{sqversion}

%install
rm -rf $RPM_BUILD_ROOT
./INSTALL -$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/share/squeak/{sqversion}
