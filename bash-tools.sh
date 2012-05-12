#!/bin/bash

# Copyright (c) 2008,2009 iphonedevlinux <iphonedevlinux@googlemail.com>
# Copyright (c) 2008, 2009 m4dm4n <m4dm4n@gmail.com>
# Copyright (c) 2012, Ray Donnelly <mingw.android@gmail.com>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Updated by Denis Froschauer Jan 30, 2011

# Compare two version strings and return a string indicating whether the first version number
# is newer, older or equal to the second. This is quite dumb, but it works.
vercmp() {
	V1=`echo "$1" | sed -e 's/[^0-9]//g' | LANG=C awk '{ printf "%0.10f", "0."$0 }'`
	V2=`echo "$2" | sed -e 's/[^0-9]//g' | LANG=C awk '{ printf "%0.10f", "0."$0 }'`
	[[ $V1 > $V2 ]] && echo "newer"
	[[ $V1 == $V2 ]] && echo "equal"
	[[ $V1 < $V2 ]] && echo "older"
}

uname-bt() {
	local _UNAME=$(uname -s)
	case "$_UNAME" in
	 "MINGW"*)
		_UNAME=Windows
		;;
	esac
	echo $_UNAME
}

download() {
	local _LFNAME=$2
	if [[ -z $_LFNAME ]] ; then
		_LFNAME=$(basename $1)
	fi
	if [[ ! -f $_LFNAME ]] ; then
		if [[ "$(uname-bt)" == "Darwin" ]] ; then
			curl -S -L -O $1 -o $_LFNAME
		else
			wget -c $1 -O $_LFNAME
		fi
	fi

	if [[ -f $_LFNAME ]] ; then
		return 0
	fi

	return 1
}

downloadStdout() {
	if [[ "$(uname-bt)" == "Darwin" ]] ; then
		curl -S -L $1
	else
		wget -c $1 -O -
	fi
}

# Beautified echo commands
cecho() {
	if [[ "$(uname-bt)" == "Windows" ]] ; then
	    local _COLOR=$1
	    shift
	    case $_COLOR in
		    black)	printf "\033[30m$*\033[0;37;40m\n";;
		    yellow)	printf "\033[33m$*\033[0;37;40m\n";;
		    red)	printf "\033[31m$*\033[0;37;40m\n";;
		    green)	printf "\033[32m$*\033[0;37;40m\n";;
		    blue)	printf "\033[34m$*\033[0;37;40m\n";;
		    purple)	printf "\033[35m$*\033[0;37;40m\n";;
		    cyan)	printf "\033[36m$*\033[0;37;40m\n";;
		    grey)	printf "\033[37m$*\033[0;37;40m\n";;
		    white)	printf "\033[32m$*\033[0;37;40m\n";;
		    bold)	printf "\033[32m$*\033[0;37;40m\n";;
		    *)		printf "\033[32m$*\033[0;37;40m\n";;
	    esac
	else
		while [[ $# > 1 ]]; do
			case $1 in
				red)	echo -n "$(tput setaf 1)";;
				green)	echo -n "$(tput setaf 2)";;
				blue)	echo -n "$(tput setaf 3)";;
				purple)	echo -n "$(tput setaf 4)";;
				cyan)	echo -n "$(tput setaf 5)";;
				grey)	echo -n "$(tput setaf 6)";;
				white)	echo -n "$(tput setaf 7)";;
				bold)	echo -n "$(tput bold)";;
				*) 	break;;
			esac
			shift
		done
		echo "$*$(tput sgr0)"
	fi
}

# Shorthand method of asking a yes or no question with a default answer
confirm() {
	local YES="Y"
	local NO="n"
	if [ "$1" == "-N" ]; then
		NO="N"
		YES="y"
		shift
	fi
	read -p "$* [${YES}/${NO}] "
	if [ "$REPLY" == "no" ] || [ "$REPLY" == "n" ] || ([ "$NO" == "N" ] && [ -z "$REPLY" ] ); then
		return 1
	fi
	if [ "$REPLY" == "yes" ] || [ "$REPLY" == "y" ] || ([ "$YES" == "Y" ] && [ -z "$REPLY" ] ); then
		return 0
	fi
}

error() {
	cecho red $*
}

message_status() {
	cecho green $*
}

message_action() {
	cecho blue $*
}

# bsd sed doesn't do newlines the same way as gnu sed.
do-sed()
{
    if [[ "$(uname-bt)" = "Darwin" ]]
    then
	if [[ ! $(which gsed) ]]
	then
	    sed -i '.bak' "$1" $2
	    rm ${2}.bak
	else
	    gsed "$1" -i $2
	fi
    else
        sed "$1" -i $2
    fi
}

# Comments out (using C comments) blocks of code in $1, delimited by $2 and $3, writing result back to $1
# This is to be used when tag for uniquely identifying the block appears at the start of the block.
# One problem with doing it using C comments is that you end up with comments within comments, so either
# provide an option for using C++ comments or delete the comments within comments.
comment-out-fwd-c()
{
    local _INFILE="$1"
    local _START="$2"
    local _END="$3"
    local _REV="$4"
    local _TMPFILEF=$(tempfile)
    local _OUTFILE=$_INFILE
    local _CSTART="/*"
    local _CEND="*/"
    if [[ "$_REV" = "1" ]] ; then
        _CSTART="*/"
        _CEND="/*"
    fi
    awk -vSTARTV="$_START" -vENDV="$_END" -vCSTART="$_CSTART" -vCEND="$_CEND" '
BEGIN { inblock=0; }
{if ( inblock==1 ) {
if ( match($0,ENDV) ) {
   inblock=0;
   print;
   print(CEND);
  }
  else {
   print;
  }
 }
else if ( inblock==0 ) {
if ( match($0,STARTV) ) {
   inblock=1;
   print(CSTART);
   print;
  }
  else {
   print;
  }
 }
}
END {} ' < $_INFILE > $_TMPFILEF
    mv $_TMPFILEF $_OUTFILE
}

