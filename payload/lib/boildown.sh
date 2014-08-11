#------------------------------------------------------------------------------
# FUNCTION: Backup some files and boil them down to their essentials.
#           Must be run with a file location and name as an argument.
#           Probably shouldn't be used on everything.
#
#  AUTHORS: Todd E Thomas
#     DATE: 2012/01/08
# MODIFIED:
#------------------------------------------------------------------------------


###----------------------------------------------------------------------------
#### VARIABLES
####----------------------------------------------------------------------------
permsAll="$(ls -l $1)"
permsFile="$(stat -c '%a' $1)"
backupFileLoc="$dirBackup/$(basename $1)".orig
origFile="$(basename $backupFileLoc)"


####----------------------------------------------------------------------------
#### FUNCTION
####----------------------------------------------------------------------------
boildown() {
    # Phase 1, record some stats and make a file.orig backup
    echo -e "Backing-up $1 to $backupFileLoc\n"
    yes | cp -p "$1" "$backupFileLoc"

    # Phase 2: boil down original file and insure proper permissions
    echo -e "Boiling-down $1 to its essentials...\n"
    egrep -v '^(;|#|$)' "$backupFileLoc" > "$1"
    yes | cp -p "$1" "$dirBackup"/
    echo -e "Re-applying original file permissions to new $1.\n"
    chmod "$permsFile" "$1"

    # Phase 3: record file permissions to file.orig
    echo -e " " >> "$backupFileLoc"
    echo -e "Original file permissions were:\n$permsAll"   >> "$backupFileLoc"
    echo -e "Original octal permissions were: $permsFile." >> "$backupFileLoc"
}
