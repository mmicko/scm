; **********************************************************************
; **  Compact Flash Test                        by Stephen C Cousins  **
; **********************************************************************
;
; **  Written as a Small Computer Monitor App 
; **  www.scc.me.uk
;
; SCC  2018-06-02 : v0.4.1  Stable version
; SCC  2022-02-11 : v0.5.0  Added support for CF card at address CF_BASE
; SCC  2022-03-02 : v1.0.0  Minor tidy of source for v1.0 release
; SCC  2022-03-02 : v1.1.0  CF card I/O address set at runtime
; SCC  2023-01-08 : v1.2.0  Improved to detect known dodgy card
;
; **********************************************************************
;
; This App reads compact flash card identification information and 
; displays some of it.
;
; **********************************************************************

            .PROC Z80           ;SCWorkshop select processor
            .HEXBYTES 0x18      ;SCWorkshop Intel Hex output format

; Define target system
#DEFINE     GENERIC
;#DEFINE    Z280RC

; Define target's possible CF card addresses
CF_BASE1    .EQU 0x10           ;Base address = 0x10 (default for RC2014 and LiNC80)
CF_BASE2    .EQU 0x90           ;Base address = 0x90 (default for Z50Bus)
;CF_BASE    .EQU 0xC0           ;Base address = 0xC0 (default for Z280RC)

; **********************************************************************
; **  Memory map
; **********************************************************************

CodeORG:    .EQU $8000          ;Loader code runs here
DataORG:    .EQU $8F00          ;Start of data section
BufferWR:   .EQU $9000          ;Data buffer address for write data
BufferRD:   .EQU $9800          ;Data buffer address for read data

; **********************************************************************
; **  Constants
; **********************************************************************

; none


; **********************************************************************
; **  Code library usage
; **********************************************************************

; SCMonitor API functions used
#REQUIRES   aOutputText
#REQUIRES   aOutputNewLine
#REQUIRES   aOutputChar
#REQUIRES   aInputChar
#REQUIRES   aInputStatus

; Utility functions used
#REQUIRES   uOutputHexPref
#REQUIRES   uOutputHexByte
#REQUIRES   uOutputHexWord
#REQUIRES   uOutputDecWord
#REQUIRES   uFindString

; Compact flash functions used
#REQUIRES   cfDiagnose
;#REQUIRES  cfFormat
#REQUIRES   cfInfo
#REQUIRES   cfRead
#REQUIRES   cfSize
;#REQUIRES  cfVerify
;#REQUIRES  cfVerifyF
#REQUIRES   cfWrite
; All other compact flash functions are included by default

; Compact flash options
#DEFINE     CF_FASTEST


; **********************************************************************
; **  Establish memory sections
; **********************************************************************

            .DATA
            .ORG  DataORG       ;Establish start of data section

            .CODE
            .ORG  CodeORG       ;Establish start of code section


; **********************************************************************
; **  Main program code
; **********************************************************************

; Initialise
            CALL cfInit         ;Initialise Compact Flash functions

; Output program details
            LD   DE,About       ;Pointer to error message
            CALL aOutputText    ;Output "Compact flash card test..."
            CALL aOutputNewLine ;Output new line

            CALL aOutputNewLine ;Output new line

; Test if compact flash present at first address
            LD   L,CF_BASE1
            CALL @CardAdd
            JR   NZ,@Err1       ;Device not found so go try next address
            CALL cfTstPres      ;Test if compact flash card is present
            JR   Z,@Start       ;Present, so go format it
@Err1:      CALL ReportErr2     ;Report error and exit program
            CALL aOutputNewLine ;Output new line

; Test if compact flash present at second address
            LD   L,CF_BASE2
            CALL @CardAdd
            JR   NZ,@Err2       ;Device not found so go try next address
            CALL cfTstPres      ;Test if compact flash card is present
            JR   Z,@Start       ;Present, so go format it
@Err2:      JP   ReportErr2     ;Report error and exit program

