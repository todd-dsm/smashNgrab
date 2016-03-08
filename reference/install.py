#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ft=python ts=4 sw=4 expandtab:
#   PURPOSE: Foundation to select 'tdsh', 'stig', or 'scsem' as a hardening
#            standard for installation.
#            ------------------------------------------------------------------
#            Execute: python install.py -s tdsh
#            ------------------------------------------------------------------
#            NOTES:
#            ------------------------------------------------------------------
#   AUTHOR:  Todd E Thomas
#     DATE:  2013/06/11



"""
PURPOSE:    Implement the "hardening" of Teradata systems. Hardening is the
            administration of systems to adhere to different standards such
            as tdsh, stig, or scsem. These programs will make changes to
            system files that include security (ownership and permissions
            on files, run time permission masking, access restrictions).
            These changes collectively are referred to as "target
            configuration". These programs implement changes based upon
            parameters passed as command line arguments, in combination
            with target configurations stored as lists of things which
            need to be changed.

ASSUMPTION: 1) The programs are executed in 3 ways:
                a) By user root in LIVE production environment, with
                    intention of changing system files. This is the most
                    common way the program will be called:
                        python install.py -s tdsh
                    or
                        python install.py -s tdsh -x disable_rootssh.py

                b) By user root in LIVE production environment in test
                    mode, with intention of only testing changes in an
                    alternate root directory at payload/sys (simulating
                    changes to those files, and not to actual system
                    files):
                        python install.py -s tdsh -t -r
                    or
                        python install.py -s tdsh -t -r -d 1

                c) By non-root user in TEST environment in test mode, with
                    intention of debugging or making program enhancements.
                        python install.py -s tdsh -t -r
                    or
                        python install.py -s tdsh -t -r -d 1

DEPENDENCIES:
            1) Update the password policy for logindefs and pam files per
                customer specification by editing soft link named
                1_passwd_policy.

            2) Update the banner file per customer specification,
                edit soft link named 2_banner_file.

            3) Specify the password for adding new user named "tdgsc",
                edit soft link named 3_tdgsc_password.

            4) The system type is determined by collect_system_info.py and
                saved to hardening/tmp/systemType.txt. It may need to be
                updated manually until the complete list of all system
                types can be added to the collect_system_info.py script.
                Currently only the disable_rootssh.py script depends on
                the system type to be set correctly before making its
                changes.

            5) Verify correct target values are being used to configure the
                system, review lists stored at hardening/payload/var/*lists

            6) Ensure that SUSE CD is mounted at /mnt/cdrom, such that
                modules can find audit rpm there.

            7) If executing on STIG system, verify you have the latest
                STIG specification, i.e. UNIX Manual SRG, Version X,
                Release Y. See website
                    http://iase.disa.mil/stigs/os/unix/unix.HTML

                If not, then download and unzip it, then save the xml
                file to payload/var/U_UNIX_V*_SRG_Manual-xccdf.xml

            8) When executing in test mode and not as root, you should
                edit /etc/sudoers to ensure your user name is configured to
                not have to enter in a password when sudo is invoked.
                Not doing so, will result having to enter in your password
                way too many times when the python modules invoke sudo.
                Here is what it looks like when you change /etc/sudoers:
                    ...
                    #Defaults targetpw # ask for password of target user
                    #ALL ALL=(ALL) ALL # Only use with 'Defaults targetpw'!
                    ...
                    # User privilege specification
                    root    ALL=(ALL) ALL
                    thomas  ALL=(ALL)NOPASSWD: ALL


USAGE:      First, execute ~/hardening/payload/src/sh/initialstate.sh to
            1) save the initial state of different files that are possibly
                touched by this program. This includes their permission modes,
                ownership, and copies of them (save to the
                ~hardening/logs/initialstate).
            2) get list of all RPM packages currently installed
            3) get list of current system configurations (chkconfig -l)

            Then execute the python modules:
            python install.py -s tdsh       # execute LIVE, tdsh standard
            python install.py -s stig       # execute LIVE, stig standard
            python install.py -s scsem      # execute LIVE, scsem standard

            # execute in test mode, reset changes, see debugging messages:
                python install.py -s tdsh -t -r -d 1

            # to execute just one script, e.g. disable_rootssh.py:
                python install.py -s tdsh -x disable_rootssh.py

            For all options: install.py --help

AUTHOR:     Todd E Thomas
CREATED:    2013/12/09
MODIFIED:
"""

###----------------------------------------------------------------------------
### IMPORTS
###----------------------------------------------------------------------------
import datetime
import os
import shutil
import subprocess
import sys
import threading
import webbrowser
from optparse import OptionParser


###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
startTime = datetime.datetime.now()
scriptName = sys.argv[0]
pathname = os.path.dirname(sys.argv[0])
scriptPath = os.path.abspath(pathname)

# get environment variables
try:
    HOME = os.environ['HOME']
except Exception:
    print('%s required HOME not set in environment, exiting.' % scriptName)
    sys.exit(1)

exeScriptname = ''
hardSpec = ''
hardVersion = "0.01"
tarFileName = 'results.tgz'

# initialize to false until we determine if in test mode or not
testMode = False

