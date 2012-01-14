#!/bin/bash

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

