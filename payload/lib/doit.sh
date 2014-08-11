#------------------------------------------------------------------------------
# FUNCTION: Extremely useful when used in conjunction with checkerrors(). This
#						function executes a shell command and if not successful, exits the
#						program.
#							$1 = line number this function was called from
#							$2 = shell command to execute
#							CANNOT BE USED FOR: sed commands, and a few others.
#  AUTHORS: Todd E Thomas
#     DATE: 2012/01/08
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------


###----------------------------------------------------------------------------
### FUNCTION
###----------------------------------------------------------------------------
doit()	{
DO_COMMAND=""
    line_num="$1"               # set to the first arg, which is line number of who called us
    cmd="$2"                    # set to the second arg, which is command to execute

    DO_COMMAND="$(cmd 2>&1)"    # back single quote shell built-in to execute everything inside of it
    errcode="$?"                # set errcode to exit status DO_COMMAND

    # if errcode doesn't equal 0, print message, exit program
    if [ "$errcode" -ne '0' ]; then
        echo "$0: exiting... failed to execute $cmd from line $line_num"
        echo "$0: error message=$DO_COMMAND"
        exit "$errcode"
    else
        # if we got here, then no errors occured, return true
        echo "$0: OUTPUT: $DO_COMMAND"
        return 0
  fi
}
