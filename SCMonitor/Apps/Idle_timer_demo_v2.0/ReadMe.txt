SCP App: Idle timer event demo

A timer event routine is executed periodically when SCM is idle. In this
case a '+' character is output to the terminal every second while SCM is
idle (waiting for the user to type a command).


*****************************************************************************
v2.0

This includes a patch to fix work around the bug in SCM v1.3.0 for Z80 systems

The code starts at $8000, so is started with the Monitor command "G 8000".

This SCM App is designed to demonstrate the use of SCM's idle timer events.

A timer event routine is executed periodically when SCM is idle. In this
case a '+' character is output to the terminal every second while SCM is
idle (waiting for the user to type a command).

The SCM command "API 13 0" will stop the idle events being processed.


*****************************************************************************
v1.0

WARNING: This does not work with SCM v1.3.0 for Z80 systems due to a bug in SCM

The code starts at $8000, so is started with the Monitor command "G 8000".

This SCM App is designed to demonstrate the use of SCM's idle timer events.

A timer event routine is executed periodically when SCM is idle. In this
case a '+' character is output to the terminal every second while SCM is
idle (waiting for the user to type a command).

The SCM command "API 13 0" will stop the idle events being processed.