# always initialize to InstallType=TEST to prevent accidental overwrite in
#   root. During testing, all execution will be relative to exeDir, which is
#   {location of this script}/payload/sys rather than /
InstallType = "TEST"

# initialize relative pathname variables dependent on InstallType
#   scriptPath is the location of this script
instDir = scriptPath + '/' + 'payload'
instStandards = instDir + '/' + 'standards'
exeDir = instDir + '/' + 'sys'
sysEtcDir = exeDir + '/' + 'etc'
sysReleaseInfo = sysEtcDir + '/' + 'SuSE-release'

# External programs
initialExtProgs = [('BASH_PROGRAM', '/bin/bash'),
                   ('CHAGE_PROGRAM', '/usr/bin/chage'),
                   ('CHGRP_PROGRAM', '/bin/chgrp'),
                   ('CHMOD_PROGRAM', '/bin/chmod'),
                   ('CHOWN_PROGRAM', '/bin/chown'),
                   ('CP_PROGRAM', '/bin/cp'),
                   ('DIG_PROGRAM', '/usr/bin/dig'),
                   ('FIND_PROGRAM', '/usr/bin/find'),
                   ('GROUPADD_PROGRAM', '/usr/sbin/groupadd'),
                   ('GROUPDEL_PROGRAM', '/usr/sbin/groupdel'),
                   ('HOSTNAME_PROGRAM', '/bin/hostname'),
                   ('LN_PROGRAM', '/bin/ln'),
                   ('LOGROTATE_PROGRAM', '/usr/sbin/logrotate'),
                   ('MKDIR_PROGRAM', '/bin/mkdir'),
                   ('MV_PROGRAM', '/bin/mv'),
                   ('PAMCONFIG_PROGRAM', '/usr/bin/pam-config'),
                   ('PASSWD_PROGRAM', '/usr/bin/passwd'),
                   ('PWCONV_PROGRAM', '/usr/sbin/pwconv'),
                   ('RPM_PROGRAM', '/bin/rpm'),
                   ('RM_PROGRAM', '/bin/rm'),
                   ('SYSCTL_PROGRAM', '/sbin/sysctl'),
                   ('SERVICE_PROGRAM', '/sbin/service'),
                   ('TAR_PROGRAM', '/usr/bin/tar'),
                   ('TOUCH_PROGRAM', '/usr/bin/touch'),
                   ('USERADD_PROGRAM', '/usr/sbin/useradd'),
                   ('USERDEL_PROGRAM', '/usr/sbin/userdel'),
                   ('USERMOD_PROGRAM', '/usr/sbin/usermod'),
                   ('WHOAMI_PROGRAM', '/usr/bin/whoami')]

###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------


class RepeatingTimer(threading._Timer):
    def run(self):
        ''' Since we use the subprocess call which is blocking until        '''
        ''' completion, one way to print something out while waiting would  '''
        ''' be to use multithreading. This function uses threading._Timer   '''
        while True:
            self.finished.wait(self.interval)
            if self.finished.isSet():
                return
            else:
                self.function(*self.args, **self.kwargs)


def progressStatus():
    ''' print current time '''
    whatTime = datetime.datetime.now()
    whatTime = '\033[36m%s\033[0m' % whatTime
    sys.stdout.write("\r%s" % whatTime)
    sys.stdout.flush()


def verifyExtProg(programList):
    ''' Verify path to external programs we use are correct paths.          '''
    '''     If type reports an alternate location from standard list, then  '''
    '''     use it. If type returns nothing, then report program could not  '''
    '''     be found on system.                                             '''
    ###---
    ### Get OS Details with SUSE version number for pam configurations
    ###---
    modName = 'verifyExtProg'
    sysReleaseInfo = '/etc/SuSE-release'

    if os.path.isfile(sysReleaseInfo):
        for line in open(sysReleaseInfo):
            if line[0:7] == 'VERSION':
                (version, versionNumber) = line.split('=')
                SLES = versionNumber.strip()
    else:
        print('%s: could not open %s to determine SUSE version number'
              % (modName, sysReleaseInfo))
        if SLES == '':
            print('%s: could not determine SUSE version number' % modName)

    # initialize empty list to hold the programs we can verify
    verifiedProgs = []

    # start at standard program list and see if executable exists, if not
    #   use what type -P returns, else report an error
    for line in programList:

        # get first item in list which is variable name for the program
        var = line[0]

        # get second item in list which is program location
        program = line[1]

        # get the basename of the program
        fbasename = program.split('/')[-1]
        bashBuiltInCmd = 'type -P %s' % fbasename

        if SLES != '11':
            if var == 'PAMCONFIG_PROGRAM':
                continue

        # Execute bash built-in type as a subprocess
        try:
            process = subprocess.Popen(["bash", "-c", bashBuiltInCmd],
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE)
        except Exception:
            # handle any exception from subprocess when it execs bash process
            (type, value, traceback) = sys.exc_info()
            msg = 'Could not locate external program for %s at %s: %s' \
                  % (fbasename, program, value)
            # return 1 for error, error message, and empty list
            return(1, msg, '')

        # get standard output and standard error from bash -c
        (stdout, stderr) = process.communicate()

        # remove leading and trailing spaces and newline character
        stdout = stdout.strip()
        program = program.strip()

        #print('stdout %s, program %s' % (stdout, program))

        # if type returned no results, then report error that program could not
        #   be located
        if stdout == '':
            msg = 'External program for %s is not located at %s.\n \
Please update the externalPrograms list with correct location of executable.' \
                  % (var, program)
            # return 1 for error, error message, and empty list
            return(1, msg, '')
        else:
            # if type returns that program exists at another location from
            #   standard list, then use the location type returned instead
            if stdout != program:
                cmdList = (var, stdout)
            else:
                cmdList = (var, program)

        # append the program name and location to verifiedProgs list
        verifiedProgs.append(cmdList)

    # return 0 for success, no error message, and verified program list
    return(0, '', verifiedProgs)