; Output card address and try to initialise cf code for specified adddress
@CardAdd:   LD   DE,CardAt
            CALL aOutputText    ;Output "Card at address "
            LD   A,L
            CALL uOutputHexByte ;Output address in hex
            LD   A,':'
            CALL aOutputChar    ;Output ':'
            LD   A,' '
            CALL aOutputChar    ;Output ' '
            LD   A,L            ;First try this device address
            JP  cfInit          ;Initialise Compact Flash / functions
;           CALL cfInit         ;Initialise Compact Flash / functions
;           RET

@Start:     CALL aOutputNewLine ;Output new line

; Get Compact flash identification info
            LD   HL,BufferRD    ;Destination address for data read
            CALL cfInfo         ;Read CF identification info
            JP   NZ,ReportErr   ;Report error and exit program

; Display results -> Number of sectors on card
            LD   DE,NumSectors
            CALL aOutputText    ;Output "Number of sectors on card: "
            CALL uOutputHexPref ;Output '$' prefix (or whatever)
            LD   DE,(BufferRD+14)
            LD   (iSize+2),DE   ;Store as card size MSW
            CALL uOutputHexWord ;Output most significant word
            LD   DE,(BufferRD+16)
            LD   (iSize+0),DE   ;Store as card size LSW
            CALL uOutputHexWord ;Output least significant word
            CALL aOutputNewLine

; Adjust end sector number which needs to be 1 less than total as we 
; test in batches of 2 sectors
            XOR  A              ;Clear carry flag
            LD   HL,(iSize+0)
            LD   DE,1
            SBC  HL,DE          ;Subtract 1
            LD   (iSize+0),HL
            LD   HL,(iSize+2)
            LD   DE,0
            SBC  HL,DE          ;Subtract carry flag
            LD   (iSize+2),HL

; Display results -> Card size 
            LD   DE,CardSize
            CALL aOutputText    ;Output "Card size: "
            LD   DE,(BufferRD+14) ;Number of sectors hi word
            LD   HL,(BufferRD+16) ;Number of sectors lo word
            CALL cfSize         ;Get size in DE, units in A
            CALL uOutputDecWord ;Output decimal word DE
            CALL aOutputChar    ;Output units character eg. "M"
            LD   A,'B'          ;Get Bytes character
            CALL aOutputChar    ;Output Bytes character "B"
            CALL aOutputNewLine ;Output new line

; Display results -> Compact Flash diagnostic test result
            LD   DE,Diagnose
            CALL aOutputText    ;Output "Diagnostic... "
            CALL cfDiagnose     ;Run diagnostics and return error code
            JR   NZ,@Failed     ;Did diagnostic pass?
            LD   DE,Passed      ;Passed ...
            CALL aOutputText    ;Output "Passed... "
            JR   @EndDiag
@Failed:    LD   DE,Failed      ;Failed ...
            CALL aOutputText    ;Output "Failed... "
            CALL uOutputHexPref ;Output hext prefix
            CALL uOutputHexByte ;Output result as hex byte
@EndDiag:   CALL aOutputNewLine ;Output new line

            CALL aOutputNewLine ;Output new line

; Warning and confirm
            LD   DE,Warning     ;Pointer to message
            CALL aOutputText    ;Output "WARNING:..."
            CALL aOutputNewLine
@Wait:      LD   DE,Confirm     ;Pointer to message
            CALL aOutputText    ;Output "Are you sure..."
            CALL aInputChar     ;Get key
            CALL aOutputNewLine ;Output new line
            AND  0b01011111     ;Convert lower case to upper case
            CP   'N'
            RET  Z              ;Abort if key = 'N'
            CP   'Y'
            JR   NZ,@Wait       ;If not 'Y' ask again

            CALL aOutputNewLine ;Output new line


; Test compact flash card
; For each sector:
; Fill sector+0 with 0xFF,0xFF,0x00 (repeating)
; Fill sector+1 with 0xAA,0x55,0xF0 (repeating)
; Verify these sectors contain the correct data
; Increment sector number
Test:       XOR A               ;Start at sector zero
            LD  (iSector+0),A
            LD  (iSector+1),A
            LD  (iSector+2),A
            LD  (iSector+3),A
