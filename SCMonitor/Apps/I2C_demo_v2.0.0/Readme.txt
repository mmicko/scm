This is an example of how to use I2C devices with bus masters such as SC126 and SC137.

The program has been written in assembler using the Small Computer Workshop (SCW). 

The HEX file can be "sent" from a terminal program, such as Tera Term, to a Z80 system 
running the Small Computer Monitor (SCM). The program can then be executed with the 
command "G 8000".

The example program scans all possible I2C bus addresses looking for devices. The address 
of any device found is then displayed in HEX. The address format is the full 8-bit value 
where bit zero indicates write (low) or read (high).

It is assumed that devices in the SC400 series are configured to their default addresses.
Each device is then performs a short demonstration. Any devices not compatible with the
SC400 series could confuse this example code!

WARNING: I2C memory devices are written to as part of the demonstration and this could
delete any data stored in that memory device.


Stephen Cousins
Small Computer Central
www.scc.me.uk
