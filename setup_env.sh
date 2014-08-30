#!/usr/bin/env bash
#   PURPOSE: Setup a base environment for virtualization.
#            ------------------------------------------------------------------
#            Execute: ./setup_env.sh | tee -i /tmp/setup.out
#            ------------------------------------------------------------------
#            NOTE: Fedora only - so far.
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
#     DATE:  2014/08/29
set -h -o errtrace


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

#export myLoc='/vagrant'            # For a 'vagrant'  install'
export myLoc="$PWD"               # For a 'standard' install'
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
FedoraRelease='/etc/os-release'                # Supported by modern OSs

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
    source "$FedoraRelease"
    if [[ "${NAME%%\ *}" = 'Fedora' ]]; then
        export myDistro="${NAME%%\ *}"
    else
        echo "Something's gone wrong, exiting."
        exit 1
    fi
else
    export myDistro="$(lsb_release -si)"
fi


### Now let's pull some system-specific variables...
if [[ "$myDistro" = 'Fedora' ]]; then
    echo "  Importing Fedora Stuff..."
    source "$instVars/vars_fedora.txt"
else
    echo "  Houston, we have a problem..."
fi
echo ""
echo ""
echo ""


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
### Script
###---
"$instSrc/install_vbox.sh"
if [ "$?" -ne '0' ]; then
    infobreak $LINENO "$instSrc/install_vbox.sh did not exit successfully"
    exit 1
fi


###---
### Script
###---
"$instSrc/install_vagrant.sh"
if [ "$?" -ne '0' ]; then
    infobreak $LINENO "$instSrc/install_vagrant.sh did not exit successfully"
    exit 1
fi


###---
### Parting Shot
###---
printReq "REVIEW:"
printSStat "Installed and configured VirtualBox."
printSStat "Installed and configured Vagrant."
printInfo ""
printInfo ""
printInfo ""


###---
### fin~
###---
finish
exit 0
