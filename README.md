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

<h2>Known IDGM Base Addresses</h2>

<table border="1">
       <tr>
        <th>Bios Version</th>
        <th>Asus UX31E</th>
	<th>Asus UX31A</th>
	<th>Asus UX32VD</th>
	<th>Asus N56VZ</th>
	<th>Asus N56VM</th>
       </tr>
       <tr>
	<td>2.06</td>
	<td>0xBE8B7018</td>
	<td>0xBE8B7018</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr>
	<td>2.11</td>
	<td>0xDA8A9018</td>
	<td>0xCA882018</td>
	<td>0xCA876018</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr>
	<td>2.12</td>
	<td>???</td>
	<td>0xCA882018</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr>
	<td>2.14</td>
	<td>0xBAE79018</td>
	<td>???</td>
	<td>???</td>
	<td>0xAE87E018</td>
	<td>???</td>
       </tr>
</table>

<h2>Known DIDL/CADL Offsets</h2>

<table border="1">
       <tr>
	<th>Bios Version</th>
        <th>Asus UX31E</th>
	<th>Asus UX31A</th>
	<th>Asus UX32VD</th>
	<th>Asus N56VZ</th>
	<th>Asus N56VM</th>
       </tr>
       <tr align="center">
	<td>2.06</td>
        <td>0x120 / 0x160</td>
	<td>0x120 / 0x160</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr align="center">
	<td>2.11</td>
        <td>&ndash;||&ndash;</td>
	<td>&ndash;||&ndash;</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr align="center">
	<td>2.12</td>
        <td>&ndash;||&ndash;</td>
	<td>&ndash;||&ndash;</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
       <tr align="center">
	<td>2.14</td>
	<td>0x120 / 0x160</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
	<td>???</td>
       </tr>
</table>

IGDM base address probably differs with each bios version.

Problems:

If this script produces a kernel panic, its most likely that the bios version doesn't match the baseaddress and/ or
offsets. Currently the script has a bios check to stop execution if the bios string returned by 
`dmidecode -s bios-version` doesn't match the BIOS_VERSION variable in the script (so change according to your bios)

Extrating the DIDL/CADL Offsets:

 1. dump the bios with acpidump to file
 2. extract dsdt tables with acpixtract &lt;file&gt;
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
    offset. If you encounter something like `offset(0x120)` you can throw away the calculated value and continue with
    this offset (don't forget this offset is in bytes, not bits). 
 5. Fill the DIDL/CADL offsets with the calculated values.
 6. *Thumbs pressed* that it works

How to execute:
 * chmod +x fixbacklight.sh
 * sudo ./fixbacklight.sh &lt;start | shutdown&gt; 
 * optionally copy to /usr/local/share and let it execute by /etc/rc.local
 * on shutdown ./fixbacklight.sh shutdown (since it apprently causes some strange bug - sometimes the harddrive doesn't get detected on the next softreboot - idfk why). - add it to /etc/rc.shutdown
