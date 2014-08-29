#!/usr/bin/env bash
set -e


###---
### the sudo password business is just too tedious
###---
sed -i '/^%wheel/ s/^%wheel/#%wheel/g' /etc/sudoers
sed -i '/NOPASSWD/ s/^#\%wheel/%wheel/g' /etc/sudoers
sed -i '/requiretty/ s/^Defaults/#Defaults/g' /etc/sudoers
egrep 'requiretty|NOPASSWD:' /etc/sudoers

