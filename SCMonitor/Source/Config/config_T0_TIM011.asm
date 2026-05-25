; **********************************************************************
; **  Build Small Computer Monitor Configuration SC722+721    native  **
; **********************************************************************

; Include standard configuration stuff
#INCLUDE    Config\Common\Config_Standard.asm

; Build date
#DEFINE     CDATE "20260525"    ;Build date is embedded in the code

; Configuration identifiers
kConfMajor: .SET 'T'            ;Config: Letter = official, number = user
kConfMinor: .SET '0'            ;Config: 1 to 9 = official, 0 = user
#DEFINE     CNAME "TIM-011"     ;Configuration name (max 11 characters)

; ROM filing system
kROMBanks:  .SET 1              ;Number of software selectable ROM banks
kROMTop:    .SET 0x7F           ;Top of banked ROM (hi byte only)

; Hardware ID (use HW_UNKNOWN if not for a very specified product)
kConfHardw: .SET HW_TIM011      ;Hardware identifier (if known)

; Console devices
kConDef:    .SET 1              ;Default console device (1 to 6)
kBaud1Def:  .SET 0x38           ;Console device 1 default baud rate 
kBaud2Def:  .SET 0x38           ;Console device 2 default baud rate 
kBaud3Def:  .SET 0x38           ;Console device 3 default baud rate 
kBaud4Def:  .SET 0x38           ;Console device 4 default baud rate 

; Simple I/O ports
kPrtIn:     .SET 0x00           ;General input port
kPrtOut:    .SET 0x00           ;General output port

; Handle special requirements when building as CP/M style .COM file
#IFDEF      BUILD_AS_COM_FILE
kCode:      .SET 0x0100         ;Code starts at 0x0100 (not 0x0000)
#DEFINE     DO_NOT_REMAP_MEMORY ;Leave memory mapping hardware unchanged
#UNDEFINE   IncludeRomFS        ;Do not include RomFS
#ENDIF

; System options
;#DEFINE    ROM_ONLY            ;No option to assemble to upper memory
;#DEFINE    EXTERNALOS          ;Run from external OS (eg. CP/M)


; **********************************************************************
; Included BIOS support for optional hardware

;TIM011 Motherboard (Z180 CPU, RAM, ROM, Clock)
#INCLUDE    Config\Modules\TIM011.asm

; **********************************************************************
; Any required customisations should be here, eg:
; kSIO1:  .SET 0x80             ;Base address of serial Z80 SIO #1


; **********************************************************************
; Build the code

#INCLUDE    System\Begin.asm

#INCLUDE    BIOS\SCZ180\Manager.asm

#INCLUDE    System\End.asm

#IFNDEF     BUILD_AS_COM_FILE
#INCLUDE    Config\Common\ROM_Info_SC32k.asm
#ENDIF



