def beginTxtSpecialCharBlock(line, specialChar):
    ''' find ascii special character in line and map them to HTML begin tag '''

    # dictionary of special characters mapped to HTML tag equivalent
    dictSpecialcharHTMLtag = {'[1m': '<b>',  # bold
                              '[5m': '<b>',  # blink
                              '[30m': '<font color="black">',  # black
                              '[31m': '<font color="red">',  # red
                              '[32m': '<font color="green">',  # green
                              '[33m': '<font color="yellow">',  # yellow
                              '[34m': '<font color="blue">',  # blue
                              '[35m': '<font color="magenta">',  # magenta
                              '[36m': '<font color="cyan">',  # cyan
                              '[37m': '<font color="white">'  # white
                              }

    # strip blank characters at end of line
    line.rstrip()

    # find location of special character in the line
    scIndex = line.index(specialChar)

    # get the length of special character
    scLength = scIndex + len(specialChar)

    # get the text after special character
    txtAfterIndex = line[scLength:]

    # set HTML tag equivalent of the special character
    tag = dictSpecialcharHTMLtag[specialChar]

    # append any remaining text, after the converted special character
    cnvTxt = tag + txtAfterIndex

    # return the converted line
    return(cnvTxt)


def endTxtSpecialCharBlock(line, specialChar, lastSpecialChar):
    ''' find ascii special character in line and map them to HTML end tag '''

    # dictionary of special characters mapped to HTML end tag equivalent
    dictSpecialcharHTMLtag = {'[1m': '</b>',  # bold
                              '[5m': '</b>',  # blink
                              '[30m': '</font>',  # black
                              '[31m': '</font>',  # red
                              '[32m': '</font>',  # green
                              '[33m': '</font>',  # yellow
                              '[34m': '</font>',  # blue
                              '[35m': '</font>',  # magenta
                              '[36m': '</font>',  # cyan
                              '[37m': '</font>'  # white
                              }

    # strip blank characters left at end of line
    line.rstrip()

    # find location of special character in the line
    scIndex = line.index(specialChar)

    # if special character is not at beginning of line, get the text
    #   before the special character
    if scIndex > 0:
        # -1 to handle the ANSI escape code for VT100, \033
        #   and escape code to switch foreground color, \x1b
        txtBeforeIndex = line[0:scIndex - 1]
    else:
        txtBeforeIndex = ''

    # set HTML tag equivalent of the special character
    tag = dictSpecialcharHTMLtag[lastSpecialChar]

    # prepend any text before tag, if any, before the converted special
    #   character
    cnvTxt = txtBeforeIndex + tag

    # return the converted text
    return(cnvTxt)


def strToFile(text, filename):
    ''' Write a file with the given name and the given text.'''

    # open file in write mode, if not exist, create it
    try:
        fp = open(filename, "w+")
    except Exception:
        # if error, return error message
        (type, value, traceback) = sys.exc_info()
        return(value)
    # write text to the file
    fp.write(text)
    # rewind file to beginning
    fp.seek(0)
    # close the file pointer
    fp.close()
    # return 0 for success
    return(0)


def browseLocal(webpageText, filename):
    ''' Start your webbrowser on a local file containing the text with      '''
    ''' given filename.                                                     '''

    # call to write HTML content to filename
    strToFile(webpageText, filename)
    # view the file through web browser
    try:
        webbrowser.open("file:///" + os.path.abspath(filename))
    except Exception:
        # if error, return error message
        (type, value, traceback) = sys.exc_info()
        return(value)
    # return 0 for success
    return(0)

###----------------------------------------------------------------------------
### MAIN PROGRAM
###----------------------------------------------------------------------------

# create instance of object to handle parsing comand line arguments to this
#   program
parser = OptionParser()
parser.add_option("-d", "--debuglevel", dest="DEBUGLEVEL",
                  default=0, help="specify a debug level, 0 for standard \
                  logging or 1 for debug output.")
parser.add_option("-l", "--loglevel", dest="LOGLEVEL",
                  default=0, help="specify a log level, 0 to write \
                  results to html file or 1 to not write results to html.")
parser.add_option("-s", "--standard", dest="HARDSPEC",
                  help="specify hardening standard spec, 'sig', 'scem' or \
                  'tdsh'.")
parser.add_option("-x", "--executeOnly", dest="EXESCRIPTNAME",
                  help="specify only one specific script should be executed")
parser.add_option("-r", "--resettest", action="store_true", dest="RESETTEST",
                  default=False, help="specify after each execution, reset \
                  files for testing purposes, only works with -t (testmode).")
