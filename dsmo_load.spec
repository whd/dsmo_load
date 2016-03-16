Name:           dsmo_load
Version:        0.1
# Release:        %{release}
Release:        1
Summary:        %{name}

License:        MPL 2.0
Source0:        %{name}.tar.gz

Requires:       postgresql-libs
Requires:       luasandbox-core
Requires:       hindsight
Requires:       heka

BuildRequires: systemd-units

%pre
ldconfig

%description
Generates Redshift derived streams from download-stats.mozilla.org server logs.

%prep
%setup -q -n %{name}

%install
mkdir -p '%{buildroot}/opt/%{name}/'
cp -aR hindsight '%{buildroot}/opt/%{name}/'
cp -aR heka/* '%{buildroot}/'
mkdir -p '%{buildroot}/%{_unitdir}'
cp %{name}.service '%{buildroot}/%{_unitdir}/'

%clean
rm -rf '%{buildroot}'

%files
%defattr(-,root,root,-)
/opt/%{name}/
/usr/share/heka/
/etc/heka.d/
%{_unitdir}/
