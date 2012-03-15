#!/bin/bash

# A simple script is use as a replacement for debugging what gcc.c does. Debugging gcc.c would be a good plan too though.
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

OUTDIR=$PWD

FIXED_TOOLCHAIN=$PWD/pre-fixed/bin/i686-apple-darwin11
MOVED_TOOLCHAIN=$PWD/pre-moved/bin/i686-apple-darwin11

SDK=$PWD/sdks/MacOSX10.7.sdk

pushd android-ndk-r6b/sources/host-tools/ndk-stack

${STRACE} ${FIXED_TOOLCHAIN}-g++ -lstdc++ -m32 ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-fixed --sysroot $SDK/ -B$SDK/usr/lib/system > $OUTDIR/strace-pre-fixed.txt 2>&1
# ${STRACE} ${MOVED_TOOLCHAIN}-g++ -lstdc++ -m32 ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-moved --sysroot $SDK/ -B$SDK/usr/lib/system > $OUTDIR/strace-pre-moved.txt 2>&1
GCC_EXEC_PREFIX=/usr/home/nonesuch/src/pre-moved/bin/ ${STRACE} ${MOVED_TOOLCHAIN}-g++ -lstdc++ -m32 ndk-stack.c ndk-stack-parser.c elff/dwarf_cu.cc elff/dwarf_die.cc elff/dwarf_utils.cc elff/elf_alloc.cc elff/elf_file.cc elff/elf_mapped_section.cc elff/elff_api.cc elff/mapfile.c regex/regcomp.c regex/regerror.c regex/regexec.c regex/regfree.c -o ndk-stack-pre-moved --sysroot $SDK/ -B$SDK/usr/lib/system > $OUTDIR/strace-pre-moved-GCC_EXEC_PREFIX.txt 2>&1
${FIXED_TOOLCHAIN}-g++ --print-search-dirs > $OUTDIR/search-dirs-pre-fixed.txt 2>&1
${MOVED_TOOLCHAIN}-g++ --print-search-dirs > $OUTDIR/search-dirs-pre-moved.txt 2>&1
${FIXED_TOOLCHAIN}-g++ -dumpspecs > $OUTDIR/specs-pre-fixed.txt 2>&1
${MOVED_TOOLCHAIN}-g++ -dumpspecs > $OUTDIR/specs-pre-moved.txt 2>&1

${STRACE} ${FIXED_TOOLCHAIN}-g++ -print-prog-name=as > $OUTDIR/print-prog-name-as-pre-fixed.txt 2>&1
${STRACE} ${MOVED_TOOLCHAIN}-g++ -print-prog-name=as > $OUTDIR/print-prog-name-as-pre-moved.txt 2>&1

popd

bcompare strace-pre-fixed.txt strace-pre-moved-GCC_EXEC_PREFIX.txt &
bcompare search-dirs-pre-fixed.txt search-dirs-pre-moved.txt &
bcompare specs-pre-fixed.txt specs-pre-moved.txt &
bcompare print-prog-name-as-pre-fixed.txt print-prog-name-as-pre-moved.txt &

# /home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus -iprefix /home/nonesuch/src/toolchain4/pre-moved/bin/../lib/gcc/i686-apple-darwin11/4.2.1/ -isysroot /home/nonesuch/src/toolchain4/sdks/MacOSX10.7.sdk -D__DYNAMIC__ ndk-stack-parser.c -fPIC -mmacosx-version-min=10.4 -dumpbase ndk-stack-parser.c -m32 -mtune=core2 -auxbase ndk-stack-parser -D__private_extern__=extern -o /tmp/ccvJfDxs.s

# Analysis:
# In both cases, cc1plus is found ok:
# stat64("/home/nonesuch/src/toolchain4/pre-fixed/libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", {st_mode=S_IFREG|0755, st_size=16461723, ...}) = 0
# access("/home/nonesuch/src/toolchain4/pre-fixed/libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", X_OK) = 0
# ...and...
# stat64("/home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", {st_mode=S_IFREG|0755, st_size=16461723, ...}) = 0
# access("/home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", X_OK) = 0

# and launched (a bit differently?!):
# [pid 21418] execve("/home/nonesuch/src/toolchain4/pre-fixed/libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus",        ["/home/nonesuch/src/toolchain4/pre-fixed/libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus",        "-quiet",                                                                                                  "-isysroot", "/home/nonesuch/darwin-cross/SDKs/MacOSX10.7.sdk/", "-D__DYNAMIC__", "ndk-stack.c", "-fPIC", "-mmacosx-version-min=10.4", "-quiet", "-dumpbase", "ndk-stack.c", "-m32", "-mtune=core2", "-auxbase", "ndk-stack", "-D__private_extern__=extern", "-o", "/tmp/ccXy75Jy.s"], [/* 43 vars */]Process 21417 suspended) = 0
# [pid 21464] execve("/home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", ["/home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus", "-quiet", "-iprefix", "/home/nonesuch/src/toolchain4/pre-moved/bin/../lib/gcc/i686-apple-darwin11/4.2.1/", "-isysroot", "/home/nonesuch/darwin-cross/SDKs/MacOSX10.7.sdk/", "-D__DYNAMIC__", "ndk-stack.c", "-fPIC", "-mmacosx-version-min=10.4", "-quiet", "-dumpbase", "ndk-stack.c", "-m32", "-mtune=core2", "-auxbase", "ndk-stack", "-D__private_extern__=extern", "-o", "/tmp/cc1hKPQX.s"], [/* 44 vars */]Process 21463 suspended) = 0
# so the pre-moved has an extra param, -iprefix=/home/nonesuch/src/toolchain4/pre-moved/bin/../lib/gcc/i686-apple-darwin11/4.2.1/ ... I wonder if I were to put my assemblers in there would they then work? let's try.

# what if gcc actually passed the right prefix to cc1plus?
# /home/nonesuch/src/toolchain4/pre-moved/bin/../libexec/gcc/i686-apple-darwin11/4.2.1/cc1plus "-iprefix" "/home/nonesuch/src/toolchain4/pre-moved/bin/../lib/gcc/i686-apple-darwin11/4.2.1/" "-isysroot" "/home/nonesuch/darwin-cross/SDKs/MacOSX10.7.sdk/" "-D__DYNAMIC__" "ndk-stack.c" "-fPIC" "-mmacosx-version-min=10.4" "-dumpbase" "ndk-stack.c" "-m32" "-mtune=core2" "-auxbase" "ndk-stack" "-D__private_extern__=extern" "-o" "/tmp/cc1hKPQX.s"
