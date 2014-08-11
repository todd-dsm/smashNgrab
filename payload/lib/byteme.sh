#------------------------------------------------------------------------------
#   PUPOSE: Function: Divides by 2^10 until < 1024 and then append metric suffix
#   AUTHOR: Joe Negron - LOGIC Wizards ~ NYC
#  LICENSE: BuyMe-a-Drinkware: Dual BSD or GPL (pick one)
#    USAGE: byteMe (bytes)
# ABSTRACT: Converts a numeric parameter to a human readable format.
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
### VARIABLES
#------------------------------------------------------------------------------
declare -a METRIC=(' Bytes' 'KB' 'MB' 'GB' 'TB' 'XB' 'PB') # Array of suffixes
MAGNITUDE=0                                                # magnitude of 2^10
PRECISION="scale=1"                                        # change this numeric value to inrease decimal precision
UNITS="$(echo $1 | tr -d ‘,’)"                             # numeric arg val (in bytes) to be converted


#------------------------------------------------------------------------------
### FUNCTION
#------------------------------------------------------------------------------
function byteMe() {
# Divides by 2^10 until < 1024 and then append metric suffix
while [ ${UNITS/.*} -ge 1024 ]; do                    # compares integers (b/c no floats in bash)
    UNITS="$(echo "$PRECISION; $UNITS/1024" | bc)"    # floating point math via `bc`
        ((MAGNITUDE++))                               # increments counter for array pointer
done
echo "$UNITS${METRIC[$MAGNITUDE]}"
}
