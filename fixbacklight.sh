#!/bin/bash
#
# Asus UX32VD acpi backlight fix
#
# Copyright(C) 2012 Eugen Dahm <eugen.dahm@gmail.com>.
#
# fix is based on a proposed bugfix posted on <https://bugs.freedesktop.org/show_bug.cgi?id=45452>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Asus UX32VD acpi backlight fix
# Disclaimer!!!! not recommended to use if laptop is not the Asus UX32VD
# probably works with other models too, but the didl and cadl offset needs to be extracted
# from the dsdt
# Tested with bios 2.06

# IGDM_BASE has to be determined for each notebook
# IGDM is the operation region (\_SB_.PCI0.GFX0.IGDM) containing the CADL/DIDL fields
# \aslb is a named field containing the base-address of the IGDM region
# this address depends on the installed ram
# how to get the address:
# - git clone git://github.com/Bumblebee-Project/acpi_call.git
# - make
# - load module with insmod or copy to /lib/modules/.... and modprobe
# - echo '\aslb' > /proc/acpi/call
# - cat /proc/acpi/call
# - this is the IGDM base address - fill in below

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit -1
fi

BIOS_VERSION="UX32VD.206"
TOTAL_MEMORY="9937592"
DMIDECODE_BIOS_VERSION="bios-version"
function usage {
    echo "usage: ./fixbacklight.sh <start | shutdown>"
}

function bios_version_check {
    bios_version_found=$(dmidecode -s $DMIDECODE_BIOS_VERSION)
    test $bios_version_found != $BIOS_VERSION
    return $?
}

function memcheck {
    mem_found=$(grep -i memtotal /proc/meminfo  | cut -d ' ' -f 9)
    test $mem_found != $TOTAL_MEMORY
    return $?
}

if [  $# -ne 1 ]; then 
    usage
    exit -1
fi

# Bios Version guard
bios_version_check
if [ $? -ne 1 ]; then
    echo "Warning!!!, possible bug detected. Bios version does not match, please verify" > /dev/stderr
    exit -1
fi

#memcheck guard
memcheck
if [ $? -ne 1 ]; then
    echo "Warning!!!, possible bug detected. Memory size doesn't match, found $mem_found kB, but expected $TOTAL_MEMORY kB" > /dev/stderr
    exit -1
fi

IGDM_BASE=0xBE8B7018
DIDL_OFFSET=0x120
CADL_OFFSET=0x160

# check if IGDM_BASE is initialized
if [ -z $IGDM_BASE ]; then
    echo "IGDM_BASE not initialized. Please determine the IGDM base address, before you continue" > /dev/stderr
    exit -1
fi

# this basically copies the values of the initialized fields DIDL-DDL8 in the IGDM opregion and initializes CADL-CAL8 with it
# CADL-CAL8 are fields, telling the bios that a screen or something is connected (this is a bit speculation - check 
# <https://bugs.freedesktop.org/show_bug.cgi?id=45452> for more
# if interested, disasselbe the dsdt to understand, why no notifyevent gets thrown, when CADL isn't initialized 
# (hint: _Q0E/_Q0F are the backlight methods on the UX32VD)
action="$1"
if [ "$action" = "start" ] ; then
    dd if=/dev/mem skip=$(( $IGDM_BASE + $DIDL_OFFSET )) of=/dev/mem seek=$(( $IGDM_BASE + $CADL_OFFSET )) count=32 bs=1
elif [ "$action" = "shutdown" ]; then
    perl -e 'print "\x00"x32' | dd of=/dev/mem bs=1 seek=$(( $IGDM_BASE + $CADL_OFFSET )) count=32
else
    echo "action $action unknown" > /dev/stderr
    usage
    exit -1
fi

