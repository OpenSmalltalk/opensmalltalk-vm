Summary: The system sources file needed to run Squeak.
Name: Squeak-sources
Version: {sqmajor}
Release: {sqrelease}
Vendor: {sqvendor}
Copyright: Squeak Software License
Group: Development/Languages
Source: {sqftp}
BuildRoot: /var/tmp/%{name}-root
BuildArchitectures: noarch

%description
The sources for the "system" methods in the Squeak image are "frozen" in a
system ".sources" file.  This package contains that file, for use with any
Squeak system with major version number {sqmajor}.

You must install this package before installing Squeak-{sqmajor}.*.

%prep
%setup -q -n Squeak-{sqmajor}

%install
rm -rf $RPM_BUILD_ROOT
./INSTALL $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
{sqlibdir}
