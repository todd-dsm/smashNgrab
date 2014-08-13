#!/usr/bin/env bash
#------------------------------------------------------------------------------
#  PURPOSE: Install EPEL; the version changes per OS release. Update
#           accordingly.
#           -------------------------------------------------------------------
#  AUTHORS: Todd E Thomas
#     DATE: 2014/08/01
# MODIFIED:
#------------------------------------------------------------------------------
#set -x


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# if required environment variables not set already, something went wrong, exit
: ${backupDir?"required backup directory not set in environment"}

repoEPEL="$sysDirEtc/yum.repos.d/epel.repo"
pkgEPEL="epel-release-6-8.noarch.rpm"


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
### Install EPEL
###---
printReq "Installing EPEL if it's not already."
if [[ "$myDistro" = 'CentOS' ]]; then
    stat "$repoEPEL" &> /dev/null
    if [[ "$?" -ne '0' ]]; then
        printInfo "EPEL is not present; installing..."
        curl -o "$sysDirTmp/$pkgEPEL" "http://mirror.pnl.gov/epel/6/i386/$pkgEPEL"
        rpm -ivh "$sysDirTmp/$pkgEPEL"
        if [[ "$?" -ne '0' ]]; then
            printFStat "EPEL cannot be installed for some reason; exiting."
            exit 1
        else
            printSStat "Success: Installed EPEL."
        fi
    else
        printSStat "Success: EPEL alredy installed."
    fi
else
    printInfo "This is Debian; we don't need it. Moving on..."
fi


###---
### Update yum db
###---
#yum check-update


###---
### fin~
###---
finish
exit 0
