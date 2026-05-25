; **********************************************************************
; **  Device Driver                             by Stephen C Cousins  **
; **  Hardware: SC714, and compatibles                                **
; **  Interface: Banked RAM                                           **
; **********************************************************************

; TODO

; RAM banks not implemented!

; SCM BIOS framework compliant driver for banked RAM type SC3.
; RAM fixed from 0x8000 to 0xFFFF
; ROM or RAM paged into 0x0000 to 0x7FFF

; The hardware interface consists of:
; 32 banks of 32k bytes (bank number 31)
; 16 x ROM (banks 0 to 15)
; 16 x RAM (banks 16 to 31)
; 32k Bank select: port <kBankPrt> bits 1 to 5 (bank number x 2)
;
; Externally definitions required:
;kBankPrt:  .EQU 0x78           ;Bank select register


            .CODE


; **********************************************************************
; Read from banked RAM          NOT IMPLEMENTED
;   On entry: DE = Address in secondary bank
;   On exit:  A = Byte read from RAM
;             F BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_RdRAM:
#IFDEF      NOCHANCE
            LD   C,kBankPrt     ;Bank select port address
            LD   B,1            ;Make B=1
            OUT  (C),B          ;Select secondary RAM bank
            LD   A,(DE)         ;Read from RAM
            DEC  B              ;Make B=0
            OUT  (C),B          ;Select primary RAM bank
#ENDIF
            RET


; **********************************************************************
; Write to banked RAM           NOT IMPLEMENTED
;   On entry: A = Byte to be written to RAM
;             DE = Address in secondary bank
;   On exit:  AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
H_WrRAM:
#IFDEF      NOCHANCE
            LD   C,kBankPrt     ;Bank select port address
            LD   B,1            ;Make B=1
            OUT  (C),B          ;Select secondary RAM bank
            LD   (DE),A         ;Write to RAM
            DEC  B              ;Make B=0
            OUT  (C),B          ;Select primary RAM bank
#ENDIF
            RET


; **********************************************************************
; **  End of device driver                                            **
; **********************************************************************





