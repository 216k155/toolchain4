#!/bin/bash

BASEURL=http://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-devel/binutils-apple
PN=binutils-apple

wget -c $BASEURL/binutils-apple-4.2.ebuild
if [[ ! -d files ]] ; then
 mkdir files
 pushd files
  wget -c ${BASEURL}/files/${PN}-4.0-as.patch
  wget -c ${BASEURL}/files/${PN}-4.2-as-dir.patch
  wget -c ${BASEURL}/files/${PN}-3.2.3-ranlib.patch
  wget -c ${BASEURL}/files/${PN}-3.1.1-libtool-ranlib.patch
  wget -c ${BASEURL}/files/${PN}-3.1.1-nmedit.patch
  wget -c ${BASEURL}/files/${PN}-3.1.1-no-headers.patch
  wget -c ${BASEURL}/files/${PN}-4.0-no-oss-dir.patch
  wget -c ${BASEURL}/files/${PN}-4.2-lto.patch
  wget -c ${BASEURL}/files/ld64-123.2-Makefile
  wget -c ${BASEURL}/files/ld64-127.2-lto.patch
  wget -c ${BASEURL}/files/libunwind-30-Makefile
 popd
fi
