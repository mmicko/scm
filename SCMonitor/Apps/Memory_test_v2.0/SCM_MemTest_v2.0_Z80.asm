; **********************************************************************
; **  Memory test for RC2014 etc                by Stephen C Cousins  **
; **********************************************************************

; This SCM App is designed to test the memory of a Z80 system that  
; initially has ROM in lower 32k of memory and RAM in upper 32k, but 
; has the ability to page out the ROM and page in the lower 32k of 
; RAM by a write to port 0x38.

; The test sequence is as follows:
; 1/ Test upper 32k of RAM except for memory used by this App
; 2/ Copy the bottom 100 bytes of ROM contents to upper 32k of RAM
; 3/ Page out ROM and page in lower 32k of RAM
; 4/ Test lower 32k of RAM
; 5/ Compare bottom 32k of ROM with RAM copy to see if ROM paged out

; Lower 32K memory test: 
; The ROM is paged out so there is RAM from 0x0000 to 0x7FFF
; This RAM is then tested
; If a failure is found the faulty address is stored at <result>
; otherwise <result> contains 0x8000
;
; Upper 32K memory test:
; If a failure is found the faulty address is stored at <result>
; otherwise <result> contains 0x0000


            .PROC Z80           ;SCWorkshop select processor

Result:     .EQU 0x9000         ;Last address is stored here on exit

            .ORG 0x8000

; Output "About" message
            LD   DE,MsgAbout    ;About message
            CALL Msg            ;Output message

; Test upper 32K of RAM
            LD   DE,MsgUpper    ;Upper memory test message
            CALL Msg            ;Output message
            LD   HL,BeginTest   ;Start location
@Upper:     LD   A,(HL)         ;Current contents
            LD   C,A            ;Store current contents
            CPL                 ;Invert bits
            LD   (HL),A         ;Write test pattern
            CP   (HL)           ;Read back and compare
            JR   NZ,@HiEnd      ;Abort if not the same
            LD   A,C            ;Get original contents
            LD   (HL),A         ;Restore origianl contents
            CP   (HL)           ;Read back and compare
            JR   NZ,@HiEnd      ;Abort if not the same
            INC  HL             ;Point to next location
            LD   A,H
            CP   0x00           ;Have we finished?
            JR   NZ,@Upper
@HiEnd:     LD   (Result),HL    ;Store current address
            LD   A,H
            CP   0x00           ;Pass?
            CALL Z,Passed       ;Yes, so go report pass
            CALL NZ,Failed      ;No, so go report fail

; Copy first 100 bytes of ROM to RAM
            LD   DE,BeginTest   ;Start of RAM copy
            LD   HL,0           ;Start of ROM
            LD   BC,100         ;Bytes to be copied
            LDIR                ;Copy to RAM

; Test lower 32k of RAM
            LD   DE,MsgLower    ;Lower memory test message
            CALL Msg            ;Output message
            CALL ROM_out        ;Page out ROM
            LD   HL,0x0000      ;Start location
@Lower:     LD   A,(HL)         ;Current contents
            LD   C,A            ;Store current contents
            CPL                 ;Invert bits
            LD   (HL),A         ;Write test pattern
            CP   (HL)           ;Read back and compare
            JR   NZ,@LoEnd      ;Abort if not the same
            LD   A,C            ;Get original contents
            LD   (HL),A         ;Restore origianl contents
            CP   (HL)           ;Read back and compare
            JR   NZ,@LoEnd      ;Abort if not the same
            INC  HL             ;Point to next location
            LD   A,H
            CP   0x80           ;Have we finished?
            JR   NZ,@Lower
@LoEnd:     CALL ROM_in         ;Page ROM back in
            LD   (Result),HL    ;Store current address
            LD   A,H
            CP   0x80           ;Pass?
            CALL Z,Passed       ;Yes, so go report pass
            CALL NZ,Failed      ;No, so go report fail

; Test if ROM is not being paged out
; Earlier we copied the bottom of memory (the ROM) to upper RAM
; We now page out the ROM and page in RAM in its place
; If this works correctly the bottom of memory will not match the ROM copy 
; If the bottom of memory matches the copy then the ROM has not been paged out
            LD   DE,MsgPage     ;ROM page out test message
            CALL Msg            ;Output message
            CALL ROM_out        ;Page out ROM
            LD   DE,BeginTest   ;Start of RAM copy of ROM
            LD   HL,0           ;Bottom of memory
            LD   B,100          ;Bytes to be compared
@Compare:   LD   A,(DE)         ;Get byte from RAM copy of ROM
            CP   (HL)           ;Same as bottom of memory?
            JR   NZ,@CompEnd    ;No, so abort (ROM not present)
            INC  HL             ;Increment ROM pointer
            INC  DE             ;Increment RAM pointer
            DJNZ @Compare       ;Repeat for all test locations
@CompEnd:   CALL ROM_in         ;Page ROM back in
            LD   (Result),HL    ;Store current address
            LD   A,B            ;Get locations left to test
            OR   A              ;Zero? (zero means ROM present)
            CALL NZ,Passed      ;Report pass 
            CALL Z,Failed       ;Report fail

            RET                 ;End App

; Page out ROM (and page in RAM)
ROM_out:    LD   A,1            ;So it works on LiNC80 etc
            OUT  (0x38),A       ;Page out ROM
            RET

; Page in ROM (and page out RAM)
ROM_in:     LD   A,0            ;So it works on LiNC80 etc
            OUT  (0x38),A       ;Page out ROM
            RET

; Output "Fail" message
Failed:     LD   DE,MsgFail     ;Start of "Failed" message
            JR   Msg

; Output "Pass" message
Passed:     LD   DE,MsgPass     ;Start of "Passed" message
            JR   Msg

; Output message at DE
; AF, BC, DE, HL preserved
Msg:        PUSH AF
            PUSH BC
            PUSH DE
            PUSH HL
            LD   C,6            ;API 6
            RST  0x30           ;  = Output message at DE
            POP  HL
            POP  DE
            POP  BC
            POP  AF
            RET

; Messages
MsgAbout:   .DB  "Z80 64k memory test v2.0 by Stephen C Cousins",  0x0D,0x0A,0
MsgUpper:   .DB  "Upper 32k RAM: ",0
MsgLower:   .DB  "Lower 32k RAM: ",0
MsgPage:    .DB  "ROM page out test: ",0
MsgPass:    .DB  "Pass",  0x0D,0x0A,0
MsgFail:    .DB  "Fail",  0x0D,0x0A,0

BeginTest:  ; Upper memory test begins here








