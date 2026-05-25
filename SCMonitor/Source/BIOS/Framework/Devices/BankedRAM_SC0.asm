; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware: Default                                               **
; **  Interface: Banked RAM                                           **
; **********************************************************************

; SCM BIOS framework compliant driver for banked RAM type SC0.

; RAM banks not implemented!


            .CODE


; **********************************************************************
; Read from banked RAM          NOT IMPLEMENTED
;   On entry: DE = Address in secondary bank
;   On exit:  A = Byte read from RAM
;             F BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_RdRAM:    RET


; **********************************************************************
; Write to banked RAM           NOT IMPLEMENTED
;   On entry: A = Byte to be written to RAM
;             DE = Address in secondary bank
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_WrRAM:    RET


; **********************************************************************
; **  End of device driver                                            **
; **********************************************************************



