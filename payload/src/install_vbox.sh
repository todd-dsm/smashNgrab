#!/usr/bin/env bash
#------------------------------------------------------------------------------
#  PURPOSE: Install VirtualBox
#           -------------------------------------------------------------------
#  AUTHORS: Todd E Thomas
#     DATE: 2014/08/29
# MODIFIED:
#------------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
repoVbox="$sysDirEtc/yum.repos.d/virtualbox.repo"
urlVbox='http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo'
pkgVbox="epel-release-6-8.noarch.rpm"
depTest='gcc'
appTest='VBoxManage'
vboxHome="$vmHome/vbox"


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


###---
### Install
###---
printReq "Install VirtualBox..."
if [[ "$myDistro" = 'Fedora' ]]; then
    getStats "$repoVbox" &> /dev/null
    if [[ "$?" -ne '0' ]]; then
        printInfo "The VirtualBox repo is not present; pulling it down..."
        printInfo "Importing key..."
        sudo rpm --import http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc
        sudo curl -o "$repoVbox" "$urlVbox"
        #echo "curl -o $repoVbox $urlVbox"
        getStats "$repoVbox"
        if [[ "$?" -ne '0' ]]; then
            printFStat "VirtualBox cannot be installed for some reason; exiting."
            exit 1
        fi
    else
        printSStat "Success: VirtualBox repo is already installed."
    fi
fi


###---
### Install Dependencies
###---
printReq "First we need to install VirtualBox dependencies..."
progExist="$(type -P "$depTest")"
if [[ -z "$progExist" ]]; then
    yum -y install dkms kernel-headers gcc
    if [[ "$?" -ne '0' ]]; then
        printFStat "Dependencies are not available; exiting."
        exit 1
    fi
else
    printSStat "Success: Dependencies already installed."
fi


###---
#### Install Package
###---
printReq "Now we can install VirtualBox..."
progExist="$(type -P "$appTest")"
if [[ -z "$progExist" ]]; then
    yum -y install VirtualBox-4.3
    ###---
    ### Build kernel modules
    ###---
    sudo /etc/init.d/vboxdrv setup
    ###---
    ### Install Guest Extensions
    ###---
    printReq "VirtualBox Guests need the Extension Pack"
    ### Let's go shopping
    vboxVersion="$(VBoxManage -v)"
    version=$(echo $vboxVersion | cut -d 'r' -f 1)
    revision=$(echo $vboxVersion | cut -d 'r' -f 2)
    file="Oracle_VM_VirtualBox_Extension_Pack-$version-$revision.vbox-extpack"
    ### Go get that package:
    printInfo "Downloading and installing the extension pack..."
    wget -P "$sysDirTmp/" "http://download.virtualbox.org/virtualbox/$version/$file" &> /dev/null
    sudo VBoxManage extpack install "/tmp/$file" --replace
    printInfo ""
    printInfo ""
    if [[ "$?" -ne '0' ]]; then
        printFStat "VirtualBox is not available; exiting."
        exit 1
    fi
else
    printSStat "Success: VirtualBox already installed."
fi


###---
### Tell VirtualBox where to fine the kernel headers
###---
grep 'KERN_DIR' "$myBashRC"
if [[ "$?" -ne '0' ]]; then
    printInfo "Telling VirtualBox where the kernel headers are located..."
cat >> "$myBashRC" << EOF
export KERN_DIR="/usr/src/kernels/\$(uname -r)"
EOF
    source "$myBashRC"
else
    printSStat "VirtualBox knows where the kernel headers are."
fi


###---
### Set some preferences
###---
VBoxManage setproperty machinefolder "$vboxHome"


printSStat "VirtualBox is ready to go."
printInfo ""
printInfo ""


###---
### fin~
###---
finish
exit 0
