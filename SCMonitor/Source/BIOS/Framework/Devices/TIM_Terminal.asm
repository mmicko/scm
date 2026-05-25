
            .CODE

; Interface descriptor
            .DB  0              ;Device ID code (not currently used)
            .DW  @String        ;Pointer to device string
            .DW  TIMTERM_Init   ;Pointer to initialisation code
            .DB  0              ;Hardware flags bit mask
            .DW  TIMTERM_Set    ;Point to device settings code
            .DB  1              ;Number of console devices
            .DW  TIMTERM_RxA    ;Pointer to 1st channel input code
            .DW  TIMTERM_TxA    ;Pointer to 1st channel output code
@String:    .DB  "TIM Terminal "
            .DB  "@ HW"
            .DB  kNull


; Initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
TIMTERM_Init:
; Fill screen memory
            LD      BC,0x8000
Loop:
            LD      A,0xAA
            OUT     (C),A
            INC     BC
            BIT     7,B
            JR      NZ,Loop
; Initialisation complete
            XOR  A              ;Flag success
            RET                 ;  and return

; Input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if a character has been found
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TIMTERM_RxA:
            ;JP   kJumpTab+0x30  ;Input from console device 1
            JP   kJumpTab+0x36  ;Input from console device 2


; Output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TIMTERM_TxA:
            JP   kJumpTab+0x33  ;Output to console device 1


; Device settings
;   On entry: No parameters required
;   On entry: A = Property to set: 1 = Baud rate
;             B = Baud rate code
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
TIMTERM_Set:  XOR  A              ;Return failed to set (Z flagged)
            RET


; **********************************************************************
; **  Variables
; **********************************************************************

            .DATA

; No variables used


; **********************************************************************
; **  End of driver                                                   **
; **********************************************************************

