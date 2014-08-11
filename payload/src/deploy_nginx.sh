#!/usr/bin/env bash
#------------------------------------------------------------------------------
#  PURPOSE: Install and configure: nginx. Update the OS if not aleady.
#           -------------------------------------------------------------------
#  AUTHORS: Todd E Thomas
#     DATE: 2014/08/01
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# if required environment variables not set already, something went wrong, exit
: ${backupDir?"required backup directory not set in environment"}

sysNginxDir="$sysDirEtc/nginx"

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

printReq "Puppet: Install nginx..."

###---
### Install nginx
###---
if [[ ! -d "$sysNginxDir" ]]; then
    sudo puppet apply "$puppetMans/install_nginx.pp"
else
    printInfo "nginx is already installed; exiting."
    exit 0
fi


###---
### Message to User
###---
printInfo ""
printInfo ""
printInfo ""

printReq "Go ahead and try it out: http://127.0.0.1:8000/"

printInfo ""
printInfo ""
printInfo ""

###---
### fin~
###---
finish
exit 0
