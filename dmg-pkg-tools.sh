#!/bin/bash

# It seems that 7z can handle both dmg and pkg files so, for Windows (at least)
# we should use this (although I've made all of the tools compile on Windows,
# we can't mount img files so this script can't be used on that platform)

# Keeps a cache of the mounted DMG file in $(dirname $0)/.dmgtools.mounted
# Keeps a cache of the loop device in $(dirname $0)/.dmgtools.loopdev
#  to avoid re-mount un-necessarily.
# Keeps a cache of copied-from-dmg files to avoid mounting un-necessarily.

. ./bash-tools.sh

patch_mingw_types_h() {
			printf %s \
'--- sys/types.h-orig	2012-01-13 00:17:02 +0000
+++ sys/types.h	2012-01-13 00:34:53 +0000
@@ -14,6 +14,14 @@
 /* All the headers include this file. */
 #include <_mingw.h>
 
+/* Added by Ray Donnelly (mingw.android@gmail.com). libgcc build fails for Android
+   cross gcc and dmg2img without this. I should find another way as this is a horrible
+   thing to do. */
+typedef        int     uid_t;
+typedef        int     gid_t;
+typedef        int     daddr_t;
+typedef        char *  caddr_t;
+/* End Added by... */
+
 #define __need_wchar_t
 #define __need_size_t
 #define __need_ptrdiff_t
' > /tmp/sys-types-uid_daddr_caddr.patch

	if [[ "$(uname_bt)" == "Windows" ]] ; then
		if [[ -f /mingw/include/sys/types.h ]] ; then
			MINGWTYPES_H=/mingw/include/sys/types.h
		elif [[ -f /usr/include/sys/types.h ]] ; then
			MINGWTYPES_H=/usr/include/sys/types.h
		fi
#		if [[ ! $(egrep gid_t $MINGWTYPES_H) ]] ; then
#			pushd $(dirname $(dirname $MINGWTYPES_H))
#			patch -p0 < /tmp/sys-types-uid_daddr_caddr.patch
#			popd
#		fi
	fi
}

downloadUntar() {
	download "$1"
	local _FNAME=$(basename $1)
	tar -zxf $_FNAME
}