; Test current sector
@Loop:      XOR  A
            LD   (iErrNum),A    ;Clear error number
            LD   (iFailCnt),A   ;Clear failure counter
; Output current sector number
            LD   DE,Sector
            CALL aOutputText    ;Output "Sector being tested: "
            CALL uOutputHexPref ;Output '$' (or whatever)
            LD   DE,(iSector+2)
            CALL uOutputHexWord ;Output most significant word
            LD   DE,(iSector+0)
            CALL uOutputHexWord ;Output least significant word
            LD   A,kSpace
            CALL aOutputChar    ;Output a space
; Prepare data
            LD   HL,BufferWR    ;Start of write buffer
; Fill buffer for 1st sector with repeating pattern 0xFF,0xFF,0x00
            PUSH BC
            PUSH DE
            LD   DE,0xFFFF      ;Test pattern 0xFF,0xFF,0x00 repeating
            LD   A,0x00
            CALL PrepData3      ;Prepare test data buffer
            POP  DE
            POP  BC
; Fill buffer for 2nd sector with repeating pattern 0xAA,0x55,0xF0
            PUSH BC
            PUSH DE
            LD   DE,0xAA55      ;Test pattern 0xAA,0x55,0xF0 repeating
            LD   A,0xF0
            CALL PrepData3      ;Prepare test data buffer
            POP  DE
            POP  BC
            CALL Write          ;Write data in buffer to sector D.E.B
; Write data
; Prepare start sector number (D.E.B) for writing
            LD   A,(iSector+0)
            LD   B,A
            LD   DE,(iSector+1)
; Write to disk
            LD   C,2            ;Number of sectors
            LD   HL,BufferWR    ;Start address of write buffer
            CALL Write          ;Start sector number D.E.B
            JR   NZ,@Fail       ;Report any errors
; Read data
; Prepare start sector number (D.E.B) for writing
@VeriTest:  LD   A,(iSector+0)
            LD   B,A
            LD   DE,(iSector+1)
; Read back from disk
            LD   C,2            ;Number of sectors
            LD   HL,BufferRD    ;Start address of read buffer
            CALL Read           ;Start sector number D.E.B
            JR   NZ,@Fail       ;Report any errors
; Verify data
; Verify read back data
            LD   BC,2*512       ;Number of bytes sectors * 512
            LD   HL,BufferRD    ;Start address of read buffer
            LD   DE,BufferWR    ;Start address of write buffer
@VLoop:     LD   A,(DE)
            CP   (HL)
            JR   NZ, @FailV
            INC  HL
            INC  DE
            DEC  BC
            LD   A,B
            OR   C
            JR   NZ,@VLoop
; Sector test passed
            LD   DE,Passed      ;Passed ...
            CALL aOutputText    ;Output "Passed... "
            CALL aOutputNewLine ;Output new line
; Test for character input
            CALL aInputStatus   ;Character input status?
            RET  NZ             ;Abort if character available
; Increment sector number
@Next:      LD   HL,iSector     ;Point to current sector number
            INC  (HL)           ;Increment...
            JR   NZ,@TstEnd
            INC  HL
            INC  (HL)
            JR   NZ,@TstEnd
            INC  HL
            INC  (HL)
            JR   NZ,@TstEnd
            INC  HL
            INC  (HL)
; Test complete? (ie. reached end of card)
@TstEnd:    LD   HL,iSector     ;Point to current sector number
            LD   DE,iSize       ;Point to card size in sectors
            LD   B,3            ;Number of bytes to compare
@Compare:   LD   A,(DE)         ;Get byte from card size in sectors
            CP   (HL)           ;Compare to current sector number
            JP   NZ,@Loop       ;Not zero, so go test next sector
            INC  HL             ;Increment to next byte
            INC  DE             ;Increment to next byte
            DJNZ @Compare       ;Repeat until all bytes compared
