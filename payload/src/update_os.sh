#!/usr/bin/env bash
#  PURPOSE:  Let's get the latest updates - but only if we need them.
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
# MODIFIED:  2014/08/01


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# if required environment variables not set already, something went wrong, exit
: ${instLib?"required library directory not set in environment"}
: ${sysPackageDir?"required system file not set in environment"}


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
source "$instLib/start.sh"
source "$instLib/finish.sh"
source "$instLib/get_stats.sh"
source "$instLib/printfmsg.sh"


###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### What time is it?
###---
start
printReq "Updating OS - if we need it."


###---
### Get File Stats
###---
getStats "$sysPackageDir"

###---
### Update the OS
###---
if [[ "${fsoModTm%% *}" != "$dateHuman"  ]]; then
    printInfo "Turns out we do, grabbing the latest updates. This might take a minute..."
    if [[ "$myDistro" = 'CentOS' ]]; then
        yum -y update &> /dev/null
    else
        apt-get update &> /dev/null
    fi
else
    printInfo "Nope, we're all good, moving on..."
fi


###---
### fin~
###---
finish
