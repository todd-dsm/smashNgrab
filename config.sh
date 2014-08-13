#!/usr/bin/env bash
#   PURPOSE: Automate the installation and configuration of an nginx web
#            server. The nginx server should:
#            a) serve requests over port 8000
#            b) serve a page with the content of the following repository:
#               https://github.com/puppetlabs/exercise-webpage.
#            Samba added for fireworks.
#            ------------------------------------------------------------------
#            Execute: ./config | tee -i /tmp/install.out
#            ------------------------------------------------------------------
#            NOTE: Only CentOS & Debian (and derivatives) supported. This is
#            all based on a structured build scenario, else more tests.
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
#     DATE:  2014/08/01


###------------------------------------------------------------------------------
### First, let's define who, where and what I am -  then make the announcement.
###------------------------------------------------------------------------------
export myName="$(basename $0)"
if [[ -z "$myName" ]]; then
    echo "Something's gone wrong, exiting."
    exit 1
else
    echo ""
    echo "Hi, my name is $myName. I'll be your installer today :-)"
fi

export myLoc='/vagrant'            # For a 'vagrant'  install'
# export myLoc="$PWD"               # For a 'standard' install'
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
CentOSRelease='/etc/centos-release'            # Supported by CentOS
DebianRelease='/etc/os-release'                # Supported by both CentOS (7) & Debian

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
progLSBRelease="$(type -P lsb_release)"
if [[ "$?" -ne '0' ]]; then
    # OK, we can do it the hard way too
    NAME="$(cat $CentOSRelease)"
    if [[ "${NAME%%\ *}" = 'CentOS' ]]; then
        export myDistro="${NAME%%\ *}"
    else
        source "$DebianRelease"
        if [[ "${NAME%%\ *}" = 'Debian' ]]; then
            export myDistro="${NAME%%\ *}"
        fi
    fi
else
    export myDistro="$(lsb_release -si)"
fi

### Now let's pull some system-specific variables...
if [[ "$myDistro" = 'Debian' ]]; then
    echo "  Importing Debian Stuff..."
    source "$instVars/vars_debian.txt"
else
    echo "  Importing CentOS Stuff..."
    source "$instVars/vars_centos.txt"
    echo ""
    echo ""
    echo ""
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


###---
### Update the OS - if it needs one
###---
"$instSrc/update_os.sh"
if [ $? -ne 0 ]; then
   infobreak $LINENO "$instSrc/update_os.sh did not exit successfully"
   exit 1
fi


###---
### Install EPEL
###---
"$instSrc/install_epel.sh"
if [ $? -ne 0 ]; then
   infobreak $LINENO "$instSrc/install_epel.sh did not exit successfully"
   exit 1
fi


###---
### Install nginx
###---
"$instSrc/deploy_nginx.sh"
if [ $? -ne 0 ]; then
    infobreak $LINENO "$instSrc/deploy_nginx.sh did not exit successfully"
    exit 1
fi


###---
### Harden Samba
###---
"$instSrc/harden_samba.sh"
if [ $? -ne 0 ]; then
    infobreak $LINENO "$instSrc/harden_samba.sh did not exit successfully"
    exit 1
fi


###---
### fin~
###---
finish
exit 0
