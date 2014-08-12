#!/usr/bin/env bash
#   PURPOSE: Foundation to select 'tdsh', 'stig', or 'scsem' as a hardening
#            standard for installation.
#            ------------------------------------------------------------------
#            Execute: ./install.sh --standard scsem -v 2.86 --type delta --loglevel 1
#            ------------------------------------------------------------------
#            NOTES:
#            1) The version is a number but we treat it like an string. We're
#            just comparing strings here, not doing math.
#            2) All below printfs were converted to functions after this vers.
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
#     DATE:  2013/01/11


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
testMode=0                  # initialize to false until we determine if in test mode or not
InstallType="TEST"          # always initialize to TEST to prevent accidental overwrite in root
instDir="$HOME/projects/hard_linux/payload"
exeDir="$instDir/sys"

hardVersion="0.01"
loglevel=0


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
### Help and Usage output
###---
show_help()     {
    printf '%b\n' "\nUsage: $0 --help to see this message.\n"
    printf '%b\n' "SPECIFY IF YOU WANT TO RUN IN TEST MODE:"
    printf '%b\n' "-t | --testmode\n"
    printf '%b\n' "SPECIFY A STANDARD:"
    printf '%b\n' "-s | --standard with an argument: 'stig', 'scsem', or 'tdsh'."
    printf '%b\n' "\tEG: $0 --standard scsem, or"
    printf '%b\n' "\tEG: $0 -s scsem\n"
    printf '%b\n' "SPECIFY A VERSION:"
    printf '%b\n' "-v | --version with an argument: 'version_number'"
    printf '%b\n' "\tA version number will be specified for all installs but will be used primarily for reporting.\n"
    printf '%b\n' "SPECIFY A LOGLEVEL:"
    printf '%b\n' "-l | --loglevel with an argument: zero (0) or one (1)"
    printf '%b\n' "\t0 for standard logging."
    printf '%b\n' "\t1 for debug output."
    printf '%b\n' "\tEG: $0 --loglevel 0, or"
    printf '%b\n' "\tEG: $0 -l 1, or visa versa."
    printf '%b\n' "\tIf no loglevel is defined then 0 will be used.\n"
    printf '%b\n' "EXAMPLES:"
    printf '%b\n' "Execute the script in either format; they are interchangeable and produce the same result."
    printf '%b\n' "\t$0 --testmode --standard tdsh --loglevel 1"
    printf '%b\n' "\t$0 -t -s stig -l 1\n"
}


###---
### Verify the version is entered correctly and that the supporting file exists.
###---
parse_version()     {
    # Find the currnt stats on the system, if there are any to get:
    source "$sysInfo"            # from /etc/os-release
    printf '%s\n' "$HARD_STANDARD"  >&2   #   Harding Standard: SCSEM, STIG, or TDSH
    printf '%s\n' "$HARD_VERSION"   >&2   #   Last hardening version configured
    printf '%s\n' "$HARD_DATE"      >&2   #   Date of the last hardening
    printf '%s\n' "$HARD_TYPE"      >&2   #   Full or Delta
}


#set -x
###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------
if [[ -z "$1" ]]; then
    show_help
    exit 1
else
    while [ "$1" != "" ]; do
        case "$1" in
            -s | --standard)    shift
                                hardSpec="$1"
                                hardSpecUC="$(tr '[:lower:]' '[:upper:]' <<<$hardSpec)"
                                # Verify we are using 1 of 3 specified types of hardening
                                case "$hardSpec" in
                                    scsem | stig | tdsh)
                                        ;;
                                    *)
                                        printf '%s\n' "fatal error: $hardSpec is not a valid hardening standard type (scsem, stig, tdsh)."
                                        exit 1
                                        ;;
                                esac
                                ;;
            -v | --version)     export hardVersion="$2"
                                ;;
            -l | --loglevel)    export loglevel="$2"
                                ;;
            -t | --testmode)    testMode=1
                                export InstallType="TEST"
                                export instDir="$HOME/projects/hard_linux/payload"
                                export exeDir="$instDir/sys"
                                ;;
            -h | --help)        show_help
                                exit 1
                                ;;
    esac
    shift
done
fi

###---
### If --testmode not explicitly requested, find out if we are executing as root or not, if
###     root then we are live, else we are by default testing
###---
if [[ "$testMode" != '1' ]]; then
    autoMan="$(whoami)"
    if [[ "$autoMan" = 'root' ]]; then
        export InstallType="LIVE"
        export instDir="$HOME/hard_linux/payload"
        export exeDir=""    # this is used by system.sh, and should be empty in LIVE environment
    else
        export InstallType="TEST"
        export instDir="$HOME/projects/hard_linux/payload"
        export exeDir="$instDir/sys"
    fi
fi


###---
### Source in global environment variables, this also sources
###     in environment variables which are dependent upon if
###     we are executing in LIVE environment or in test mode.
###---
source "vars.sh"


case "$loglevel" in
    1)  source $instLib/infobreak.sh
        export instLogger='infobreak'
        ;;
    *)  export loglevel=0
        source $instLib/infoclean.sh
        export instLogger='infoclean'
        ;;
esac

###---
### Announce and Harden
###---
if [[ "$loglevel" -eq '0' ]]; then
    printf '%s\n' "Running in $InstallType mode."
    printf '%s\n' "Logging level = $loglevel"
    printf '%s\n' "The full path is: $instStandards/$hardSpec.sh"
fi

###---
### Kick-Off the script
###---
source $instLib/printfmsg.sh
printf '\n%s\n\n' "Hardening to version $hardVersion of the $hardSpec standard."
"$instStandards/$hardSpec.sh"
if [[ "$?" -ne '0' ]]; then
    printFStatus "$LINENO" "$instStandards/$hardSpec.sh did not exit successfully."
    exit 1
fi


# Find the current stats on the system, if there are any to get.
#source "$sysInfo"            # from /etc/os-release
#printf '%s\n' "$NAME"           #   OS Name
#printf '%s\n' "$VERSION_ID"     #   OS Version
#printf '%s\n' "$HARD_STANDARD"  #   Harding Standard: SCSEM, STIG, or TDSH
#printf '%s\n' "$HARD_VERSION"   #   Last hardening version configured
#printf '%s\n' "$HARD_DATE"      #   Date of the last hardening
#printf '%s\n' "$HARD_TYPE"      #   Full or Delta


###---
### finish
###---
