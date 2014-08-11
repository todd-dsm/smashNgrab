#------------------------------------------------------------------------------
# FUNCTION: Parse INI is just what it sounds like; we search a specified:
#               1) file for a
#               2) parameter that has a
#               3) value we need to verify.
#           If the value is correct, we leave the file in its current state.
#           If the value is incorrect, we
#               1) Backup the file and
#               2) Modify the specified parameter's value.
#           Given, there can be multiple parameters in a config file that may
#           need to be modified, it only takes one value to be out of place to
#           trigger the backup and modification process.
#
#  AUTHORS: Jim Browning, Todd E Thomas
#     DATE: 2012/04/10
# MODIFIED:
#------------------------------------------------------------------------------

#  Arguments:
#       Name to find
#       Value to compare
#       File name to grep
#
#  Name:Value pair can be in any of the following forms:
#       Name=Value
#       Name = Value
#       Name Value
#       Name<tab>Value
#
#  Returns $Result:
#       -1 - File does not exist or Name not in file
#        0 - Value does not match
#        1 - Value matches

grepit() {
    Result=-1
        if [ -f $3 ]; then
            local GLine=`grep ^$1 $3`
            if [ -n "$GLine" ]; then
                if [ `echo "$GLine" | awk -F " = |=| |\t" '{ print $2 }'` == $2 ]; then
                    Result=1
                else
                    Result=0
                fi
            fi
        fi
}