parser.add_option("-t", "--testmode", action="store_true", dest="TESTMODE",
                  default=False, help="run in testmode which uses alternate \
                  execution directories from LIVE production environment")
parser.add_option("-v", "--version", dest="HARDVERSION",
                  help="specify hardening version, version number used for \
                  all installs but primarily for reporting.")

# parse the arguments to this program and save to options and arguments to
#   each option
(options, args) = parser.parse_args()

# if debuglevel was passed, then set DEBUGLEVEL to number specified
if options.DEBUGLEVEL:
    debuglevel = options.DEBUGLEVEL
else:
    # if no debuglevel was passed, then set default to 0
    debuglevel = '0'

# if loglevel was passed, then set LOGLEVEL to number specified
if options.LOGLEVEL:
    loglevel = options.LOGLEVEL
else:
    # if no loglevel was passed, then set default to 0
    loglevel = '0'

# if standard was passed, then set HARDSPEC (hardening specification
#   standard) to standard specified
if options.HARDSPEC:
    hardSpec = options.HARDSPEC
else:
    # if no standard was passed, print error and exit
    print('%s hardSpec is a required parameter, see -h for help usage'
          % scriptName)
    sys.exit(1)

if options.EXESCRIPTNAME:
    exeScriptname = options.EXESCRIPTNAME

# convert hardening specification standard to uppercase
hardSpecUC = hardSpec.upper()
# verify that standard is valid
if hardSpecUC != 'SCSEM':
    if hardSpecUC != 'STIG':
        if hardSpecUC != 'TDSH':
            # if not valid standard, print error and exit
            print('%s %s not a valid hardening standard type'
                  % (scriptName, hardSpec))
            sys.exit(1)

# if testmode was passed, set flag to True
if options.TESTMODE:
    testMode = True

# if reset test was passed, set to 1 for on
if options.RESETTEST:
    resetTest = '1'
else:
    # if reset test was not passed, set to 0 for off
    resetTest = '0'

# if hardening version number was passed, then set version number to what
#   user specified, and later print the number. No other real action for
#   this in code at this time.
if options.HARDVERSION:
    hardVersion = options.HARDVERSION


###---
### verify we have correct paths to system's external programs
###---
(ecode, rval, verifiedExternalPrograms) = verifyExtProg(initialExtProgs)
if ecode != 0:
    print('%s' % rval)
    sys.exit(1)
else:
    # put programs into environment so later called scripts have access to them
    for program in verifiedExternalPrograms:
        # parse list of programs whose execution path were verified
        #       verifiedExternalPrograms =
        #           (programName, executionPath), (...)]
        #   An example in environment is
        #       os.environ['CHMOD_PROGRAM' = '/usr/sbin/chmod']
        os.environ[program[0]] = program[1]

###---
### If testmode not explicitly requested on command line, find out if we
###   are executing as root or not. If root then we will assume we are in
###   LIVE production environment, else if we executing as some non-root
###   user assume that we are in test mode, and use alternate execution
###   directory and do not change real system files.
###---
if testMode is False:
    # find out who is executing this program
    WHOAMI_PROGRAM = os.environ['WHOAMI_PROGRAM']
    cmd = '%s' % WHOAMI_PROGRAM

    # execute command in as a subprocess
    whop = subprocess.Popen(cmd, stdout=subprocess.PIPE)

    # get standard output and standard error from command executed
    (autoMan, err) = whop.communicate()
    # strip newline character
    autoMan = autoMan.rstrip()

    # if we could determine who was executing, then check if root
    if err is None:
        if autoMan == "root":
            # set that we are executing in live production environment
            InstallType = "LIVE"

            # set that we are executing from root's home directory, and
            #   payload install directory
            instDir = HOME + '/' + 'hardening' + '/' + 'payload'

            # set standards directory location
            instStandards = instDir + '/' + 'standards'

            # exeDir is an alternate execution directory used during
            #   testmode to ensure we only write to files found therein,
            #   and not to real system file locations. If we are running
            #   in LIVE production environment and not executing in
            #   testmode, then this alternate exeDir should be blank
            exeDir = ""
    else:
        # else, whoami failed, print error, and exit
        print('%s unable to determine if we are executing as root'
              % scriptName)
        sys.exit(1)

###---
### put variables into environment for this and later called scripts to use
###---
# based on command line arguments and defaults
os.environ['exeScriptname'] = exeScriptname
os.environ['debuglevel'] = debuglevel
os.environ['loglevel'] = loglevel
os.environ['InstallType'] = InstallType
os.environ['instDir'] = instDir
os.environ['instStandards'] = instStandards
os.environ['exeDir'] = exeDir
os.environ['resetTest'] = resetTest

# relative to the installation directory of this script
instSrc = instDir + '/' + 'src'
os.environ['instSrc'] = instSrc
instSrcPy = instSrc + '/' + 'py'
os.environ['instSrcPy'] = instSrcPy
instSrcTests = instSrcPy + '/' 'tests'
os.environ['instSrcTests'] = instSrcTests

# installation variable, lists, and banner files
instVar = instDir + '/' + 'var'
os.environ['instVar'] = instVar
instLists = instVar + '/' + 'lists'
os.environ['instLists'] = instLists
specBanner = instVar + '/' + 'banner.txt'
os.environ['specBanner'] = specBanner

