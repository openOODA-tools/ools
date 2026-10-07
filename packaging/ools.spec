Name:           ools
Version:        0.1.0
Release:        1%{?dist}
Summary:        Sovereign directory lister and metadata classifier
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/ools
Source0:        ools-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
ools is a sovereign, capability-bounded directory lister and ls replacement written
in pure openOODA, featuring metadata classification, multi-column grid rendering,
oote color themes, and an MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/ools
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/ools-uninstall

%files
/usr/bin/ools
/usr/bin/ools-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign release: directory scanning, oote palettes, and MCP stdio surface
