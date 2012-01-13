#!/bin/bash

# Keeps a cache of the mounted DMG file in $(dirname $0)/.dmgtools.mounted
#  to avoid re-mount un-necessarily.
# Keeps a cache of copied-from-dmg files to avoid mounting un-necessarily.

. ./bash-tools.sh

MNT_DIR=/tmp/mnt
MNT_CACHE=$(dirname $0)/.dmgtools.mounted

UNAME=$(uname-bt)

if [[ "$(uname-bt)" == "Windows" ]] ; then
	SUDO=
else
	SUDO=sudo
fi

patch_mingw_types_h() {
	if [[ "$(uname-bt)" == "Windows" ]] ; then
		if [[ ! $(egrep uid_t /usr/include/sys/types.h) ]] ; then
			printf %s \
'--- sys/types.h-orig	2012-01-13 00:17:02 +0000
+++ sys/types.h	2012-01-13 00:34:53 +0000
@@ -14,6 +14,15 @@
 /* All the headers include this file. */
 #include <_mingw.h>
 
+/* Added by Ray Donnelly (mingw.android@gmail.com). libgcc build fails for Android 
+   cross gcc or dmg2img without this. I should find another way as this is a horrible
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
' > /usr/include/sys-types-uid_daddr_caddr.patch
			pushd /usr/include
			patch -p0 < sys-types-uid_daddr_caddr.patch		
			popd
		fi
	fi
}

# Builds dmg2img decryption tools and vfdecrypt, which we will use later to convert dmgs to
# images, so that we can mount them.
build_tools_dmg() {
	patch_mingw_types_h
	local _TMP_DIR=$1
	mkdir -p $_TMP_DIR
	pushd $_TMP_DIR

	if [ -z $(which dmg2img) ] ; then
		if [[ 0 == 1 ]] && [[ "$(uname-bt)" == "Windows" ]] ; then

			message_status "Retrieving and building bzip2 1.0.6 ..."

			if ! wget -O - http://bzip.org/1.0.6/bzip2-1.0.6.tar.gz | tar -zx; then
					error "Failed to get and extract bzip2-1.0.6 Check errors."
					popd
					exit 1
			fi

			pushd bzip2-1.0.6
			# Fails due to chmod a+x without .exe suffix, ignored.
			cp ../../files/bzip2-1.0.6-Makefile ./Makefile
			make install
			popd
			
			if ! wget -O - http://www.openssl.org/source/openssl-1.0.0f.tar.gz | tar -zx; then
					error "Failed to get and extract openssl-1.0.0f Check errors."
					popd
					exit 1
			fi

			pushd openssl-1.0.0f
			./configure --prefix=/usr/local -no-shared -no-zlib-dynamic -no-test mingw
			make
			make install
			popd

			rm -Rf bzip2-1.0.6
			rm -Rf openssl-1.0.0f
	
			message_status "Retrieving and building dmg2img 1.6.2 ..."
	
			if ! wget -O - http://vu1tur.eu.org/tools/download.pl?dmg2img-1.6.2.tar.gz | tar -zx; then
				error "Failed to get and extract dmg2img-1.6.2 Check errors."
				exit 1
			fi
		fi

		pushd dmg2img-1.6.2
		patch -p0 <../../patches/dmg2img-1.6.2-WIN.patch
		if ! CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib -mwindows" CC="gcc" make install; then
			error "Failed to make dmg2img-1.6.2"
			error "Make sure you have libbz2-dev and libssl-dev available on your system."
			popd
			exit 1
		fi

		rm -Rf dmg2img-1.6.2
		popd
	fi
	popd
	message_status "dmg2img is ready!"

	if [ -z $(which xml2-config) ] ; then

		pushd $_TMP_DIR

		if ! wget -O - http://xmlsoft.org/sources/old/libxml2-2.7.1.tar.gz | tar -zx; then
			error "Failed to get and extract libxml2-2.7.1 Check errors."
			popd
			exit 1
		fi

		pushd libxml2-2.7.1
		./configure --prefix=/usr/local --with-threads=no --disable-shared --enable-static
		make
		make install

		if ! make install; then
			error "Failed to make libxml2-2.7.1"
			popd
			exit 1
		fi

		popd
#		rm -Rf libxml2-2.7.1
		popd
	fi


	if [ -z $(which xar) ] ; then
		pushd $_TMP_DIR
#if [[ ! -d xar-1.5.2 ]] ; then
		if ! wget -O - http://xar.googlecode.com/files/xar-1.5.2.tar.gz | tar -zx; then
			error "Failed to get and extract xar-1.5.2 Check errors."
			popd
			exit 1
		fi
#fi
		pushd xar-1.5.2
		patch -p0 < ../../patches/xar-1.5.2-WIN.patch
		if ! CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" LIBS="-lgdi32" ./configure --prefix=/usr/local --disable-shared --enable-static; then
			error "Failed to configure xar-1.5.2"
			popd
			exit 1
		fi

		if ! make install; then
			error "Failed to make xar-1.5.2"
			popd
			exit 1
		fi

		popd
		rm -Rf xar-1.5.2
		popd
	fi
	message_status "xar is ready!"
}

# Platform independent umount command
umount_dmg() {
	if [[ $(uname-bt) == "Darwin" ]] ; then
		$SUDO hdiutil detach $MNT_DIR
	else
		# shouldn't we have a DEBUG var and only
		# delete the TMP_IMG if DEBUG is not set/true
		$SUDO umount -fl $MNT_DIR
		$SUDO losetup -d /dev/loop0
		sleep 1
	fi
	if [ ! $? == 0 ]; then
		error "Failed to unmount."
		exit 1
	fi
	if [[ -f $MNT_CACHE ]] ; then
		rm -f $MNT_CACHE
	fi
}

# Platform independent mount command
mount_dmg() {
	# Key provided, we need to decrypt the DMG first
	local _TMP_DIR=$1
	shift
	local _DMG=$1
	shift
	local MNTFILE=
	if [[ -f $MNT_CACHE ]] ; then
		MNTFILE=( $(cat $MNT_CACHE) )
	fi

	if [[ $MNTFILE == $_DMG ]] ; then
		message_status "Already mounted $_DMG..."
		return 0
	fi

	if [[ ! -z $3 ]] ; then
		message_status "Decrypting `basename $1`..."
		TMP_DECRYPTED=${_TMP_DIR}/`basename $1`.decrypted
		if ! vfdecrypt -i $1 -o $TMP_DECRYPTED -k $3 &> /dev/null; then
			error "Failed to decrypt `basename $1`!"
			exit 1
		fi
		local _DMG="${TMP_DECRYPTED}"
	else
		local _DMG="$1"
	fi
	if [[ ! -z $MNTFILE ]] ; then
		if [[ $MNTFILE != $DMG ]] ; then
			umount_dmg
		fi
	fi
	if [[ $(uname-bt) == "Darwin" ]] ; then
		# echo "In order to extract `basename $1`, I am going to mount it."
		# echo "This needs to be done as root."
		# sudo hdiutil attach -mountpoint $2 $DMG
		MOUNT_RES=$?
	else
		# Convert the DMG to an IMG for mounting
		TMP_IMG=${_TMP_DIR}/`basename $_DMG .dmg`.img
		[ ! -f ${TMP_IMG} ] && dmg2img -v -i $_DMG -o $TMP_IMG
		# echo "In order to extract `basename $1`, I am going to mount it."
		# echo "This needs to be done as root."
		# This is needed for 3.0 sdk and dmg2img 1.6.1
		[[ -d $2 ]] || mkdir -p $2
		$SUDO losetup -o 36864 /dev/loop0 $TMP_IMG
		$SUDO mount -t hfsplus /dev/loop0 $2
#		$SUDO mount -t hfsplus -o loop,offset=36864 $TMP_IMG $2
		MOUNT_RES=$?
		sleep 1
		# find $2
	fi
	if [[ ! $MOUNT_RES = 0 ]] ; then
		error "Failed to mount `basename $1`."
		exit 1
	fi
	echo $_DMG > $MNT_CACHE
}

cache_packages() {
	local _DMG=$1
	shift
	local _DST=$2
	shift
	local _KM=$3
	shift
	local _KEY=$4
	shift
	local _PKGS=("$@")
	shift

	local _ALL_PKGS_FOUND=1
	for i in "${_PKGS[@]}"
	do
		local _CACHE_FILE=${_DST}/$(basename ${_DMG} ".dmg")##$(basename ${i} ".pkg").pkg
		echo ${_CACHE_FILE}
		if [[ ! -f ${_CACHE_FILE} ]] ; then
			_ALL_PKGS_FOUND=0
		fi
	done

	local _MOUNTED=0
	mkdir -p $PKG_DIR

	if [[ ${_ALL_PKGS_FOUND} = 0 ]] ; then
		mount_dmg $TMP_DIR $_DMG $MNT_DIR $_KEY
		_MOUNTED=1
		for i in "${_PKGS[@]}"
		do
			local _CACHE_FILE=${_DST}/$(basename ${_DMG} ".dmg")##$(basename ${i} ".pkg").pkg
			if [[ ! -f ${_CACHE_FILE} ]] ; then
				if [[ ! -r ${MNT_DIR}/$i ]] ; then
					error "I tried to cache ${MNT_DIR}/$i but I couldn't find it!"
					echo $(ls ${MNT_DIR}/Packages)
					exit 1
				fi
				cp ${MNT_DIR}/$i ${_CACHE_FILE}
			fi
		done
	fi

	if [[ $_MOUNTED = 1 ]] && [[ $_KM = 0 ]] ; then
		umount_dmg
	fi
}

extract_packages_cached() {
	local _TMPDIR=$1
	shift
	local _PKGS=("$@")

	for i in "${_PKGS[@]}"
	do
		local _CACHE_FILE=${i}
		if [ -f ${_CACHE_FILE} ] ; then
			echo "extracting ${_CACHE_FILE}"
			pushd $_TMP_DIR
			xar -xf ${_CACHE_FILE} Payload
			# zcat on OSX needs .Z suffix
			cat Payload | zcat | cpio -id -v
			rm Payload
			popd
		else
			error "Failed to extract $_CACHE_FILE"
		fi
	done
}

_OPERATION=$1
if [[ "$_OPERATION" == "--help" ]] || [[ -z $1 ]] ; then
	echo "$0 --cache <dmg-file> <--keep-mounted> <--key KEY> <dst-files-folder> FILES..."
	echo "$0 --extract-cached CACHED_PKG_FILES..."
	echo "$0 --list <dmg-file>"
	echo "$0 --umount"
	exit 1
fi
shift
TMPDIR=$PWD/tmp
mkdir -p $TMPDIR
build_tools_dmg $TMPDIR
if [[ "$_OPERATION" == "--cache" ]] ; then
	$DMGFILE=$1
	if [[ ! -f $DMGFILE ]] ; then
		echo "Couldn't find dmg file $DMGFILE"
		exit
	fi
	shift
	KEEP_MOUNTED=0
	if [[ "$1" == "--keep-mounted" ]] ; then
		KEEP_MOUNTED=1
		shift
	fi
	KEY=0
	if [[ "$1" == "--key" ]] ; then
		shift
		KEY=$1
		shift
	fi
	$DEST=$1
	shift
	[[ -d $DEST ]] || mkdir -p $DEST
	if [[ ! -d $DEST ]] ; then
		echo "Couldn't create dest folder $DEST"
	fi
	if [[ "$_OPERATION" == "--cache" ]] ; then
		FILES=("$@")
		cache_packages $DMGFILE $DEST $KEEP_MOUNTED $KEY $FILES
		exit 0
	fi
elif [[ "$_OPERATION" == "--extract-cached" ]] ; then
	FILES=("$@")
	extract_packages_cached $TMPDIR $FILES
elif [[ "$_OPERATION" == "--list" ]] ; then
	DMGFILE=$1
	shift
	mount_dmg $TMPDIR $DMGFILE $MNT_DIR
	find $MNT_DIR
	exit 0
elif [[ "$_OPERATION" == "--umount" ]] ; then
	umount_dmg
fi
