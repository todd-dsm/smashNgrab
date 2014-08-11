#------------------------------------------------------------------------------
# FUNCTION: print a formatted message in a consistent format.
#  AUTHORS: Todd E Thomas
#     DATE: 2013/10/19
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
valDATE="$(date +%F\ %r)"
myFileName="$(basename $0)"
bold=$(tput bold)
green=$(tput setaf 2)
red=$(tput setaf 1)
clear=$(tput sgr0)


###----------------------------------------------------------------------------
### FUNCTION
###----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# for debugging purposes. Generally used during development.
#------------------------------------------------------------------------------
# Print Requirement
printReq()    {
    printf '\n%s\n' "$bold$1$clear"
}

# Print 1 line of info
print1Line()    {
    printf '%s\n\n' "$1"
}

# Print Info
printInfo()    {
    printf '%s\n' "  $1"
}

# Print final Success status
printSStat()    {
    printf '%s\n\n' "$green  $1$clear"
}


# Print final Failure status
printFStat()    {
    printf '%s\n\n' "$red  $1$clear"
}
