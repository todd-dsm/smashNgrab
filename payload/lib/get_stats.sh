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
    stat "$pathFile" &> /dev/null
    if [[ "$?" -ne '0' ]]; then
	    return 1
    else
	    fsoPerms="$(stat -c '%a' $pathFile 2>/dev/null)"
        fsoOwner="$(stat -c '%U' $pathFile 2>/dev/null)"
        fsoGroup="$(stat -c '%G' $pathFile 2>/dev/null)"
        fsoModTm="$(stat -c '%y' $pathFile 2>/dev/null)"
    fi
}