comment-out-fwd-cxx()
{
    local _INFILE="$1"
    local _START="$2"
    local _END="$3"
    local _REV="$4"
    local _TMPFILEF=$(tempfile)
    local _OUTFILE=$_INFILE
    local _CSTART="/*"
    local _CEND="*/"
    if [[ "$_REV" = "1" ]] ; then
        _CSTART="*/"
        _CEND="/*"
    fi
    awk -vSTARTV="$_START" -vENDV="$_END" -vCSTART="$_CSTART" -vCEND="$_CEND" '
BEGIN { inblock=0; }
{if ( inblock==1 ) {
if ( match($0,ENDV) ) {
   inblock=0;
   print("// " $0);
  }
  else {
   print("// " $0);
  }
 }
else if ( inblock==0 ) {
if ( match($0,STARTV) ) {
   inblock=1;
   print("// " $0);
  }
  else {
   print;
  }
 }
}
END {} ' < $_INFILE > $_TMPFILEF
    mv $_TMPFILEF $_OUTFILE
}

# Comments out (using C comments) blocks of code in $1, delimited by $2 and $3, writing result back to $1.
# This is to be used when tag for uniquely identifying the block appears at the end of the block.
# For example:
# "typedef union { some\nstuff\n } TAG;", where
# $1 is "typedef union" and $2 is "} TAG;"
# Works by using tac to reverse the input file, calling comment-out-fwd (with swapped delimiters)
# and then calling tac once more to re-reverse the result of that.
comment-out-rev()
{
    echo "Top of comment-out-rev"
    echo "PWD is $PWD"
    local _INFILE="$1"
    local _START="$2"
    local _END="$3"
    local _OUTFILE="$4"
    local _REVTMPFILE=$(tempfile)
    local _TMPFILER=$(tempfile)
    if [[ $_OUTFILE = "" ]] ; then
        _OUTFILE=$_INFILE
    fi
    cat $_INFILE | tac > $_REVTMPFILE
    $(comment-out-fwd-cxx "$_REVTMPFILE" "$_END" "$_START" "1")
    cat $_REVTMPFILE | tac > $_OUTFILE
}

# $1 == folder to compress
# $2 == dirname with prefix for filename of output (i.e. without extensions)
# $3 == Either xz, bz2, 7z, Windows, Linux, Darwin or nothing
# Returns the name of the compressed file.
compress-folder() {

    if [[ ! -d $1 ]] ; then
	echo ""
	return 1
    fi

    local _OUTFILE=$2

    if [[ "$(basename $_OUTFILE)" = "$_OUTFILE" ]] ; then
	_OUTFILE=$PWD/$_OUTFILE
    fi

    local _ARCFMT=$3

    if [[ -z "$_ARCFMT" ]] ; then
	_ARCFMT=$(uname-bt)
    fi

    if [[ "$_ARCFMT" = "Windows" ]] ; then
	_ARCFMT="7z"
    elif [[ "$_ARCFMT" = "Darwin" ]] ; then
	# I'd prefer to use xar (but see below) or tar.xz, but can't, because:
	# 1. Neither lzma nor xz are compiled into the Darwin version.
	# 2. It compresses each file individually.
	# 3. xz doesn't exist by default on Darwin - neither does 7z, but I've
	#    put a binary up on http://code.google.com/p/mingw-and-ndk/
	# ..meaning with xar --compression-args=9 -cjf, my Darwin cross
	#   compilers end up being ~71MB compared to ~19MB as a 7z
	#   which is too vast a difference for me to ignore.
	_ARCFMT="7z"
    else
	_ARCFMT="xz"
    fi

    pushd $1 > /dev/null
    if [[ "$_ARCFMT" == "xz" ]] || [[ "$_ARCFMT" == "bz2" ]] ; then
	# Usually, sorting by the filename part of the full path yields better compression.
	find -type f -exec sh -c "echo \$(basename {}; echo {} ) " \; | sort | awk '{print $2;}' > /tmp/$$.txt
	tar -c --files-from=/tmp/$$.txt -f /tmp/$(basename $2).tar
    else
	find . -mindepth 1 -maxdepth 1 -type d > /tmp/$$.txt
    fi

    if [[ "$_ARCFMT" == "xz" ]] ; then
	xz -z -9 -e -c -q /tmp/$(basename $2).tar > $_OUTFILE.tar.xz
	echo $_OUTFILE.tar.xz
    elif [[ "$_ARCFMT" == "bz2" ]] ; then
	bzip2 -z -9 -c -q /tmp/$(basename $2).tar > $_OUTFILE.tar.bz2
	echo $_OUTFILE.tar.bz2
    elif [[ "$_ARCFMT" == "xar" ]] ; then
	# I'd like to use xz or lzma, but xar -caf results in "lzma support not compiled in."
	xar --compression-args=9 -cjf $_OUTFILE.xar $(cat /tmp/$$.txt)
	echo $_OUTFILE.xar
    else
	7za a -mx=9 $_OUTFILE.7z $(cat /tmp/$$.txt) > /dev/null
	echo $_OUTFILE.7z
    fi
    popd > /dev/null
    return 0
}
