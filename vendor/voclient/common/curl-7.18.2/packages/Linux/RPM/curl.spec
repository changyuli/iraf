%define name curl
%define version 7.18.2
%define release 1
%define prefix /usr

%define builddir $RPM_BUILD_DIR/%{name}-%{version}

Summary: get a file from an FTP or HTTP server.
Name: %{name}
Version: %{version}
Release: %{release}
Copyright: MPL
Vendor: Daniel Stenberg <Daniel.Stenberg@haxx.se>
Packager: Loic Dachary <loic@senga.org>
Group: Utilities/Console
Source: %{name}-%{version}.tar.gz
URL: http://curl.haxx.se/
BuildRoot: /tmp/%{name}-%{version}-root

%description
curl is a client to get documents/files from servers, using any of the
supported protocols. The command is designed to work without user
interaction or any kind of interactivity.

curl offers a busload of useful tricks like proxy support, user
authentication, ftp upload, HTTP post, file transfer resume and more.

Note: this version is compiled without SSL (https:) support.

%package	devel
Summary:	The includes, libs, and man pages to develop with libcurl
Group:		Development/Libraries

%description devel
libcurl is the core engine of curl; this packages contains all the libs,
headers, and manual pages to develop applications using libcurl.

%prep
rm -rf %{builddir}

%setup

%build
%configure --without-ssl --prefix=%{prefix}
make 

%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install-strip

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{builddir}

%post
/sbin/ldconfig

%postun
/sbin/ldconfig

%files
%defattr(-,root,root)
%attr(0755,root,root) %{_bindir}/curl
%attr(0644,root,root) %{_mandir}/man1/*
%{prefix}/lib/libcurl.so*
%doc CHANGES LEGAL MITX.txt MPL-1.1.txt README docs/BUGS
%doc docs/CONTRIBUTE docs/FAQ docs/FEATURES docs/INSTALL docs/INTERNALS
%doc docs/LIBCURL docs/MANUAL docs/README* docs/RESOURCES docs/TODO
%doc docs/TheArtOfHttpScripting

%files devel
%defattr(-,root,root)
%attr(0644,root,root) %{_mandir}/man3/*
%attr(0644,root,root) %{_includedir}/curl/*
%{prefix}/lib/libcurl.a
%{prefix}/lib/libcurl.la
%doc docs/examples/*

%changelog
* Sun Jan  7 2001 Loic Dachary  <loic@senga.org>

        - use _mandir instead of prefix to locate man pages because
	  _mandir is not always prefix/man/man?.

