#!/usr/bin/env bash
#------------------------------------------------------------------------------
#  PURPOSE: Install EPEL
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
printReq "Installing EPEL if it doesn't exist..."
stat "$repoEPEL" 2>/dev/null
if [[ $? -ne 0 ]]; then
    curl -o "$sysDirTmp/$pkgEPEL" "http://mirror.pnl.gov/epel/6/i386/$pkgEPEL"
    rpm -ivh "$sysDirTmp/$pkgEPEL"
fi

printSStatus "Success: Installed EPEL."

###---
### fin~
###---
finish
exit 0