; Test completed
@Finished:  LD   DE,Complete    ;Test complete ...
            CALL aOutputText    ;Output "Test complete... "
            CALL aOutputNewLine ;Output new line
            RET
; Failed a test
@FailV:     LD   A,CF_Verify    ;Verify error number
            CALL cfSetErr       ;Set error
@Fail:      LD   DE,Failed      ;Pointer to message
            CALL aOutputText    ;Output "Failed... "
            CALL uOutputHexPref ;Output hex prefix
            CALL uOutputHexByte ;Output result as hex byte
            CALL ReportErr      ;Output descriptive error msg
            LD   HL,iFailCnt    ;Point to failure counter
            INC  (HL)           ;Increment failure counter
; Check for verify error
            ;LD   A,(HL)        ;Get error counter
            ;CP   1             ;First error
            ;JR   NZ,@Wait      ;No, so do not retry
            CALL cfGetError     ;Get error number
            CP   CF_Verify      ;Verify error?
            JR   NZ,@NotVeri    ;Yes, so repeat the verify
; Verify error
@AskV:      LD   DE,RetryV      ;Pointer to message
            CALL aOutputText    ;Output "Retry verify..."
            CALL aInputChar     ;Get key
            CALL aOutputNewLine ;Output new line
            AND  0b01011111     ;Convert lower case to upper case
            CP   'N'
            JR   Z,@Wait        ;Skip if key = 'N' 
            CP   'Y'
            JR   NZ,@AskV       ;If not 'Y' ask again
            CALL aOutputNewLine ;Output new line
            JP   @VeriTest
@NotVeri:
; Wait for Continue Y/N
@Wait:      LD   DE,Confirm     ;Pointer to message
            CALL aOutputText    ;Output "Are you sure..."
            CALL aInputChar     ;Get key
            CALL aOutputNewLine ;Output new line
            AND  0b01011111     ;Convert lower case to upper case
            CP   'N'
            JR   Z,@Abort       ;Abort if key = 'N'
            CP   'Y'
            JR   NZ,@Wait       ;If not 'Y' ask again
            CALL aOutputNewLine ;Output new line
            JP   @Next
; Display raw data locations and abort
@Abort:     CALL aOutputNewLine ;Output new line
            LD   DE,WrData
            CALL aOutputText    ;Output "Last write data at $"
;           CALL uOutputHexPref ;Output '$' prefix (or whatever)
            LD   DE,BufferWR
            CALL uOutputHexWord ;Output most significant word
            CALL aOutputNewLine
            LD   DE,RdData
            CALL aOutputText    ;Output "Last read data at $"
;           CALL uOutputHexPref ;Output '$' prefix (or whatever)
            LD   DE,BufferRD
            CALL uOutputHexWord ;Output most significant word
            CALL aOutputNewLine
            RET


ReportErr:  CALL aOutputNewLine ;Output new line
ReportErr2: CALL cfGetError     ;Get error number
            LD   DE,cfErrMsgs   ;Point to list of error messages
            CALL uFindString    ;Find error message string
            CALL aOutputText    ;Output message at DE
            CALL aOutputNewLine ;Output new line
            RET


; **********************************************************************
; **  Messages
; **********************************************************************

About:      .DB  "Compact flash card test v1.2.0 by Stephen C Cousins",0
CardAt:     .DB  "Card at address $",0
Warning:    .DB  "WARNING: This will erase all data from the card",0
Confirm:    .DB  "Do you wish to continue? (Y/N)",0
NumSectors: .DB  "Number of sectors on card: ",0
CardSize:   .DB  "Card size: ",0
Diagnose:   .DB  "Card's self diagnostic test ",0
Passed:     .DB  "passed",0
Failed:     .DB  "failed: code ",0
Sector:     .DB  "Sector: ",0
RetryV:     .DB  "Do you wish to retry the verify? (Y/N)",0
WrData:     .DB  "Last write data at $",0
RdData:     .DB  "Last read back data at $",0
Complete:   .DB  "Test complete",0


