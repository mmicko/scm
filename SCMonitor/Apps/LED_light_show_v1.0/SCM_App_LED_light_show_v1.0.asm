; **********************************************************************
; **  LED light show                            by Stephen C Cousins  **
; **********************************************************************

; This App creates a light show via 8 LEDs on an output port.

; Port addresses are typically:
;   0x00 for RC2014
;   0x0D for SC126's build in LEDs
;   0xA0 for SC500 series Z50Bus designs

kPort:      .EQU  0x0D          ;LED port address

            .PROC Z80           ;SCWorkshop select processor

            .ORG 0x8000

Start:      LD   HL,Data        ;Point to start of LED data table
Next:       LD   A,(HL)         ;Get byte from data table
            OUT  (kPort),A      ;Output byte to LED port
            CALL Delay          ;Delay
            INC  HL             ;Increment table pointer
            LD   A,L            ;Get low byte of table pointer
            CP   kEndLo         ;End of table?
            JR   NZ,Next        ;No, so go get next byte from table
            JR   Start          ;Ye, so go back to start of table
            
Delay:      PUSH HL             ;Preserve HL
            PUSH DE             ;Preserve DE
            PUSH BC             ;Preserve BC
            LD   DE,100         ;Delay time = X ms
            LD   C,0x0A         ;API 0x0A
            RST  0x30           ;  = Delay by DE ms
            POP  BC             ;Restore BC
            POP  DE             ;Restore DE
            POP  HL             ;Restore HL
            RET

; LED data table
Data:       DB 0b00000000
            DB 0b00000001
            DB 0b00000010
            DB 0b00000100
            DB 0b00001001
            DB 0b00010010
            DB 0b00100100
            DB 0b01001001
            DB 0b10010010
            DB 0b00100100
            DB 0b01001001
            DB 0b10010010
            DB 0b00100100
            DB 0b01001001
            DB 0b10010010
            DB 0b00100100
            DB 0b01001000
            DB 0b10010000
            DB 0b00100000
            DB 0b01000000
            DB 0b10000000
            DB 0b00000000

            DB 0b10000001
            DB 0b01000010
            DB 0b00100100
            DB 0b00011000
            DB 0b00000000
            DB 0b00011000
            DB 0b00100100
            DB 0b01000010
            DB 0b10000001
            DB 0b00000000

kEndLo:     .EQU  $ & 0xFF      ;Lo byte of end address


; Consider combining this with the idle timer event demo to create
; a light show that continues while you do other things.


