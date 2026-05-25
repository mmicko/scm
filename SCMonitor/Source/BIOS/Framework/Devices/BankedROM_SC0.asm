; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware: Default                                               **
; **  Interface: Banked ROM                                           **
; **********************************************************************

; SCM BIOS framework compliant driver for banked ROM type SC0.

; A single 32k ROM without support for multiple banks


            .CODE


; **********************************************************************
; Copy from banked ROM to RAM
;   On entry: A = ROM bank number (0 to n)
;             HL = Source start address (in ROM)
;             DE = Destination start address (in RAM)
;             BC = Number of bytes to copy
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_CopyROM:  LDIR                ;Only one bank so just copy memory
            RET


; **********************************************************************
; Execute code in ROM bank
;   On entry: A = ROM bank number (0 to 3)
;             DE = Absolute address to execute
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_ExecROM:  PUSH DE             ;Jump to DE by pushing on
            RET                 ;  to stack and 'returning'


; **********************************************************************
; **  End of device driver                                            **
; **********************************************************************


