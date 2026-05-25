Memory test program version 2.0 for use with SCMonitor.

This memory test is for Z80 systems with a full 64K of RAM and a mechanism
to page out the ROM (via port 0x38).

Load the program into the target system by sending the hex file from a terminal program.

The code starts at $8000, so is started with the Monitor command "G 8000".



This SCM App is designed to test the memory of a Z80 system that  
initially has ROM in lower 32k of memory and RAM in upper 32k, but 
has the ability to page out the ROM and page in the lower 32k of 
RAM by a write to port 0x38.

The test sequence is as follows:
1/ Test upper 32k of RAM except for memory used by this App
2/ Copy the bottom 100 bytes of ROM contents to upper 32k of RAM
3/ Page out ROM and page in lower 32k of RAM
4/ Test lower 32k of RAM
5/ Compare bottom 32k of ROM with RAM copy to see if ROM paged out

Upper 32K memory test:
If a failure is found the faulty address is stored at <result>
otherwise <result> contains 0x0000

Lower 32K memory test: 
The ROM is paged out so there is RAM from 0x0000 to 0x7FFF
This RAM is then tested
If a failure is found the faulty address is stored at <result>
otherwise <result> contains 0x8000
