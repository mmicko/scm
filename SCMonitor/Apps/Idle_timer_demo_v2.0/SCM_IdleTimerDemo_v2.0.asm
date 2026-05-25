; **********************************************************************
; **  SCM App: Idle Timer Events Demo           by Stephen C Cousins  **
; **  Warning: Version number is embedded in the About message        **
; **********************************************************************

; This SCM App is designed to demonstrate the use of SCM's idle timer 
; events. A timer event routine is executed periodically when SCM is
; idle. The demo can be stopped with the SCM command: API 13 0

; THe App uses idle events to output a '+' character to the terminal
; every second when SCM is idle - typically when waiting for a key to be
; pressed. The interval is only very approximate on systems without
; hardware timers. 
; SCM can still be used while the plus signs are being output.

; If the hardware includes a primary Z80 CTC then the CTC will be used 
; to generate the events, otherwise software loop counting is used.
; Software loop counting is not accurate as it is unknown how long the
; firmware takes to handle other activity. In the case of systems using
; a bit-bang serial port the events are many times slower than for
; hardware (UART style) serial ports.

; The App includes a patch to SCM to fix a bug in Z80 configurations
; of SCM v1.3. Do not include the patch when running on Z180 systems.

#DEFINE     PROCESSOR           Z80

#IF         PROCESSOR = "Z80"
#DEFINE     INCLUDE_PATCH
            .PROC Z80           ;SCWorkshop select processor
#ENDIF
#IF         PROCESSOR = "Z180"
            .PROC Z180          ;SCWorkshop select processor
#ENDIF

            .ORG 0x8000


; Patch SCM to fix a bug in Z80 configurations of SCM v1.3
#IFDEF      INCLUDE_PATCH
            CALL Patch          ;Patch SCM to fix SCM v1.3 bug
#ENDIF

; Output "About" message
            LD   DE,MsgAbout    ;About message
            CALL Msg            ;Output message

; Set up timer 3
            LD   A,10           ;Interval = A x 100ms
            LD   DE,Event       ;Event routine
            LD   C,0x16         ;API 0x16
            RST  0x30           ;  = Timer 3 control

; Enable idle events (without using patch)
#IFNDEF     INCLUDE_PATCH
            LD   A,1            ;Enable
            LD   C,0x13         ;API 0x13
            RST  0x30           ;  = Configure idle events
#ENDIF

; Return to SCM
            RET

; Timer event to output a '+'
Event:      LD   A,'+'
            LD   C,0x02         ;API 2
            RST  0x30           ;  = Output character in A
            RET

; Output message at DE
; AF, BC, DE, HL preserved
Msg:        PUSH AF
            PUSH BC
            PUSH DE
            PUSH HL
            LD   C,0x06         ;API 6
            RST  0x30           ;  = Output message at DE
            POP  HL
            POP  DE
            POP  BC
            POP  AF
            RET

; Messages
MsgAbout:   .DB  "SCM App: Idle Timer Demo v2.0.0",  0x0D,0x0A,0


; **********************************************************************
; **  Patch SCM due to bug in v1.3 of Z80 builds (Z180 builds okay)   **
; **********************************************************************

#IF         PROCESSOR = "Z80"

kPollInc:   .EQU 9              ;Increment timer by X each time polled
kCTC:       .EQU 0x88           ;Base address for primary Z80 CTC

Patch:
; Determine if the system includes a primary Z80 CTC
            LD   C,8            ;API 8
            RST  0x30           ;  = Get version details
            BIT  4,L            ;Primary CTC present?
            JR   Z,InstSoft     ;No, so go install software loop handler

; Prepare to install idle time handler using Z80 CTC for timing
; Assume CTC channel 2 is already set for 5ms interval
;            LD   A,0b00110101   ;Timer: 7372800Hz/256 = 28800Hz
;            OUT  (kCTC+2),A     ;Write channel 2's control register
;            LD   A,144          ;28800Hz/144 = 200 Hz
;            OUT  (kCTC+2),A     ;Write channel 2's time base
            LD   DE,PollCTC     ;Start of CTC idle handler code
            JR   Install        ;Go install CTC timer handler

; Prepare to install idle time handler using software loop for timing
InstSoft:   LD   DE,PollSoft    ;Start of default idle handler code

; Install custom idle handler code (code starts at DE)
Install:    LD   A,0x0C         ;Jump table entry number (idle handler)
            LD   C,9            ;API 9
            RST  0x30           ;  = Claim/write jump table entry
            RET

; Idle time handler using software loop for timing
PollSoft:   LD   A,(iIdleCount) ;Get loop counter
            ADD  A,kPollInc     ;Add to loop counter
            LD   (iIdleCount),A ;Store updated counter
            JR   C,RollOver     ;Skip if roll over (1ms event)
            XOR   A             ;No event so Z flagged and A = 0
            RET
RollOver:   OR    0xFF          ;1ms event so NZ flagged and A != 0
            RET

; Idle time handler using Z80 CTC for timing
PollCTC:    PUSH HL
            LD   HL,iHwPrevTim  ;Point to previous (down counter)
            IN   A,(kCTC+2)     ;A = current (down counter)
            CP   (HL)           ;Compare (current - previous)
            LD   (HL),A         ;Update previous value
            LD   HL,iHwBacklog  ;Point to backlog (of 1ms events)
            LD   A,(HL)         ;Get backlog (of 1ms events)
            JR   C,@NoRoll      ;Skip if current < previous
            JR   Z,@NoRoll      ;Skip if current = previous
            ADD  A,5            ;Add 5ms to backlog (of 1ms events)
@NoRoll:    OR   A              ;Any backlog of events to process?
            JR   Z,@NoEvent     ;No, so skip
            PUSH AF             ;Preserve Z flag and A register
            DEC  A              ;Decrement backlog (of 1ms events)
            LD   (HL),A         ;Update backlog (of 1ms events)
            POP  AF             ;Restore Z flag and A register
@NoEvent:   POP  HL
            RET


; Workspace
iIdleCount: .DB  0              ;Timer polling, idle time counter
iHwPrevTim: .DB  0              ;Timer polling, previous timer reading
iHwBacklog: .DB  0              ;Timer polling, backlog of 1ms events

#ENDIF



