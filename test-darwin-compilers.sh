#!/bin/bash

# Attempts to compile and link ndk-stack.

. bash-tools.sh

if [[ "$(uname-bt)" = "Linux" ]] ; then
	STRACE="strace -F -s 512 -e access,open,execve,stat64,fstat64"
fi

download http://dl.google.com/android/ndk/android-ndk-r6b-linux-x86.tar.bz2
if [[ ! -d android-ndk-r6b ]] ; then
	tar -xjf android-ndk-r6b-linux-x86.tar.bz2
	pushd android-ndk-r6b
	patch -p1 < ../patches/test/android-ndk-r6b-darwincross.patch
	popd
fi

if [[ ! -z $1 ]] ; then
	LEFT=$1
else
	LEFT=fixed
fi

if [[ ! -z $2 ]] ; then
	RIGHT=$2
else
	RIGHT=moved
fi

OUTDIR=$PWD

#FIXED_TOOLCHAIN=$PWD/pre-$LEFT/bin/i686-apple-darwin11
#MOVED_TOOLCHAIN=$PWD/pre-$RIGHT/bin/i686-apple-darwin11

FIXED_TOOLCHAIN=/tmp2/$LEFT/bin/i686-apple-darwin11
MOVED_TOOLCHAIN=/tmp2/$RIGHT/bin/i686-apple-darwin11

SDK=$PWD/sdks/MacOSX10.7.sdk

pushd android-ndk-r6b/sources/host-tools/ndk-stack

ARCHS="-m64"
#cc1plus: error: unrecognised command line option "-arch"
ARCHS="-arch x86_64 -arch i386"
${STRACE} ${FIXED_TOOLCHAIN}-g++ $ARCHS -lstdc++ ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-$LEFT --sysroot $SDK > $OUTDIR/strace-pre-$LEFT.txt 2>&1
${STRACE} ${MOVED_TOOLCHAIN}-g++ $ARCHS -lstdc++ ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-$RIGHT --sysroot $SDK > $OUTDIR/strace-pre-$RIGHT.txt 2>&1

${FIXED_TOOLCHAIN}-g++ --print-search-dirs > $OUTDIR/search-dirs-pre-$LEFT.txt 2>&1
${MOVED_TOOLCHAIN}-g++ --print-search-dirs > $OUTDIR/search-dirs-pre-$RIGHT.txt 2>&1
${FIXED_TOOLCHAIN}-g++ -dumpspecs > $OUTDIR/specs-pre-$LEFT.txt 2>&1
${MOVED_TOOLCHAIN}-g++ -dumpspecs > $OUTDIR/specs-pre-$RIGHT.txt 2>&1

${STRACE} ${FIXED_TOOLCHAIN}-g++ -print-prog-name=as > $OUTDIR/print-prog-name-as-pre-$LEFT.txt 2>&1
${STRACE} ${MOVED_TOOLCHAIN}-g++ -print-prog-name=as > $OUTDIR/print-prog-name-as-pre-$RIGHT.txt 2>&1

popd

bcompare strace-pre-$LEFT.txt strace-pre-$RIGHT.txt &
bcompare search-dirs-pre-$LEFT.txt search-dirs-pre-$RIGHT.txt &
bcompare specs-pre-$LEFT.txt specs-pre-$RIGHT.txt &
bcompare print-prog-name-as-pre-$LEFT.txt print-prog-name-as-pre-$RIGHT.txt &

# Ok, finally...
# "-syslibroot", "/home/nonesuch/src/toolchain4/pre-fixed"

# For QtCreator debugging:
# Executable: /tmp/darwin-gcc-moved/bin/i686-apple-darwin11-g++
# Arguments : -lstdc++ -m32 ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-darwin-gcc-moved --sysroot /home/nonesuch/src/toolchain4/sdks/MacOSX10.7.sdk
# WorkingDir: /home/nonesuch/src/toolchain4/android-ndk-r6b/sources/host-tools/ndk-stack