# Builds dmg2img decryption tools and vfdecrypt, which we will use later to convert dmgs to
# images, so that we can mount them.
# This needs splitting up; some of the libs are just plain needed and
#  building the tools for dmg is flaky (on MinGW64) atm. Need 
build_tools_dmg() {
	patch_mingw_types_h
	local _TMP_DIR=$1; shift
	local _PREFIX=$1; shift
	local _TCPREFIX=$1; shift
	local _TOOLCHAIN=$1; shift
	local _SAVE_INTERMEDIATES=1
	local _JOBS=8
	local _SUDO=sudo
	local _MACHFLAG=
	if [[ "$UNAME" == "Windows" ]] ; then
		_JOBS=1
		_SUDO=
		_MACHFLAG=-mwindows
	fi
	mkdir -p $_TMP_DIR
	pushd $_TMP_DIR
	mkdir -p $_PREFIX/include
	mkdir -p $_PREFIX/lib
	export PATH=$_PREFIX/bin:$PATH
	if [[ "$UNAME" == "Windows" ]] ; then
		if [[ ! -d zlib-1.2.7 ]] ; then
			if ! $(downloadUntar http://downloads.sourceforge.net/libpng/zlib/1.2.7/zlib-1.2.7.tar.gz); then
				error "Failed to get and extract zlib-1.2.7 Check errors."
				popd
				exit 1
			fi
			pushd zlib-1.2.7
			if ! INCLUDE_PATH=$_PREFIX/include LIBRARY_PATH=$_PREFIX/lib BINARY_PATH=$_PREFIX/bin make -f win32/Makefile.gcc -j $_JOBS install; then
				error "Failed to make zlib-1.2.7"
				exit 1
			fi
			popd
		fi
     
        if [[ ! $(which cvs) ]] ; then
            download http://kent.dl.sourceforge.net/project/mingw/MSYS/Extension/cvs/cvs-1.12.13-2/cvs-1.12.13-2-msys-1.0.13-bin.tar.lzma
            tar -xJf cvs-1.12.13-2-msys-1.0.13-bin.tar.lzma -C /
            download http://kent.dl.sourceforge.net/project/mingw/MSYS/Base/gettext/gettext-0.17-2/libintl-0.17-2-msys-dll-8.tar.lzma
            tar -xJf libintl-0.17-2-msys-dll-8.tar.lzma -C /
            download http://kent.dl.sourceforge.net/project/mingw/MSYS/Base/libiconv/libiconv-1.13.1-2/libiconv-1.13.1-2-msys-1.0.13-dll-2.tar.lzma
            tar -xJf libiconv-1.13.1-2-msys-1.0.13-dll-2.tar.lzma -C /
            download http://kent.dl.sourceforge.net/project/mingw/MSYS/Extension/crypt/crypt-1.1_1-3/libcrypt-1.1_1-3-msys-1.0.13-dll-0.tar.lzma
            tar -xJf libcrypt-1.1_1-3-msys-1.0.13-dll-0.tar.lzma -C /
        fi

#		if [[ ! -d pthreads ]] ; then
		if [[ ! -d winpthreads ]] ; then
# On 07062012, pthreads head was broken. They've changed the Makefiles too.
            svn co https://mingw-w64.svn.sourceforge.net/svnroot/mingw-w64/experimental/winpthreads winpthreads
            pushd winpthreads
            ./configure --enable-static --enable-shared --prefix=$_PREFIX
            make && make install
            popd
            
#            cvs -d :pserver:anoncvs@sourceware.org:/cvs/pthreads-win32 checkout -D "March 16, 2012" pthreads  # -r1.89 ?
#            pushd pthreads
#            make -j $_JOBS clean GC-static
#            cp libpthreadGC2.a $_PREFIX/lib/libpthreadGC2.a
#            make -j $_JOBS clean GCE
#            cp libpthreadGCE2.a $_PREFIX/lib/libpthreadGCE2.a
#            cp libpthreadGCE2.a $_PREFIX/bin/pthreadGCE2.dll

#			cvs -d :pserver:anoncvs@sourceware.org:/cvs/pthreads-win32 checkout pthreads
#			pushd pthreads
#			make -j $_JOBS clean GC-static -f GNUmakefile
#			cp libpthreadGC2.a $_PREFIX/lib/libpthreadGC2.a
#			make -j $_JOBS clean GCE -f GNUmakefile
#			cp libpthreadGCE2.a $_PREFIX/lib/libpthreadGCE2.a
#			cp libpthreadGCE2.a $_PREFIX/bin/pthreadGCE2.dll
			# For GOMP. The usual linux/vs-mingw -l<lib> issue... -> TODORMD :: This may not be needed!
#	 		cp libpthreadGC2.a $_PREFIX/lib/libpthread.a
#			cp pthread.h sched.h semaphore.h $_PREFIX/include/
#			popd
#			exit 1
		fi

		if [[ ! -d libiconv-1.14 ]] ; then
			if ! $(downloadUntar http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz); then
				error "Failed to get and extract libiconv-1.14 Check errors."
			fi
			pushd libiconv-1.14
			CFLAGS=-O2 && ./configure --enable-static --disable-shared --prefix=$_PREFIX  CFLAGS=-O2
			if ! make -j $_JOBS install-lib ; then
				error "Failed to make libiconv-1.14"
			fi
			do_sed $"s/iconv_t cd,  char\* \* inbuf/iconv_t cd,  const char\* \* inbuf/g" $_PREFIX/include/iconv.h
			popd
		fi

		if [[ ! -d gettext-0.18.1.1 ]] ; then
			if ! $(downloadUntar http://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.1.1.tar.gz); then
				error "Failed to get and extract gettext-0.18.1.1 Check errors."
			fi
			pushd gettext-0.18.1.1
			patch --backup -p0 < ${_TOOLCHAIN}/patches/gettext-0.18.1.1-win-pthreads.patch
			# Without NM=... gettext-tools\libgettextpo\exported.sh ends up with /bin/nm and that fails to eval:
			# nm_cmd="/bin/nm $1 | sed -n -e 's/^.*[	 ]\([ABCDGIRSTW][ABCDGIRSTW]*\)[	 ][	 ]*_\([_A-Za-z][_A-Za-z0-9]*\)\{0,1\}$/\1 _\2 \2/p'"
			# eval $nm_cmd
			NM="C:/usr/bin/nm.exe" ./configure --disable-java --disable-native-java --disable-tests --enable-static --disable-shared --with-libiconv-prefix=$_PREFIX --enable-multibyte --prefix=$_PREFIX CFLAGS="-O3 -DPTW32_STATIC_LIB"
			if ! make -j $_JOBS install ; then
				error "Failed to make gettext-0.18.1.1"
			fi
			popd
		fi
		if [[ ! -d mingw-libgnurx-2.5.1 ]] ; then
			if ! $(downloadUntar http://kent.dl.sourceforge.net/project/mingw/Other/UserContributed/regex/mingw-regex-2.5.1/mingw-libgnurx-2.5.1-src.tar.gz); then
				error "Failed to get and extract mingw-regex-2.5.1 Check errors."
			fi
			pushd mingw-libgnurx-2.5.1
			patch --backup -p0 < ${_TOOLCHAIN}/patches/mingw-libgnurx-2.5.1-static.patch
			./configure --prefix=$_PREFIX --enable-static --disable-shared
			if ! make  -j $_JOBS; then
				error "Failed to make mingw-libgnurx-2.5.1"
				popd
				exit 1
			fi
			make -j $_JOBS install
			popd
		fi

		# Needed by both dmg2img and xar (and ld64 later...)
		if [[ ! -d openssl-1.0.0f ]] ; then
			if ! $(downloadUntar http://www.openssl.org/source/openssl-1.0.0f.tar.gz); then
					error "Failed to get and extract openssl-1.0.0f Check errors."
					popd
					exit 1
			fi

			pushd openssl-1.0.0f
			./configure --prefix=$_PREFIX -no-shared -no-zlib-dynamic -no-test mingw
			make -j $_JOBS
			make -j $_JOBS install
			popd
		fi

		if [ ! -f $_PREFIX/lib/libcurses.a ] ; then
			if ! $(downloadUntar http://downloads.sourceforge.net/pdcurses/pdcurses/3.4/PDCurses-3.4.tar.gz); then
				error "Failed to get and extract PDCurses. Check errors."
				popd
				exit 1
			fi
			rm -rf PDCurses-3.4
			tar -xvzf PDCurses-3.4.tar.gz
			pushd PDCurses-3.4/win32
			sed '90s/-copy/-cp/' mingwin32.mak > mingwin32-fixed.mak
			make -f mingwin32-fixed.mak WIDE=Y UTF8=Y DLL=N
			cp pdcurses.a $_PREFIX/lib/libcurses.a
			cp pdcurses.a $_PREFIX/lib/libncurses.a
			cp pdcurses.a $_PREFIX/lib/libpdcurses.a
			cp ../curses.h $_PREFIX/include
			cp ../panel.h $_PREFIX/include
			popd
		fi
		message_status "PDCurses is ready!"

		if [ -z $(which nano) ] ; then
			message_status "Retrieving and building nano 2.3.1 ..."
			if ! $(downloadUntar http://www.nano-editor.org/dist/v2.3/nano-2.3.1.tar.gz); then
				error "Failed to get and extract nano-2.3.1. Check errors."
				popd
				exit 1
			fi

			pushd nano-2.3.1
			patch --backup -p1 < ${_TOOLCHAIN}/patches/nano-2.3.1-WIN.patch
			CFLAGS="-I$_PREFIX/include -DENOTSUP=48 -D_POSIX_SOURCE" LDFLAGS="-L$_PREFIX/lib -static-libgcc" LIBS="-lregex -liconv -lintl" ./configure --prefix=$_PREFIX --enable-color
			if ! make -j $_JOBS install; then
				error "Failed to make nano-2.3.1"
				exit 1
			fi
			cp .nanorc ~/.nanorc
			popd
		fi
		message_status "nano is ready!"
	fi

	if [ -z $(which dmg2img) ] ; then
		if [[ "$(uname_bt)" == "Windows" ]] ; then
			message_status "Retrieving and building bzip2 1.0.6 ..."
			if ! $(downloadUntar http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz); then
				error "Failed to get and extract bzip2-1.0.6 Check errors."
				popd
				exit 1
			fi
			pushd bzip2-1.0.6
			# Fails due to chmod a+x without .exe suffix, ignored.
			cp ${_TOOLCHAIN}/files/bzip2-1.0.6-Makefile ./Makefile
			do_sed $"s#PREFIX=/usr#PREFIX=$_PREFIX#g" ./Makefile
			make -j -k $_JOBS install
			popd

			[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf bzip2-1.0.6
		fi

		message_status "Retrieving and building dmg2img 1.6.2 ..."

		if ! $(downloadUntar http://mingw-and-ndk.googlecode.com/files/dmg2img-1.6.2.tar.gz); then
			error "Failed to get and extract dmg2img-1.6.2 Check errors."
			exit 1
		fi

		pushd dmg2img-1.6.2
		patch --backup -p1 < ${_TOOLCHAIN}/patches/dmg2img-1.6.2-WIN.patch
		if ! CFLAGS="-I$_PREFIX/include" LDFLAGS="-L$_PREFIX/lib $_MACHFLAG" CC="gcc" DESTDIR="$_PREFIX" make -j $_JOBS install; then
			error "Failed to make dmg2img-1.6.2"
			error "Make sure you have libbz2-dev and libssl-dev available on your system."
			popd
#			exit 1
		fi

		[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf dmg2img-1.6.2
		popd
	fi
	message_status "dmg2img is ready!"
	if [ -z $(which xml2-config) ] ; then

		if ! $(downloadUntar http://xmlsoft.org/sources/old/libxml2-2.7.1.tar.gz); then
			error "Failed to get and extract libxml2-2.7.1 Check errors."
			popd
			exit 1
		fi

		pushd libxml2-2.7.1
		./configure --prefix=$_PREFIX --with-threads=no --disable-shared --enable-static
		make -j $_JOBS
		make -j $_JOBS install

		if ! make -j $_JOBS install; then
			error "Failed to make libxml2-2.7.1"
			popd
			exit 1
		fi

		popd
		[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf libxml2-2.7.1
	fi

	if [ -z $(which cpio) ] ; then
		if ! $(downloadUntar http://ftp.gnu.org/gnu/cpio/cpio-2.11.tar.gz); then
			error "Failed to get and extract cpio-2.11 Check errors."
			popd
#			exit 1
		fi
		pushd cpio-2.11
		patch --backup -p1 < ${_TOOLCHAIN}/patches/cpio-2.11-WIN.patch
		CFLAGS=-O2 && ./configure --prefix=$_PREFIX  CFLAGS=-O2
		make -j $_JOBS
		make -j $_JOBS install

		popd
		[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf cpio-2.11
	fi
	if [[ "$(uname_bt)" == "Windows" ]] && [[ -z $(which lns) ]] ; then
		message_status "Retrieving and building Nokia's lns ..."
		git clone git://gitorious.org/qt-labs/qtmodularization.git
		pushd qtmodularization
		patch -p1 < ${_TOOLCHAIN}/patches/lns-git.patch
		pushd src/lns
		CXXFLAGS="-DSE_PRIVILEGE_REMOVED=4" make
		cp ../../lns.exe $_PREFIX/bin/
		popd
		popd
	fi
	if [ -z $(which xar) ] ; then
		if [[ ! -d xar-1.5.2 ]] ; then
			if ! $(downloadUntar http://xar.googlecode.com/files/xar-1.5.2.tar.gz); then
				error "Failed to get and extract xar-1.5.2 Check errors."
				popd
				exit 1
			fi
		fi
		pushd xar-1.5.2
		patch --backup -p1 < ${_TOOLCHAIN}/patches/xar-1.5.2-WIN.patch
		if [[ "$UNAME" == "Windows" ]] ; then
			if ! CFLAGS="-I$_PREFIX/include -DENOTSUP=48" LDFLAGS="-L$_PREFIX/lib" LIBS="-lgdi32 -lregex -lmingwex" ./configure --prefix=$_PREFIX --disable-shared --enable-static; then
				error "Failed to configure xar-1.5.2"
				popd
				exit 1
			fi
		else
			if ! CFLAGS="-I$_PREFIX/include" LDFLAGS="-L$_PREFIX/lib" ./configure --prefix=$_PREFIX --disable-shared --enable-static; then
				error "Failed to configure xar-1.5.2"
				popd
				exit 1
			fi
		fi

		make -j $_JOBS
		make -j $_JOBS install
		if ! make -j $_JOBS && make -j $_JOBS install; then
			error "Failed to make xar-1.5.2"
			popd
			exit 1
		fi

		popd
		[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf xar-1.5.2
	fi
	message_status "xar is ready!"

	if [ -z $(which git) ] ; then
		if ! $(downloadUntar http://www.kernel.org/pub/software/scm/git/git-1.7.3.tar.gz); then
			error "Failed to get and extract git-1.7.3 Check errors."
			exit 1
		fi

		pushd git-1.7.3

		if ! make install; then
			error "Failed to make git-1.7.3"
			exit 1
		fi

		popd
		[[ $_SAVE_INTERMEDIATES == 1 ]] || rm -Rf git-1.7.3
	fi
	message_status "git is ready!"

	# mmap problems.
#	if [ -z $(which ldid) ] ; then
#		if ! $(downloadUntar http://svn.telesphoreo.org/trunk/data/ldid/ldid-1.0.610.tgz); then
#			error "Failed to get and extract ldid-1.0.610 Check errors."
#			exit 1
#		fi
#		pushd ldid-1.0.610
#		g++ -I . -o util/ldid{,.cpp} -x c util/{lookup2,sha1}.c
#		mkdir -p ${_TCPREFIX}/pre/bin/
#		cp -a util/ldid${EXEEXT} ${_TCPREFIX}/pre/bin/
#		message_action "ldid built. (direct)"
#		popd
#	fi
#	message_status "ldid is ready!"
	popd
}

# Platform independent umount command
umount_dmg() {
	local _MNT_DIRCACHE=$(dirname $0)/.dmgtools.dir
	local _MNT_CACHE=$(dirname $0)/.dmgtools.mounted
	local _MNT_LOOPDEV=$(dirname $0)/.dmgtools.loopdev
	local _MNT_DEV=( $(cat $_MNT_LOOPDEV) )
	if [[ -f $_MNT_LOOPDEV ]] ; then
		local _MNT_DIR=( $(cat $_MNT_DIRCACHE) )

		if [[ "$(uname_bt)" == "Darwin" ]] ; then
			$SUDO hdiutil detach $_MNT_DIR
		else
			# shouldn't we have a DEBUG var and only
			# delete the TMP_IMG if DEBUG is not set/true
			$SUDO umount -fl $_MNT_DIR
			$SUDO losetup -d $_MNT_DEV
		fi
		sleep 1
		if [ ! $? == 0 ]; then
			error "Failed to unmount."
			exit 1
		fi
		if [[ -f $_MNT_DIRCACHE ]] ; then
			rm -f $_MNT_DIRCACHE
		fi
		if [[ -f $_MNT_CACHE ]] ; then
			rm -f $_MNT_CACHE
		fi
		if [[ -f $_MNT_LOOPDEV ]] ; then
			rm -f $_MNT_LOOPDEV
		fi
	fi
}

# Platform independent mount command
mount_dmg() {
	local _MNT_DIRCACHE=$(dirname $0)/.dmgtools.dir
	local _MNT_CACHE=$(dirname $0)/.dmgtools.mounted
	local _MNT_LOOPDEV=$(dirname $0)/.dmgtools.loopdev
	# Key provided, we need to decrypt the DMG first
	local _TMP_DIR=$1; shift
	local _DMG=$1; shift
	local _MNT_DIR=$1; shift
	local _MNTFILE=
	if [[ -f $_MNT_CACHE ]] ; then
		_MNTFILE=( $(cat $_MNT_CACHE) )
	fi

	if [[ $_MNTFILE == $_DMG ]] ; then
		# Already mounted.
		return 0
	fi

	if [[ ! -z $3 ]] ; then
		message_status "Decrypting `basename $1`..."
		TMP_DECRYPTED=${_TMP_DIR}/`basename "$1"`.decrypted
		if ! vfdecrypt -i $1 -o $TMP_DECRYPTED -k $3 &> /dev/null; then
			error "Failed to decrypt `basename $1`!"
			exit 1
		fi
		_DMG="${TMP_DECRYPTED}"
	fi
	if [[ ! -z $_MNTFILE ]] ; then
		if [[ $_MNTFILE != $_DMG ]] ; then
			umount_dmg
		fi
	fi
	[[ -d $_MNT_DIR ]] || mkdir -p $_MNT_DIR
	if [[ "$(uname_bt)" == "Darwin" ]] ; then
		# echo "In order to extract `basename $1`, I am going to mount it."
		# echo "This needs to be done as root."
		sudo hdiutil attach -noverify -mountpoint $_MNT_DIR $_DMG
		_MOUNT_RES=$?
	else
		# Convert the DMG to an IMG for mounting
		_TMP_IMG=${_TMP_DIR}/`basename "$_DMG" .dmg`.img
		[ ! -f $_TMP_IMG ] && dmg2img -v -i "$_DMG" -o "$_TMP_IMG"
		# echo "In order to extract `basename $1`, I am going to mount it."
		# echo "This needs to be done as root."
		# This is needed for 3.0 sdk and dmg2img 1.6.1
		local _i
		# /dev/loop0 may be in use, so loop over /dev/loop0..7
		for _i in {0..7}
		do
			$SUDO losetup -o 36864 /dev/loop$_i "$_TMP_IMG"
			if [[ $? == 0 ]] ; then
				$SUDO mount -t hfsplus /dev/loop$_i $_MNT_DIR
				if [[ $? == 0 ]] ; then
					echo /dev/loop$_i > $_MNT_LOOPDEV
					break
				fi
			fi
		done
#		$SUDO mount -t hfsplus -o loop,offset=36864 $TMP_IMG $2
		_MOUNT_RES=$?
		sleep 1
		# find $2
	fi
	if [[ ! $_MOUNT_RES = 0 ]] ; then
		error "Failed to mount `basename $1`."
		exit 1
	fi
	echo $_DMG > $_MNT_CACHE
	echo $_MNT_DIR > $_MNT_DIRCACHE
}

cache_packages() {
	local _DMG=$1
	shift
	local _DST=$1
	shift
	local _KM=$1
	shift
	local _KEY=$1
	shift
	local _TMPDIR=$1
	shift
	local _MNTDIR=$1
	shift
	local _PKGS=("$@")
	shift

	local _ALL_PKGS_FOUND=1
	for i in "${_PKGS[@]}"
	do
		local _EXT="${i##*.}"
		local _CACHE_FILE=${_DST}/$(basename ${_DMG} ".dmg")##$(basename "${i}" ${_EXT})${_EXT}
		if [[ ! -f ${_CACHE_FILE} ]] ; then
			_ALL_PKGS_FOUND=0
		fi
	done

	local _MOUNTED=0
	mkdir -p $_DST

	if [[ ${_ALL_PKGS_FOUND} = 0 ]] ; then
		mount_dmg $_TMPDIR $_DMG $_MNTDIR $_KEY
		_MOUNTED=1
		for i in "${_PKGS[@]}"
		do
			local _EXT="${i##*.}"
			local _CACHE_FILE=${_DST}/$(basename ${_DMG} ".dmg")##$(basename "${i}" ${_EXT})${_EXT}
			if [[ ! -f ${_CACHE_FILE} ]] && [[ -f ${_MNTDIR}/$i ]] ; then
				cp "${_MNTDIR}/$i" "${_CACHE_FILE}"
				echo "${_CACHE_FILE}"
			fi
			if [[ ! -r ${_MNTDIR}/$i ]] ; then
				error "I tried to cache ${_MNTDIR}/$i but I couldn't find it!"
				echo $(ls ${_MNTDIR}/Packages)
				exit 1
			fi
		done
	else
		for i in "${_PKGS[@]}"
		do
			local _EXT="${i##*.}"
			local _CACHE_FILE=${_DST}/$(basename ${_DMG} ".dmg")##$(basename "${i}" ${_EXT})${_EXT}
			echo "${_CACHE_FILE}"
		done
	fi

	if [[ $_MOUNTED = 1 ]] && [[ $_KM = 0 ]] ; then
		umount_dmg
	fi
}

extract_packages_cached() {
	local _OUTDIR=$1; shift
	local _PKGSC=("$@")

	local _in
	for _in in "${_PKGSC[@]}"
	do
		message_status "extract_packages_cached ${_in}"
		local _CACHE_FILE=${_in}
		if [ -f ${_CACHE_FILE} ] ; then
			echo "extracting ${_CACHE_FILE}"
			pushd $_OUTDIR
			xar -xf ${_CACHE_FILE} Payload
			# zcat on OSX needs .Z suffix
			cat Payload | zcat | cpio -id
			rm Payload
			popd
		else
			error "Failed to extract $_CACHE_FILE"
		fi
	done
}

extract_packages() {
	message_status "in extract_packages"
	local _OUTDIR=$1; shift
	local _PKGSDIR=$1; shift
	local _DMG=$1; shift
	local _PKGS=("$@")

	local _i
	for _i in "${_PKGS[@]}"
	do
		message_status "file is $_i"
		local _EXT="${_i##*.}"
		local _CACHE_FILE=${_PKGSDIR}/$(basename ${_DMG} ".dmg")##$(basename "${_i}" ${_EXT})${_EXT}
		_CACHEDPKGS[${#_CACHEDPKGS[*]}]="$_CACHE_FILE"
	done
	echo ${_CACHEDPKGS[@]}
	extract_packages_cached $_OUTDIR "${_CACHEDPKGS[@]}"
	message_status "done extract_packages"
}
