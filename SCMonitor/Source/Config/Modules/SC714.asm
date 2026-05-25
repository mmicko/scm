; **********************************************************************
; **  Configuration file                        by Stephen C Cousins  **
; **  Module: SC714 (Z80 memory 512k FLASH + 512k RAM for RCBus)      **
; **********************************************************************

; This card contains a MMU @ 0x78, ROM 512k, RAM 512k

; RAM fixed from 0x8000 to 0xFFFF
; ROM or RAM paged into 0x0000 to 0x7FFF

; The hardware interface consists of:
; 32 banks of 32k bytes (bank number 31)
; 16 x ROM (banks 0 to 15)
; 16 x RAM (banks 16 to 31)
; 32k Bank select: port <kBankPrt> bits 1 to 5 (bank number x 2)


; Memory banks not currently implemented


; ROM filing system
kROMBanks:  .SET 1              ;Number of software selectable ROM banks
kROMTop:    .SET 0x7F           ;Top of banked ROM (hi byte only)

; Banked RAM                    No bank selection implemented
#IFNDEF     INCLUDE_BankedRAM_SC0
#DEFINE     INCLUDE_BankedRAM_SC0
#ENDIF

; Banked ROM                    No bank selection impemented 
#IFNDEF     INCLUDE_BankedROM_SC0
#DEFINE     INCLUDE_BankedROM_SC0
#ENDIF