###----------------------------------------------------------------------------
### Declare remaining environment variables which uses execution
###     directory based on if we are executing in LIVE environment or
###     in test mode
###----------------------------------------------------------------------------

# Set up variables to user's environment, note that exeDir is blank when
#   executing in LIVE environment in non-test mode; if in test mode, exeDir
#   will point to relative path hardening/payload/sys so that we will not
#   modify the real root directory, but a fake one
userHome = exeDir + '/' + 'root'
os.environ['userHome'] = userHome
hardDir = userHome + '/' + 'hardening'
os.environ['hardDir'] = hardDir

# Set up back up and log directories
backupDir = hardDir + '/' + 'backups'
os.environ['backupDir'] = backupDir
backupLogs = hardDir + '/' + 'logs'
os.environ['backupLogs'] = backupLogs
tmpDir = hardDir + '/' + 'tmp'
os.environ['tmpDir'] = tmpDir

###---
### Save initial state of the system if we did not previously
###---
initialstatelogdir = backupLogs + '/' + 'initialstatefiles'
if os.access(initialstatelogdir, os.F_OK):
    if os.path.isdir(initialstatelogdir) is False:
        # Execute initialstate.sh as a subprocess
        cmd = '%s/payload/src/sh/initialstate.sh' % hardDir
        initstp = subprocess.Popen(["bash", "-c", cmd],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)

        # get standard output and standard error from command executed
        (valHostname, err) = initstp.communicate()

