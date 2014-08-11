#!/usr/bin/env bash
#   PURPOSE: Automate the installation and configuration of an nginx web
#            server. The nginx server should:
#            a) serve requests over port 8000
#            b) serve a page with the content of the following repository:
#               https://github.com/puppetlabs/exercise-webpage.
#            ------------------------------------------------------------------
#            Execute: ./bootstrap.sh | tee /tmp/install.out
#            ------------------------------------------------------------------
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
#     DATE:  2014/08/01


###---
### First, let's define who and where I am then make the announcement
###---
export myName="$(basename $0)"
if [[ -z "$myName" ]]; then
    echo "Something's gone wrong, exiting."
    exit 1
else
    echo ""
    echo "Hi, my name is $myName. I'll be your installer today :-)"
fi

export myLoc="$PWD"
if [[ ! -d "$myLoc/payload" ]]; then
    echo "Something's gone wrong, exiting."
    exit 1
else
    echo "We will be executing from $myLoc"
fi


###------------------------------------------------------------------------------
### VARIABLES
###------------------------------------------------------------------------------
### Pull Global Vaiables
###---
workVars="$myLoc/payload/var/vars_global.txt"
if [[ -f "$workVars" ]]; then
    echo "First, let's pull in the Global Vaiables..."
    echo ""
    source "$workVars"
else
    echo "Something's gone wrong, exiting."
    exit 1
fi

###---
### Define Distro
###---
export myDistro="$(lsb_release -si)"

### Now let's pull some system-specific variables...
if [[ "$myDistro" = 'Debian' ]]; then
    echo "  Importing Debian Stuff..."
    source "$instVars/vars_debian.txt"
else
    echo "  Importing CentOS Stuff..."
    source "$instVars/vars_centos.txt"
fi


###------------------------------------------------------------------------------
### FUNCTIONS
###------------------------------------------------------------------------------
source "$instLib/start.sh"
source "$instLib/finish.sh"
source "$instLib/printfmsg.sh"


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### What time is it?
###---
start


###---
### Lets collect some information
###---
"$instSrc/collect_system_info.sh"
if [ $? -ne 0 ]; then
	infobreak $LINENO "$instSrc/collect_system_info.sh did not exit successfully"
	exit 1
fi

exit

###---
### Update the OS - if it needs one
###---
#"$instSrc/update_os.sh"
#if [ $? -ne 0 ]; then
#	infobreak $LINENO "$instSrc/update_os.sh did not exit successfully"
#	exit 1
#fi


###---
### Install nginx
###---
"$instSrc/deploy_nginx.sh"
if [ $? -ne 0 ]; then
	infobreak $LINENO "$instSrc/deploy_nginx.sh did not exit successfully"
	exit 1
fi


###---
### fin~
###---
finish