; **********************************************************************
; **  Support functions
; **********************************************************************


; Write test sector(s)
;   On entry: C = Number of sectors to write
;             D.E.B = Start sector number
;             HL - Start address of write buffer
;   On exit:  A = Error number (0 if no error)
;             Z flagged if no error
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Write:      PUSH BC
            PUSH DE
            PUSH HL
            CALL cfWrite        ;Write sector(s) from buffer
            POP  HL
            POP  DE
            POP  BC
            RET


; Read test sector(s)
;   On entry: C = Number of sectors to read
;             D.E.B = Start sector number
;             HL - Start address of read buffer
;   On exit:  A = Error number (0 if no error)
;             Z flagged if no error
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
Read:       PUSH BC
            PUSH DE
            PUSH HL
            CALL cfRead         ;Read sector(s) to buffer
            POP  HL
            POP  DE
            POP  BC
            RET


; Prepare test data
;   On entry: D,E.A = Data bytes to fill the sector buffer with
;             HL = Start address of data buffer (512 bytes long)
;   On exit:  HL = Next memory address after end of buffer
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
; This fills a 512 byte buffer with the supplied data pattern
; and returns the next address after the 512 buye buffer
PrepData3:  PUSH BC
            LD   B,171          ;512 bytes divided by 3 = 170.6667
@Loop:      LD   (HL),D
            INC  HL
            LD   (HL),E
            INC  HL
            LD   (HL),A
            INC  HL
            DJNZ @Loop
            DEC  HL             ;Correct address to end of sector
            POP  BC
            RET


; Output parameter (string plus hex word)
Parameter:  PUSH HL
            CALL aOutputText    ;Output message
            CALL uOutputHexPref ;Output '$' (or whatever)
            POP  HL
            LD   E,(HL)         ;Get parameter address...
            INC  HL
            LD   D,(HL)
            CALL uOutputHexWord ;Output hex parameter value
            CALL aOutputNewLine ;Output new line
            RET


; Output text (at DE) length (A)
Text:       PUSH AF
            PUSH BC
            PUSH DE
            LD   B,A            ;Number of characters 
            LD   A,kQuote       ;Quotation mark
            CALL aOutputChar    ;Output quote mark
@Loop:      LD   A,(DE)         ;Get character from text
            CALL aOutputChar    ;Ouptut character
            INC  DE             ;Point to next character
            DJNZ @Loop
            LD   A,kQuote       ;Quotation mark
            CALL aOutputChar    ;Output quote mark
            POP  DE
            POP  BC
            POP  AF
            RET


; Output text (at DE) number of character pairs (A)
; Character order swapped in each word
TextSwap:   PUSH AF
            PUSH BC
            PUSH DE
            LD   B,A            ;Number of characters 
            LD   A,kQuote       ;Quotation mark
            CALL aOutputChar    ;Output quote mark
@Loop:      INC  DE
            LD   A,(DE)         ;Get first CharOut of pair
            DEC  DE
            CALL aOutputChar    ;Ouptut CharOutr
            LD   A,(DE)         ;Get second character of pair
            CALL aOutputChar    ;Ouptut CharOutr
            INC  DE             ;Point to next character pair
            INC  DE
            DJNZ @Loop
            LD   A,kQuote       ;Quotation mark
            CALL aOutputChar    ;Output quote mark
            POP  DE
            POP  BC
            POP  AF
            RET


; **********************************************************************
; **  Includes
; **********************************************************************

#INCLUDE    ..\_CodeLibrary\SCMonitor_API.asm
#INCLUDE    ..\_CodeLibrary\Utilities.asm
#INCLUDE    ..\_CodeLibrary\CompactFlash.asm


; **********************************************************************
; **  Variables
; **********************************************************************

            .DATA

iSector:    .DS  4              ;Current sector number
iSize:      .DS  4              ;Card size in sectors 
iErrNum:    .DS  1              ;Current error number
iFailCnt:   .DS  1              ;Failure count at current sector

            .END

