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


do-sed()
{
    if [ "$(uname-bt)" = "darwin" ]
    then
        sed -i '.bak' "$1" $2
        rm ${2}.bak
    else
        sed "$1" -i $2
    fi
}