###---
### If STIG, ensure that we have a csv file to status test results, created
###     by parsing the original STIG SRG manual in xml format
###---
if hardSpecUC == 'STIG':
    stigCSVFileBasename = 'SRG.csv'
    stigCSVFile = backupLogs + '/' + stigCSVFileBasename
    os.environ['stigCSVFile'] = stigCSVFile
    stigXMLOrigFile = instVar + '/' + 'U_UNIX_V*_SRG_Manual-xccdf.xml'
    cmd = 'ls %s' % stigXMLOrigFile
    # get XML full filename
    try:
        process = subprocess.Popen(["bash", "-c", cmd],
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
    except Exception:
        # handle any exception from subprocess when it execs bash process
        (type, value, traceback) = sys.exc_info()
        print('Could not get full filename of STIG Manual %s: %s'
              % (stigXMLOrigFile, value))
        # return 1 for error, error message, and empty list
        sys.exit(1)

    # get standard output and standard error from bash -c
    (stdout, stderr) = process.communicate()

    # remove newline character
    stigXMLOrigFile = stdout.strip()

    if os.access(stigCSVFile, os.F_OK) is False:
        # see if SRG manual is available to create it
        if os.access(stigXMLOrigFile, os.F_OK):
            parseModule = instSrcPy + '/parseSRGManual.py'
            try:
                parse_p = subprocess.Popen(parseModule,
                                           stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE)
            except Exception:
                # if error, print message, and exit
                (type, value, traceback) = sys.exc_info()
                print('Could not execute %s: %s' % (parseModule, value))
                sys.exit(1)

            parse_p.wait()

            # get the standard output and standard error results
            (stdout, stderr) = parse_p.communicate()
            if stderr:
                print('%s: subprocess.Popen error %s' % (parseModule, stderr))
                sys.exit(1)

            ### Write output from subprocess python scripts to standard output
            print(stdout)
        else:
            print('Unable to access STIG csv file %s (or original %s \
to create it)'
                  % (stigCSVFile, stigXMLOrigFile))
            sys.exit(1)

###---
### Create output log files in txt and HTML format, writing to txt file
###     first, then converting it to HTML format once execution completes.
###---
# create backups, logs, and tmp directories
setupDirs = (backupDir, backupLogs, tmpDir)
for directory in setupDirs:
    """ create directory if not exist"""
    if os.access(directory, os.F_OK):
        if os.path.isdir(directory) is False:
            try:
                os.makedirs(directory, mode=0755)
            except Exception:
                (type, value, traceback) = sys.exc_info()
                print('Unable to create required directory: %s'
                      % (directory, value))
                sys.exit(1)
    else:
        try:
            os.makedirs(directory, mode=0755)
        except Exception:
            (type, value, traceback) = sys.exc_info()
            print('Unable to create required directory: %s'
                  % (directory, value))
            sys.exit(1)

# get valid date string in yymmddHHMM format
valDate = str(datetime.datetime.now().strftime("%y-%m-%d-%H-%M"))

# get hostname
HOSTNAME_PROGRAM = os.environ['HOSTNAME_PROGRAM']
cmd = '%s -s' % HOSTNAME_PROGRAM

# Execute hostname as a subprocess
hostnamep = subprocess.Popen(["bash", "-c", cmd],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)

# get standard output and standard error from command executed
(valHostname, err) = hostnamep.communicate()

# set output filenames with time stamp and hostname if available
if valHostname:
    # remove newline character
    valHostname = valHostname.rstrip()
    resultsHTMLdir = backupLogs + '/' + \
        valDate + '_installOutput_' + valHostname
    resultsHTML = backupLogs + '/' + \
        valDate + '_installOutput_' + valHostname + '.html'
    resultsTxt = backupLogs + '/' + \
        valDate + '_installOutput_' + valHostname + '.txt'
else:
    resultsHTMLdir = backupLogs + '/' + valDate + '_installOutput'
    resultsHTML = backupLogs + '/' + valDate + '_installOutput.html'
    resultsTxt = backupLogs + '/' + valDate + '_installOutput.txt'

rdirbasename = resultsHTMLdir.split('/')[-1]
rbasename = resultsHTML.split('/')[-1]

# if loglevel == 0, set temporary html file name global variable
if int(loglevel) == 0:
    outputHTML = tmpDir + '/' + \
        valDate + '_installOutputBody_' + valHostname + '.html'
    os.environ['outputHTML'] = outputHTML

# open the output log for writing
try:
    resultsTxt_fp = open(resultsTxt, "w+")
except Exception:
    # if error, return error message
    (type, value, traceback) = sys.exc_info()
    print('Could not open % to log results: %s' % (resultsTxt, value))
    sys.exit(1)

# create file to hold test execution status of STIG test cases
stigStatusFile = tmpDir + '/' + valDate + '_stigStatus.txt'

# open the STIG status result log for writing
try:
    stigStatus_fp = open(stigStatusFile, "w+")
except Exception:
    # if error, return error message
    (type, value, traceback) = sys.exc_info()
    print('Could not open %s: %s' % (stigStatusFile, value))
    sys.exit(1)

os.environ['stigStatusFile'] = stigStatusFile

###---
### Announce and harden, going forward we are writing duplicate messages to
###     screen, and to log file.
###---

# print information about settings we are executing with
if InstallType != 'LIVE':
    print('Running in %s mode.' % InstallType)
    resultsTxt_fp.write('Running in %s mode.\n' % InstallType)

    if resetTest == '1':
        print('Reset files for testing is turned on.')
        resultsTxt_fp.write('Reset files for testing is turned on.\n')

    print('Debug level = %s' % debuglevel)
    resultsTxt_fp.write('Debug level = %s\n' % debuglevel)

    print('Logging level = %s' % loglevel)
    resultsTxt_fp.write('Logging level = %s\n' % loglevel)

###---
### If there is no backup directory then make one
###---
if os.path.isdir(backupDir) is False:
    try:
        # create all paths along the way if needed, set permission mode
        os.makedirs(backupDir, mode=0755)
    except Exception:
        # if error, print message, and exit
        (type, value, traceback) = sys.exc_info()
        print('%s: %s' % value)
        sys.exit(1)

if debuglevel == '1':
    print('The backup directory is here: %s' % backupDir)
    resultsTxt_fp.write('The backup directory is here: %s\n' % backupDir)

###---
### If there is no logs directory then make one
###---
if os.path.isdir(backupLogs) is False:
    try:
        # create all paths along the way if needed, set permission mode
        os.makedirs(backupLogs, mode=0755)
    except Exception:
        # if error, print message, and exit
        (type, value, traceback) = sys.exc_info()
        print('%s: %s' % value)
        sys.exit(1)

if debuglevel == '1':
    print('The logs directory is here: %s' % backupLogs)
    resultsTxt_fp.write('The logs directory is here: %s\n' % backupLogs)

if debuglevel == '1':
    print('\nExternal programs being used are:')
    resultsTxt_fp.write('\nExternal programs being used are:\n')
    for programs in verifiedExternalPrograms:
        print('%s = %s' % (programs[0], programs[1]))
        resultsTxt_fp.write('%s = %s\n' % (programs[0], programs[1]))

###---
### Kick-Off the standards script
###---
print('\nHardening to version %s of %s standard.\n'
      % (hardVersion, hardSpec))
resultsTxt_fp.write('\nHardening to version %s of %s standard.\n\n'
                    % (hardVersion, hardSpec))

standardFile = instSrcPy + '/' + hardSpec + '.py'
standardFile = os.path.abspath(standardFile)
print('The full path is: %s\n' % standardFile)
resultsTxt_fp.write('The full path is: %s\n\n' % standardFile)
if not exeScriptname:
    print('Just a minute...:')
    resultsTxt_fp.write('Just a minute...%s\n\n')

# Start the time and hardening script
timer = RepeatingTimer(1.0, progressStatus)
# Allows program to exit if only the thread is alive
timer.daemon = True

timer.start()
try:
    # for progress bar, do real work here
    standardp = subprocess.Popen(standardFile,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
except Exception:
    # if error, print message, and exit
    (type, value, traceback) = sys.exc_info()
    print('Could not execute %s: %s' % (standardFile, value))
    sys.exit(1)

# get the standard output and standard error results
(stdout, stderr) = standardp.communicate()
if stderr:
    print('%s: subprocess.Popen error %s' % (standardFile, stderr))
    sys.exit(1)

### Write output from subprocess python scripts to standard output
print(stdout)
resultsTxt_fp.write(stdout)
timer.cancel()

###---
### Parse output to transform formatting from ANSI code to HTML tags
###---
# rewind to beginning of file
resultsTxt_fp.seek(0)
# read back all output results
myBuffer = resultsTxt_fp.readlines()
# rewind to beginning of file
resultsTxt_fp.seek(0)
# close the file
resultsTxt_fp.close()

###---
### parse for special display characters in our output buffer, and replace
###     special characters with HTML equivalent tags
###---
# boolean if special character detected
specialCharFound = False
# empty list to hold the converted text
cnvBuffer = []

for line in myBuffer:
    # strip newline character
    line.rstrip()

    # if not blank line
    if line:
        line = line.rstrip()
        # The ASCII special characters below represent these things:
        #   specialChars = (bold, blink, black, red, green, yellow,
        #                   blue, magenta, cyan, white)
        specialChars = ('[1m', '[5m', '[30m', '[31m', '[32m', '[33m',
                        '[34m', '[35m', '[36m', '[37m')

        # check if special character detected is in our list of specialChars
        for sChars in specialChars:
            # if special character appears in the line of text
            if sChars in line:
                # set boolean to True that it was detected
                specialCharFound = True
                # save the special character detected
                lastSpecialChar = sChars
                # transform to HTML begin tag for this special character,
                #   for example, '[1m' is bold, so HTML begin tag is <B>
                line = beginTxtSpecialCharBlock(line, lastSpecialChar)
                # break out of loop for this line
                break

        # if special character was detected earlier, then find where it is
        #   reset, and convert that to HTML ending tag
        if specialCharFound is True:
            # [0m is ANSI reset character
            if '[0m' in line:
                specialChar = '[0m'
                # transform to the HTML end tag for last special character,
                #   for example, '[1m' is bold, so HTML end tag is </B>
                line = endTxtSpecialCharBlock(line, specialChar,
                                              lastSpecialChar)
                # reset specialCharFound boolean once handled end of block
                specialCharFound = False

    # write the converted line to buffer to write to file later
    cnvBuffer.append(line)

###---
### Built HTML web page
###---
# write generic text which starts standard web page
valDate2 = str(datetime.datetime.now().strftime("%B %d, %Y"))
webpageHeader = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Teradata Security Hardening for Linux V2.0</title>

    <link rel="stylesheet" media="screen" href="%s/hardening.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="author" content="Todd E Thomas">
    <meta name="description" content="Teradata security hardening.">
    <!--[if lt IE 9]>
    <script src="script/html5shiv.js"></script>
    <![endif]-->
</head>

<body id="hardening">
<div class="page-wrapper">

    <section class="intro" id="intro">
        <header role="banner">
            <h1>Security Hardening Procedures for Linux V2.0: %s</h1>
        </header>

        <div class="summary" id="summary" >
        <p>Presented by: Todd E Thomas &nbsp;&nbsp;&nbsp;
        Teradata Information Security  COE &nbsp; &nbsp; &nbsp; &nbsp;
        &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;
        %s</p>
        </div>

    </section>

    <div class="main supporting" id="supporting" >

''' % (rdirbasename, hardSpecUC, valDate2)
# write generic text which ends standard web page
# start the buffer where body of web page content will be
contentsHTML = webpageHeader

webpageTrailer = '''
    </div>

</div>

<div class="extra1" ></div>
<div class="extra2" ></div>
<div class="extra3" ></div>
<div class="extra4" ></div>
<div class="extra5" ></div>
<div class="extra6" ></div>

</body>

</html>
'''

fp = open(outputHTML, 'rb')
for line in open(outputHTML, 'rb'):
    contentsHTML = contentsHTML + line
contentsHTML = contentsHTML + webpageTrailer

# Commenting out section which launches browser because most of time script
#   is executing from ssh to target system, and not launching browser from
#   desktop.
#
# Write to HTML file, also attempt to open browser automatically to view
#   it if possible.
#rval = browseLocal(contentsHTML, resultsHTML)
#if rval != 0:
#    if debuglevel == 1:
#        print('Open browser to display %s error: %s' % (resultsHTML, rval))

# Write to HTML content to results file
strToFile(contentsHTML, resultsHTML)

try:
    os.makedirs(resultsHTMLdir)
except OSError:
    # errno file exists, must be executing in same minute, create 2nd directory
    resultsHTMLdir = resultsHTMLdir + '_2'
    os.makedirs(resultsHTMLdir)
except Exception:
    # if error, print message, and exit
    (type, value, traceback) = sys.exc_info()
    print('Could not make directory: %s' % value)
    sys.exit(1)

shutil.copy(hardDir + '/payload/docs/css/hardening.css', resultsHTMLdir)
shutil.copy(hardDir + '/payload/docs/css/bg.gif', resultsHTMLdir)
shutil.copy(hardDir + '/payload/docs/css/bottom.gif', resultsHTMLdir)
shutil.copy(hardDir + '/payload/docs/css/procedure.gif', resultsHTMLdir)
shutil.copy(hardDir + '/payload/docs/css/Teradata.gif', resultsHTMLdir)
shutil.copy(hardDir + '/payload/docs/css/T_Header.gif', resultsHTMLdir)

print('Results saved to:')
print('  text file: %s' % resultsTxt)
print('  web page : %s' % resultsHTML)

###---
### If STIG, initialize all test status to Not Executed
###---
if hardSpecUC == 'STIG':
    lineno = 0
    tmpBuf = []
    fp = open(stigStatusFile, 'rb')
    statusBuf = fp.readlines()
    fp.seek(0)
    fp.close()

    for csvline in open(stigCSVFile, 'rb'):
        TCprocessed = False
        lineno += 1
        for tcStatusLine in statusBuf:
            (tcid, fname, tcstatus) = tcStatusLine.split()
            #print('line %s: tcStatusLine = %s\ntcstatus %s'
            #      % (lineno, tcStatusLine, tcstatus))
            if tcid in csvline:
                #print('line %s: csvline = "%s"' % (lineno, csvline))
                csvline = csvline.replace('Not Executed', tcstatus)
                #print('line %s: replaced csvline = "%s"' % (lineno, csvline))
                tmpBuf.append(csvline)
                TCprocessed = True
                break

        if TCprocessed is False:
            tmpBuf.append(csvline)

if hardSpecUC == 'STIG':
    if tmpBuf:
        fp = open(stigCSVFile, 'w+')
        for line in tmpBuf:
            fp.write(line)
        fp.seek(0)
        fp.close()

###---
### If STIG, initialize all exception status to exception verbiage
###---
# Per Jim: Do not configure, define exception verbiage
eList = ['TC_V-23826_GEN005490_SV-28762r1_rule, FIPS, \
            "Teradata: Need exception verbiage"',
         'TC_V-23827_GEN005495_SV-28763r1_rule, FIPS, \
            "Teradata: Need exception verbiage"',
         'TC_V-22457_GEN005504_SV-26750r1_rule, Listen, \
            "Teradata: All are management interfaces; configuring all \
interfaces gets the same result as configuring no interfaces."',
         'TC_V-22470_GEN005521_SV-26763r1_rule, AllowGroups, \
            "Teradata: Need exception verbiage"',
         'TC_V-22473_GEN005524_SV-26766r1_rule, GSSAPI, \
            "Teradata: systems do not require GSSAPIAuthentication."',
         'TC_V-22474_GEN005525_SV-26767r1_rule, GSSAPI, \
            "Teradata: systems do not require GSSAPIAuthentication."',
         'TC_V-22475_GEN005526_SV-26768r1_rule, Kerberos, \
            "Teradata systems do not require kerberos."',
         'TC_V-22480_GEN005531_SV-26774r1_rule, PermitTunnel, \
            "Teradata: PermitTunnel cannot be set in SLES 10 as it is \
not a configurable option for this version of OpenSSH."',
         'TC_V-22482_GEN005533_SV-26776r1_rule, MaxSessions, \
            "Teradata: This would restrict pshell from proper operation. \
This is not implemented.', ]
if hardSpecUC == 'STIG':
    lineno = 0
    tmpBuf = []

    for csvline in open(stigCSVFile, 'rb'):
        TCprocessed = False
        lineno += 1
        for tcException in eList:
            (tcid, param, exceptStr) = tcException.split()
            if tcid in csvline:
                csvline = csvline.replace('Not Executed', exceptStr)
                #print('line %s: replaced csvline = "%s"' % (lineno, csvline))
                tmpBuf.append(csvline)
                TCprocessed = True
                break

        if TCprocessed is False:
            tmpBuf.append(csvline)

if hardSpecUC == 'STIG':
    if tmpBuf:
        fp = open(stigCSVFile, 'w+')
        for line in tmpBuf:
            fp.write(line)
        fp.seek(0)
        fp.close()


if hardSpecUC == 'STIG':
    print('\n  STIG csv file: %s' % stigCSVFile)
    print('    Import into Excel with options set to: UTF-8, \
separated by Tab, Text Delimiter of ";", and Merge delimiters.\n\n')

# tar up resultsHTML and directory
TAR_PROGRAM = os.environ['TAR_PROGRAM']
if InstallType == "LIVE":
    if hardSpecUC == 'STIG':
        cmd = 'cd %s; %s -czvf %s %s %s %s' \
              % (backupLogs, TAR_PROGRAM, tarFileName, rdirbasename,
                 rbasename, stigCSVFileBasename)
    else:
        cmd = 'cd %s; %s -czvf %s %s %s' \
              % (backupLogs, TAR_PROGRAM, tarFileName, rdirbasename,
                 rbasename)
else:
    if hardSpecUC == 'STIG':
        cmd = 'cd %s; sudo %s -czvf %s %s %s %s' \
              % (backupLogs, TAR_PROGRAM, tarFileName, rdirbasename,
                 rbasename, stigCSVFileBasename)
    else:
        cmd = 'cd %s; sudo %s -czvf %s %s %s' \
              % (backupLogs, TAR_PROGRAM, tarFileName, rdirbasename,
                 rbasename)

try:
    standardp = subprocess.Popen(["bash", "-c", cmd],
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
except Exception:
    # if error, print message, and exit
    (type, value, traceback) = sys.exc_info()
    print('Could not execute %s: %s' % (cmd, value))
    sys.exit(1)

standardp.wait()

# get the standard output and standard error results
(stdout, stderr) = standardp.communicate()
if stderr:
    print('%s: subprocess.Popen error %s' % (cmd, stderr))
    sys.exit(1)

print('Results archived to:')
print('  tar file : %s/%s' % (backupLogs, tarFileName))
print('    To extract it, use "tar -vxzf %s"' % tarFileName)

endTime = datetime.datetime.now()
diffTime = endTime - startTime
print('\nExecution complete. Elapsed time = %s seconds.' % diffTime.seconds)

sys.exit(0)
