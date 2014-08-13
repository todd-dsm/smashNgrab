#!/usr/bin/env bash
#  PURPOSE:  Before we DO anything, let's record some system details.
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
# MODIFIED:  2014/08/01


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
# if required environment variables not set already, something went wrong, exit
: ${instLib?"required library directory not set in environment"}
: ${BASH_VERSION?"required BASH_VERSION not set in environment"}


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
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
### Find the Bash version
###---
printReq "Confirm the BASH version:"
printInfo "We are using BASH version: $BASH_VERSION"

### Verify it's version 4.x
if [[ "${BASH_VERSION%%.*}" != '4' ]]; then
   printStatus "Bash version is not 4.x; halting process."
   exit 1
fi


###---
### Collect some system info before we do anything
###---
printReq "We are using OS: $myDistro"


###---
### Get Network Info
###---
printReq "This is our current host and network info:"
### Host & Name Info
printInfo "Host Name:   $hostName"
printInfo "Host Arch:   $hostArch"
#printInfo "FQDN Name:   $hostFQDN"
#printInfo "Host Domain: $hostDomain"
#printInfo "Host TLD:    $hostTLD"
### Since there is no good (portable) method for this, we'll have to get dirty
printInfo "Host IP:     $IPADDR"
#printInfo "NETMASK:     $NETMASK"
#printInfo "GATEWAY:     $GATEWAY"
dns1Resolver="$(grep nameserver $sysResolver)"
printInfo "DNS Servers: ${dns1Resolver##*\ }"


###---------------------------------------------------------------------------
### Setup some directories for long-term maintence.
### If there is no admin directory then make one
###---
printReq "Creating some directories for the long-term:"
if [[ ! -d "$adminDir" ]]; then
    mkdir -p "$adminDir"
fi

printInfo "The admin  directory is here: $adminDir"


###---
### If there is no backup directory then make one
###---
if [[ ! -d "$backupDir" ]]; then
    mkdir -p "$backupDir"
fi

printInfo "The backup directory is here: $backupDir"


###---
### If there is no logs directory then make one
###---
if [[ ! -d "$logDir" ]]; then
    mkdir -p "$logDir"
fi

printInfo "The logs   directory is here: $logDir"


printSStat "Success: Completed collecting system info."

###---
### fin~
###---
finish
