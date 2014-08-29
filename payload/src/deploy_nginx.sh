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
sysNginxWeb="$sysNginxHtml/html"

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

printReq "Puppet: Installing nginx..."

###---
### Install nginx
###---
progInstalled="$(type -P nginx)"

if [[ "${progInstalled##*/}" != 'nginx' ]]; then
    case "$myDistro" in
        'CentOS')
            sudo puppet apply "$puppetMans/install_nginx_centos.pp"
            ;;
        'Debian')
            sudo puppet apply "$puppetMans/install_nginx_debian.pp"
            ;;
    esac
else
    printInfo "nginx is already installed."
fi


###---
### New HTML Resume
###---
printInfo "Deploying HTML Resume..."
tar xzvf "$varTargets/web_assets.tgz" -C "$sysNginxWeb/"  &> /dev/null


###---
### Message to User
###---
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
