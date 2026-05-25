; **********************************************************************
; **  Configuration file                        by Miodrag Milanovic  **
; **  Module: TIM-011 native mode                                     **
; **********************************************************************

; This card contains a Z180 CPU, ROM, RAM, Clock, Reset, Serial port

; Processor
#DEFINE     PROCESSOR Z180      ;Processor type "Z80", "Z180"
kCPUClock:  .SET 12288000       ;CPU clock speed in Hz
kZ180Base:  .SET 0x00           ;Z180 internal register base address

; ROM filing system
kROMBanks:  .SET 1              ;Number of software selectable ROM banks

; Status LED
;#IFNDEF     INCLUDE_StatusLED
;kPrtLED:    .SET 0x0E           ;Single status LED port (active low)
;#DEFINE     INCLUDE_StatusLED
;#ENDIF

; Z180 ASCI
#IFNDEF     INCLUDE_ASCI_n1
kASCI1:     .SET kZ180Base+0x00 ;Base address of Z180 serial ports (CNTLA0)
#DEFINE     INCLUDE_ASCI_n1     ;Include ASCI #1 
#ENDIF





