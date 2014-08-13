#------------------------------------------------------------------------------
# FUNCTION: Collect some Octal Permissions, Owner and Group prior to any
#           changes to files or directories.
#  AUTHORS: Todd E Thomas
#     DATE: 2012/10/14
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------


###----------------------------------------------------------------------------
### FUNCTION
###----------------------------------------------------------------------------
getStats()  {
    stat "$1"  &> /dev/null
    if [[ "$?" -ne '0' ]]; then
        printInfo "What file?! There's no file!"
	    return 1
    else
	    fsoPerms="$(stat -c '%a' $1 2>/dev/null)"
        fsoOwner="$(stat -c '%U' $1 2>/dev/null)"
        fsoGroup="$(stat -c '%G' $1 2>/dev/null)"
        fsoModTm="$(stat -c '%y' $1 2>/dev/null)"
    fi
}
