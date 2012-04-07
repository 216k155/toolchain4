#!/bin/bash

# Attempts to compile and link ndk-stack.

. bash-tools.sh

if [[ "$(uname-bt)" = "Linux" ]] ; then
	STRACE="strace -F -s 512 -e access,open,execve,stat64,fstat64"
elif [[ "$(uname-bt)" = "Darwin" ]] ; then
	STRACE="dtruss"
fi

download http://dl.google.com/android/ndk/android-ndk-r6b-linux-x86.tar.bz2
if [[ ! -d android-ndk-r6b ]] ; then
	tar -xjf android-ndk-r6b-linux-x86.tar.bz2
	pushd android-ndk-r6b
	patch -p1 < ../patches/test/android-ndk-r6b-darwincross.patch
	popd
fi

OUTDIR=$PWD

if [[ ! -z $1 ]] ; then
	LEFT=${1}
else
	LEFT=fixed
fi
OUTLEFT=$OUTDIR/$LEFT
mkdir -p $OUTLEFT

if [[ ! -z $2 ]] ; then
	RIGHT=${2}
	OUTRIGHT=$OUTDIR/$RIGHT
	mkdir -p $OUTRIGHT
else
	RIGHT=/
	OUTRIGHT=$OUTDIR/apple
	mkdir -p $OUTRIGHT
fi

#FIXED_TOOLCHAIN=$PWD/pre-$LEFT/bin/i686-apple-darwin11
#MOVED_TOOLCHAIN=$PWD/pre-$RIGHT/bin/i686-apple-darwin11

# FIXED_TOOLCHAIN=/tmp2/$LEFT/bin/i686-apple-darwin11
# MOVED_TOOLCHAIN=/tmp2/$RIGHT/bin/i686-apple-darwin11
# ARCHS="-m64"

FIXED_TOOLCHAIN=/tmp2/$LEFT/bin/${LEFT}-g++
if [[ "$RIGHT" = "/" ]] ; then
	MOVED_TOOLCHAIN=/usr/bin/llvm-g++-4.2
else
	MOVED_TOOLCHAIN=/tmp2/$RIGHT/bin/${RIGHT}-g++
fi
ARCHS="-arch x86_64 -arch i386"

SDK=$PWD/sdks/MacOSX10.7.sdk

pushd android-ndk-r6b/sources/host-tools/ndk-stack

#dtruss -n $(basename ${FIXED_TOOLCHAIN}g++) > $OUTLEFT/dtrace.txt 2>&1 &
${STRACE} ${FIXED_TOOLCHAIN} $ARCHS -lstdc++ ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o $OUTLEFT/ndk-stack --sysroot $SDK > $OUTLEFT/strace.txt 2>&1
#dtruss -n $(basename ${MOVED_TOOLCHAIN}g++) > $OUTRIGHT/dtrace.txt 2>&1 &
${STRACE} ${MOVED_TOOLCHAIN} $ARCHS -lstdc++ ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o $OUTRIGHT/ndk-stack --sysroot $SDK > $OUTRIGHT/strace.txt 2>&1

${FIXED_TOOLCHAIN} --print-search-dirs > $OUTLEFT/search-dirs.txt 2>&1
${MOVED_TOOLCHAIN} --print-search-dirs > $OUTRIGHT/search-dirs.txt 2>&1
${FIXED_TOOLCHAIN} -dumpspecs > $OUTLEFT/specs.txt 2>&1
${MOVED_TOOLCHAIN} -dumpspecs > $OUTRIGHT/specs.txt 2>&1

${STRACE} ${FIXED_TOOLCHAIN} -print-prog-name=as > $OUTLEFT/print-prog-name-as.txt 2>&1
${STRACE} ${MOVED_TOOLCHAIN} -print-prog-name=as > $OUTRIGHT/print-prog-name-as.txt 2>&1

popd

rm -f $(uname-bt)-test.7z
7za a -mx=9 $(uname-bt)-test.7z $OUTLEFT $OUTRIGHT
cp $(uname-bt)-test.7z ~/Dropbox/darwin-compilers-work/

if [[ $(which bcmp) ]] ; then
    bcmp $OUTLEFT/strace.txt $OUTRIGHT/strace.txt &
    bcmp $OUTLEFT/search-dirs.txt $OUTRIGHT/search-dirs.txt &
    bcmp $OUTLEFT/specs.txt $OUTRIGHT/specs.txt &
    bcmp $OUTLEFT/print-prog-name-as.txt $OUTRIGHT/print-prog-name-as.txt &
fi

# Ok, finally...
# "-syslibroot", "/home/nonesuch/src/toolchain4/pre-fixed"

# For QtCreator debugging:
# Executable: /tmp/darwin-gcc-moved/bin/i686-apple-darwin11-g++
# Arguments : -lstdc++ -m32 ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-darwin-gcc-moved --sysroot /home/nonesuch/src/toolchain4/sdks/MacOSX10.7.sdk
# WorkingDir: /home/nonesuch/src/toolchain4/android-ndk-r6b/sources/host-tools/ndk-stack
