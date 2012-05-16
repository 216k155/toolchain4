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

uname_bt() {
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
		if [[ "$(uname_bt)" == "Darwin" ]] ; then
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
	if [[ "$(uname_bt)" == "Darwin" ]] ; then
		curl -S -L $1
	else
		wget -c $1 -O -
	fi
}

# Beautified echo commands
cecho() {
	if [[ "$(uname_bt)" == "Windows" ]] ; then
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
do_sed()
{
    if [[ "$(uname_bt)" = "Darwin" ]]
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
comment_out_fwd_c()
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

comment_out_fwd_cxx()
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
comment_out_rev()
{
    echo "Top of comment_out_rev"
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
    $(comment_out_fwd_cxx "$_REVTMPFILE" "$_END" "$_START" "1")
    cat $_REVTMPFILE | tac > $_OUTFILE
}

# http://stackoverflow.com/questions/6973088/longest_common_prefix-of-two-strings-in-bash
longest_common_prefix () {
  local prefix= n
  ## Truncate the two strings to the minimum of their lengths
  if [[ ${#1} -gt ${#2} ]]; then
    set -- "${1:0:${#2}}" "$2"
  else
    set -- "$1" "${2:0:${#1}}"
  fi
  ## Binary search for the first differing character, accumulating the common prefix
  while [[ ${#1} -gt 1 ]]; do
    n=$(((${#1}+1)/2))
    if [[ ${1:0:$n} == ${2:0:$n} ]]; then
      prefix=$prefix${1:0:$n}
      set -- "${1:$n}" "${2:$n}"
    else
      set -- "${1:0:$n}" "${2:0:$n}"
    fi
  done
  ## Add the one remaining character, if common
  if [[ $1 = $2 ]]; then prefix=$prefix$1; fi
  printf %s "$prefix"
}

longest_common_prefix_n () {
    local _ACCUM=""
    local _PREFIXES="$1"
    for PREFIX in $_PREFIXES
    do
        if [[ -z $_ACCUM ]] ; then
            _ACCUM=$PREFIX
        else
            _ACCUM=$(longest_common_prefix $_ACCUM $PREFIX)
        fi
    done
    printf %s "$_ACCUM"
}

archive_type_for_host() {
    local _HOST=$1
    if [[ -z $_HOST ]] ; then
        HOST=$(uname_bt)
    fi

    if [[ "$HOST" = "Linux" ]] ; then
	echo tar.xz
	return 0
    elif [[ "$HOST" = "Windows" ]] ; then
	echo 7z
	return 0
    else
	echo 7z
	return 0
    fi
}

# $1 == folder(s) to compress (quoted, must all be relative to the working directory)
# $2 == dirname with prefix for filename of output (i.e. without extensions)
# $3 == Either xz, bz2, 7z, Windows, Linux, Darwin or nothing
# Returns the name of the compressed file.
compress_folders() {

    local _FOLDERS="$1"
    local _COMMONPREFIX=""
    local _FOLDERSABS

    # Special case: if a single folder is passed in and it ends with a ., then
    # we don't want the actual folder itself to appear in the archive.
    if [[ ${#_FOLDERS[@]} = 1 ]] && [[ $(basename "$1") = . ]] ; then
        pushd $1 > /dev/null
        _COMMONPREFIX=$PWD
        popd > /dev/null
	_RELFOLDERS=$(basename "$_FOLDERSABS")
    else
        for FOLDER in $_FOLDERS
        do
            if [[ ! -d $FOLDER ]] ; then
                echo "Folder $FOLDER doesn't exist"
                return 1
            fi
            pushd $FOLDER > /dev/null
            _FOLDERSABS="$_FOLDERSABS "$PWD
            popd > /dev/null
        done
    
        local _COMMONPREFIX=$(longest_common_prefix_n "$_FOLDERSABS")
        echo _COMMONPREFIX is $_COMMONPREFIX
    
        if [[ ${#_FOLDERSABS[@]} = 1 ]] ; then
            _COMMONPREFIX=$(dirname "$_FOLDERSABS")
            _RELFOLDERS=$(basename "$_FOLDERSABS")
        else
            local _RELFOLDERS=
            for FOLDER in $_FOLDERSABS
            do
                _RELFOLDERS="$_RELFOLDERS "${FOLDER#$_COMMONPREFIX}
            done
        fi
    fi

    local _OUTFILE=$2
    if [[ "$(basename $_OUTFILE)" = "$_OUTFILE" ]] ; then
	_OUTFILE=$PWD/$_OUTFILE
    fi

    local _ARCFMT=$3

    if [[ -z "$_ARCFMT" ]] ; then
	_ARCFMT=$(uname_bt)
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
    elif [[ "$_ARCFMT" = "Linux" ]] ; then
	_ARCFMT="xz"
    fi

    pushd $_COMMONPREFIX > /dev/null
#    pushd $1 > /dev/null
    if [[ "$_ARCFMT" == "7z" ]] ; then
        find $_RELFOLDERS -maxdepth 1 -mindepth 0 \( ! -path "*.git*" \) -exec sh -c "exec echo {} " \; > /tmp/$$.txt
    else
        # Usually, sorting by the filename part of the full path yields better compression.
        find $_RELFOLDERS -type f \( ! -path "*.git*" \) -exec sh -c "echo \$(basename {}; echo {} ) " \; | sort | awk '{print $2;}' > /tmp/$$.txt
        tar -c --files-from=/tmp/$$.txt -f /tmp/$(basename $2).tar
    fi

    if [[ "$_ARCFMT" == "xz" ]] ; then
        _ARCEXT=".tar.xz"
    elif [[ "$_ARCFMT" == "bz2" ]] ; then
        _ARCEXT=".tar.bz2"
    else
        _ARCEXT="."$_ARCFMT
    fi

    if [[ -f $_OUTFILE$_ARCEXT ]] ; then
        rm -rf $_OUTFILE$_ARCEXT > /dev/null
    fi

    if [[ "$_ARCFMT" == "xz" ]] ; then
        _ARCEXT=".tar.xz"
	xz -z -9 -e -c -q /tmp/$(basename $2).tar > $_OUTFILE$_ARCEXT
    elif [[ "$_ARCFMT" == "bz2" ]] ; then
        _ARCEXT=".tar.bz2"
	bzip2 -z -9 -c -q /tmp/$(basename $2).tar > $_OUTFILE$_ARCEXT
    elif [[ "$_ARCFMT" == "xar" ]] ; then
	# I'd like to use xz or lzma, but xar -caf results in "lzma support not compiled in."
	xar --compression-args=9 -cjf $_OUTFILE$_ARCEXT $(cat /tmp/$$.txt)
    else
	7za a -mx=9 $_OUTFILE$_ARCEXT $(cat /tmp/$$.txt) > /dev/null
    fi
    echo $_OUTFILE$_ARCEXT
    popd > /dev/null
    return 0
}
