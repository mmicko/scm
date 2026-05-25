; **********************************************************************
; **  SCM App: Idle Timer Events Demo           by Stephen C Cousins  **
; **********************************************************************

; This SCM App is designed to demonstrate the use of SCM's idle timer 
; events. A timer event routine is executed periodically when SCM is
; idle.


            .PROC Z80           ;SCWorkshop select processor

            .ORG 0x8000

; Output "About" message
            LD   DE,MsgAbout    ;About message
            CALL Msg            ;Output message

; Set up timer 3
            LD   A,10           ;Interval = A x 100ms
            LD   DE,Event       ;Event routine
            LD   C,0x16         ;API 0x16
            RST  0x30           ;  = Timer 3 control

; Enable idle events
            LD   A,1            ;Enable
            LD   C,0x13         ;API 0x13
            RST  0x30           ;  = Configure idle events

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
MsgAbout:   .DB  "SCM App: Idle Timer Demo",  0x0D,0x0A,0


