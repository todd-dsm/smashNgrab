#!/usr/bin/env bash
#  PURPOSE:  Harden Samba: Restrict Samba to only:
#               a) Listen on the localhost segment 127.
#               b) Use its own password table
#               c) Use encrypted passwords
#               d) Use defined password table
#               e) Allow permitted users: none ()
#               f)
#            ------------------------------------------------------------------
#  CREATED:  2013/01/14
#   AUTHOR:  Todd E Thomas
# MODIFIED:
#set -x

###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
paramsFile="$varLists/samba_populate.list"
targetSambaConfig="$varTargets/smb.conf"


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
source "$instLib/finish.sh"
source "$instLib/get_stats.sh"
source "$instLib/printfmsg.sh"
source "$instLib/start.sh"

displayConfig() {
    egrep -v '^(#|.*#|;|*$)' "$1" | sed '/^\s*$/d'
}

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
### What time is it?
###---
start

printReq "Harnening Samba..."

###---
### Ensure the program is installed
###---
progInstalled="$(type -P smbd)"

if [[ "${progInstalled##*/}" != 'smbd' ]]; then
    case "$myDistro" in
        'CentOS')
            yum -y  install samba
            ;;
        'Debian')
            apt-get install samba
            ;;
    esac
else
    printSStat "Samba is already installed."
fi


###---
### Record the permissions on the file
###---
getStats "$sysSambaConfig"


###---
### Backup the file
###---
cp -p "$sysSambaConfig" "$backupDir"


###---
### Display configuration and normalize the file
###---
displayConfig "$backupDir/${sysSambaConfig##*/}" > "$sysSambaConfig"
printInfo ""
printInfo ""


###---
### Diff the file and update it to the required specification.
###---
diff "$sysSambaConfig" "$targetSambaConfig"  >/dev/null
if [[ "$?" -ne '0' ]]; then
    printInfo "The Samba configuration file does not meet the specification."
    printInfo "Adding new parameters:"
    # Read parameters into a while loop
    # URL: http://goo.gl/sehtX
    while IFS='\t' read -r confLine; do
        [[ "$confLine" = \#* ]] && continue
        # Using BASH PE (parameter expansion)
        # URL: http://goo.gl/stZWt
        strSrch="${confLine%% = *}"
        grep "$strSrch" "$sysSambaConfig"
        if [[ "$?" -ne '0' ]]; then
            printInfo "$confLine"
            sed -i "/security \= user/a\ $confLine" "$sysSambaConfig"
        else
            printSStat "$confLine is already set in the configuration."
        fi
    done < "$paramsFile"
else
    printInfo "Samba configuration file meets the specification."
fi


###---
### Ensure correct permissions and ownership
###---
### Insure permissions are correct on the new file
printInfo ""
printInfo "Re-applying original permissions to the file."
chmod "$fsoPerms" "$sysSambaConfig"


###---
### Ensure correct ownership
###---
printInfo "Re-applying original user and group ownership to the file."
chown "$fsoOwner:$fsoGroup" "$sysSambaConfig"


###---
### After: Display configuration for reporting
###---
printInfo ""
printSStat "Samba is now HARD:"
displayConfig "$sysSambaConfig"


###---
### Reset Test
###---
cp -p "$backupDir/smb.conf" "$sysSambaConfig"


###---
### fin~
###---
finish
exit 0
