###########  HOW TO USE THIS SPEC FILE  ###########

#  Ensure you have the rpm-build rpm installed
#  Example:  sudo yum -y install rpm-build

#  If you do not already have the rpmbuild folder structure created, you can create it by running:
#  rpmdev-setuptree after installing the rpmdevtools rpm
#  Example:  sudo yum -y install rpmdevtools && rpmdev-setuptree

#  Change the following to include the domain you are installing a CA Certificate for
#  Example:  %define certdomain example.com

%define certdomain example.com

#  Set the following to todays date in YYYYMMDD format
#  Example:  June 6th, 2024 would be 20240629

%define dateversion 20240629

#  Place the CA Certificate in the rpmbuild/SOURCE directory and name it ca.<domain_name>.crt
#  Example: ca.example.com.crt

#  Place this spec file in the rpmbuild/SPECS directory

#  Build both the binary and source RPM's by running
#  rpmbuild -ba SPECS/Build_CA.spec
#  from the rpmbuild directory

##########################################################
###########  DON'T MODIFY ANYTHING BELOW HERE  ###########
##########################################################


Summary: This RPM will install the CA root certificate for %{certdomain}
Name: %{certdomain}-root-ca
Version: %{dateversion}
Release: 1
License: Proprietary
URL: https://www.%{certdomain}

%define cacertname ca.%{certdomain}.crt

Source0: %{cacertname}

BuildArch: noarch

%description
This package contains the %{cacertname} CA certificate
for the %{certdomain} domain

%define catrustdir %{_sysconfdir}/pki/ca-trust/source/anchors

%setup -q

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m 755 $RPM_BUILD_ROOT%{catrustdir}
install -p -m 644 %{SOURCE0} $RPM_BUILD_ROOT%{catrustdir}/%{cacertname}

%files
%dir %{catrustdir}
%{catrustdir}/%{cacertname}

%post
%{_bindir}/update-ca-trust

%posttrans
%{_bindir}/update-ca-trust

%postun
rm -f %{catrustdir}/%{cacertname}
%{_bindir}/update-ca-trust

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
