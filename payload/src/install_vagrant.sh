#!/usr/bin/env bash
#------------------------------------------------------------------------------
#  PURPOSE: Install Vagrant
#           -------------------------------------------------------------------
#  AUTHORS: Todd E Thomas
#     DATE: 2014/08/29
# MODIFIED:
#------------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
#repoVbox="$sysDirEtc/yum.repos.d/virtualbox.repo"
pkgDlURL='https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.3_x86_64.rpm'
pkgNameVers="${pkgDlURL##*/}"
#depTest='gcc'
appTest='vagrant'
vagrantHome="$HOME/vbox/vagrant"


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
source "$instLib/start.sh"
source "$instLib/finish.sh"
source "$instLib/printfmsg.sh"
source "$instLib/get_stats.sh"


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### What time is it?
###---
start

printReq "Install Vagrant"

###---
### Pull the package down
###---
printReq "Download the Vagrant package..."
if [[ "$myDistro" = 'Fedora' ]]; then
    progExist="$(type -P "$appTest")"
    if [[ -z "$progExist" ]]; then
        printInfo "Vagrant is not installed; pulling it down..."
        wget -q  -P "$sysDirTmp" "$pkgDlURL"
        getStats "$sysDirTmp/$pkgNameVers"
        if [[ "$?" -ne '0' ]]; then
            printFStat "Vagrant cannot be downloaded for some reason; exiting."
            exit 1
        else
            printSStat "Success: Vagrant package has been pulled down."
        fi
    else
        printSStat "Success: We already had the Vagrant package."
    fi
fi


###---
#### Install Package
###---
printReq "Now we can install Vagrant..."
#progExist="$(type -P "$appTest")"
if [[ -z "$progExist" ]]; then
    rpm -ivh "$sysDirTmp/$pkgNameVers"
    if [[ "$?" -ne '0' ]]; then
        printFStat "Vagrant install is erroring; exiting."
        exit 1
    else
        printSStat "Success: Vagrant is installed."
    fi
else
    printSStat "Success: Vagrant was already installed."
fi

set -x
###---
### Define Vagrant's home
###---
cat >> "$myBashRC" << EOF
export VAGRANT_HOME="\$HOME/vbox/vagrant"
EOF
set +x

# Source it in
source "$myBashRC"


###---
### fin~
###---
finish
exit 0
