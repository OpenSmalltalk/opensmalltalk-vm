Summary: The .image and .changes files needed to run Squeak.
Name: Squeak-image
Vendor: Squeak.org
Version: 2.8
Release: 2
Copyright: Squeak Software License
Group: Development/Languages
Source: ftp.inria.fr/INRIA/Projects/SOR/users/piumarta/squeak/Squeak-2.8pre2-image.tar.gz
BuildRoot: /var/tmp/%{name}-root
BuildArchitectures: noarch

%description
The persistent state of the Squeak environment is saved in a pair of ".image"
and ".changes" files.  This package contains these files for version 2.8 of
Squeak.

You must install this package before installing Squeak-2.8.

%prep
%setup -q -n Squeak-2.8

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/local/lib/squeak2.8
cp * $RPM_BUILD_ROOT/usr/local/lib/squeak2.8

%clean
rm -rf $RPM_BUILD_ROOT

%files
/usr/local/lib/squeak2.8
