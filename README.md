fixasusbacklight
================

This is a little tool to fix the ux31a/ux32vd acpi backlight buttons during runtime
It patches the IGDM opregion mapped into virtual memory during runtime to fix the not working backlight control
buttons on the UX31A/UX32VD zenbooks.

Requirements:
 * dmidecode (used to check against bios version
 * [acpi_call](https://github.com/Bumblebee-Project/acpi_call) to extract the IGDM Base address

How to use acpi_call:
 * download and compile acpi_call with make
 * load module with insmod or with copying to /lib/modules/... and modprobe it
 * echo '\aslb' > /proc/acpi/call
 * cat /proc/acpi/call
 * this is the IGDM base address - fill in the IGDM_BASE variable in the script

Known IGDM Base Addresses
 * Asus UX31A v2.06:    0xBE8B7018
 * Asus UX32VD v2.06:   0xBE8B7018

Known DIDL/CADL Offsets
 * Asus UX31A v2.06:  DIDL: 0x120, CADL: 0x160 
 * Asus UX32VD v2.06: DIDL: 0x120, CADL: 0x160 

IGDM base address probably differs with each bios version.

Problems:

If this script produces a kernel panic, its most likely that the bios version doesn't match the baseaddress and/ or
offsets. Currently the script has a bios check to stop execution if the bios string returned by 
`dmidecode -s bios-version` doesn't match the BIOS_VERSION variable in the script (so change according to your bios)

Extrating the DIDL/CADL Offsets:

 1. dump the bios with acpidump to file
 2. extract dsdt tables with acpixtract <file>
    this should create some files, one beeing something like dsdt.dsl (the file with .dsl is the important file)
 3. find the IGDM opregion in this file. This should look something like this:
    	 OperationRegion (IGDM, SystemMemory, ASLB, 0x2000)
    	 Field (IGDM, AnyAcc, NoLock, Preserve)
    	 {
		SIGN,   128, 
		SIZE,   32, 
		OVER,   32, 
		...
 4. The numbers represent the size of each element in bits. Add all numbers until you reach the DIDL and CADL 
    offset. If you encounter something like `offset(120)` you can throw away the calculated value and continue with
    this offset (don't forget this offset is in bytes, not bits). 
 5. Fill the DIDL/CADL offsets with the calculated values.
 6. *Thumbs pressed* that it works