; **********************************************************************
; **  I2C demo/test  v1.1.0  05-Jan-2021        by Stephen C Cousins  **
; **********************************************************************

; This demonstration and test program is deliberately slow so it works 
; with the slowest I2C devices on the fastest processors.

; **********************************************************************

; Configure for target I2C bus master hardware (define only one)
#DEFINE     SC126               ;SC126 SBC's onboard I2C bus
;#DEFINE    SC137@20            ;SC137 I2C module at address 0x20

            .PROC Z80           ;SCWorkshop select processor
            .ORG  0x8000        ;Program starts at this address

            CALL DEMO_OUT       ;Output to I2C device (PCF8574, SAA1300)
            CALL DEMO_RAND      ;Single byte random access (24LC256)
            CALL DEMO_BLOCK     ;Block access to I2C memory (24LC256)
            RET



; **********************************************************************
; Demo: Output to I2C device such as PCF8574 or SAA1300
;
; This demo writes one test pattern to the output device, waits a while,
; then writes a different test pattern.

;I2CA_OUT:  .EQU 0x70           ;I2C device addess: PCF8574
I2CA_OUT:   .EQU 0x40           ;I2C device addess: SAA1300

DEMO_OUT:   LD   D,0xAA
            CALL DEMO_WR        ;Write output data byte 0xAA
            LD   DE,500
            CALL API_Delay      ;Delay 500ms
            LD   D,0x55
            CALL DEMO_WR        ;Write output data byte 0x55
            RET

DEMO_WR:    LD   A,I2CA_OUT     ;I2C address to write to
            CALL I2C_Open       ;Open I2C device for write
            RET  NZ             ;Abort if failed to open
            LD   A,D            ;Data byte to be written
            CALL I2C_Write      ;Write I2C device's output bits
            RET  NZ             ;Abort if write failed
            CALL I2C_Close      ;Close I2C device 
            RET


; **********************************************************************
; Demo: Single byte random access read and write to 24LC256
;
; This demo writes a test byte to a location in the 24LC256, waits a
; while, then reads it back. The result is stored for checking.

I2CA_RAND:  .EQU 0xAE           ;I2C device addess: 24LC256
I2C_LOCN:   .EQU 0x1234         ;Memory location in memory chip

DEMO_RAND:  LD   E,0x42         ;Byte to be written
            LD   HL,I2C_LOCN    ;Address in I2C memory chip
            CALL I2C_MWr        ;Write to I2C memory
            RET  NZ             ;Abort if error
            LD   DE,50
            CALL API_Delay      ;Delay 50ms
            LD   HL,I2C_LOCN    ;Address in I2C memory chip
            CALL I2C_MRd        ;Read from I2C memory
            RET  NZ             ;Abort if error
            LD   A,E            ;Get byte read back from chip
            LD   (0x9000),A     ;Store it somewhere
            RET

; Random access single byte write
;   On entry: E = Byte to be written
;             HL = Address to be written
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             IX IY preserved
I2C_MWr:    LD   A,E            ;Get data byte to be written
            LD   A,I2CA_RAND    ;I2C address to write to
            CALL I2C_Open       ;Open for write
            RET  NZ             ;Abort if failure
            LD   A,H            ;Address (hi) in memory chip
            CALL I2C_Write      ;Send address hi byte
            LD   A,L            ;Address (lo) in memory chip
            CALL I2C_Write      ;Send address lo byte
            LD   A,E            ;Byte to be written to memory
            CALL I2C_Write      ;Write data byte to memory chip
            CALL I2C_Stop       ;Generate I2C stop
            RET                 ;Yes, I could just JP I2C_Stop !!


; Random access single byte read
;   On entry: DE = First address to be written
;             SCL = unknown, SDA = unknown
;   On exit:  E = Data byte read from memory
;             If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             IX IY preserved
I2C_MRd:    LD   A,I2CA_RAND    ;I2C address to write to
            CALL I2C_Open       ;Open for write
            RET  NZ             ;Abort if failure
            LD   A,H            ;Address (hi) in memory chip
            CALL I2C_Write      ;Send address hi byte
            LD   A,L            ;Address (lo) in memory chip
            CALL I2C_Write      ;Send address lo byte
            LD   A,I2CA_RAND+1  ;I2C address to be read from
            CALL I2C_Open       ;Open for read
            XOR  A              ;Do not acknowledge read
            CALL I2C_Read       ;Read byte from I2C memory
            LD   E,A            ;Store data byte read
            CALL I2C_Stop       ;Generate I2C stop
            RET                 ;Yes, I could just JP I2C_Stop !!


; **********************************************************************
; Demo: Single byte random access read and write to 24LC256
;
; This demo writes a block of memory to the 24LC256, then reads it back
; to RAM for checking.

I2CA_BLOCK: .EQU 0xAE           ;I2C device addess: 24LC256
TIMEOUT:    .EQU 10000          ;Timeout loop counter

DEMO_BLOCK: LD   HL,0x0000      ;Start of data in ROM
            LD   DE,0x1000      ;Start of data in 24LC256
            LD   BC,0x800       ;Number of bytes to copy
            CALL I2C_MemWr      ;Write a block from ROM to I2C memory
            LD   DE,200
            CALL API_Delay      ;Delay 200ms
            LD   HL,0x9000      ;Start of data in RAM
            LD   DE,0x1000      ;Start of data in 24LC256
            LD   BC,0x800       ;Number of bytes to copy
            CALL I2C_MemRd      ;Read a block from I2C memory to RAM
            RET


; Copy a block from I2C memory to CPU memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             IX IY preserved
I2C_MemRd:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
@Repeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,@Ready       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,@Repeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
@Ready:     POP  BC             ;Restore byte counter
            LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,I2CA_BLOCK+1 ;I2C device to be read from
            CALL I2C_Open       ;Open for read
            RET  NZ             ;Abort if error
@Read:      DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Last byte to be read?
            CALL I2C_Read       ;Read byte with no ack on last byte
            LD   (HL),A         ;Write byte in CPU memory
            INC  HL             ;Increment CPU memory pointer
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,@Read       ;No, so go read next byte
            CALL I2C_Stop       ;Generate I2C stop
            XOR  A              ;Return with success (Z flagged)
            RET


; Copy a block from CPU memory to I2C memory
;   On entry: DE = First address in I2C memory
;             HL = First address in CPU memory
;             BC = Number of bytes to be copied
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             IX IY preserved
; The 24LC64 requires blocks of data to be written in 64 byte (or less)
; pages.
I2C_MemWr:  PUSH BC
            LD   BC,TIMEOUT     ;Timeout loop counter
@Repeat:    LD   A,I2CA_BLOCK   ;I2C address to write to
            CALL I2C_Open       ;Open for write
            JR   Z,@Ready       ;If open okay then skip on
            DEC  BC
            LD   A,B
            OR   C              ;Timeout?
            JR   NZ,@Repeat     ;No, so go try again
            POP  BC
            LD   A,ERR_TOUT     ;Error code
            OR   A              ;Error, so NZ flagged
            RET                 ;Return with error
; Device opened okay
@Ready:     POP  BC             ;Restore byte counter
@Block:     LD   A,D            ;Address (hi) in I2C memory
            CALL I2C_Write      ;Write address
            LD   A,E            ;Address (lo) in I2C memory
            CALL I2C_Write      ;Write address
@Write:     LD   A,(HL)         ;Get data byte from CPU memory
            CALL I2C_Write      ;Read byte from I2C memory
            INC  HL             ;Increment CPU memory pointer
            INC  DE             ;Increment I2C memory pointer
            DEC  BC             ;Decrement byte counter
            LD   A,B
            OR   C              ;Finished?
            JR   Z,@Store       ;Yes, so go store this page
            LD   A,E            ;Get address in I2C memory (lo byte)
            AND  63             ;64 byte page boundary?
            JR   NZ,@Write      ;No, so go write another byte
@Store:     CALL I2C_Stop       ;Generate I2C stop
            LD   A,B
            OR   C              ;Finished?
            JR   NZ,I2C_MemWr   ;No, so go write some more
            RET                 ;Return success A=0 and Z flagged


; **********************************************************************
; I2C support functions

; I2C bus open device
;   On entry: A = Device address (bit zero is read flag)
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             BC DE HL IX IY preserved
I2C_Open:   PUSH AF
            CALL I2C_Start      ;Output start condition
            POP  AF
            JR   I2C_Write      ;Write data byte


; I2C bus close device
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  If successfully A=0 and Z flagged
;             If successfully A=Error and NZ flagged
;             SCL = hi, SDA = hi
;             BC DE HL IX IY preserved
I2C_Close:  JP   I2C_Stop       ;Output stop condition


; **********************************************************************
; Small computer monitor API

; Delay by DE milliseconds (approx)
;   On entry: DE = Delay time in milliseconds
;   On exit:  BC DE HL IX IY preserved
API_Delay:  PUSH BC             ;Preserve registers
            PUSH DE
            PUSH HL
            LD   C,0x0A         ;API 0x0A = Delay by DE milliseconds
            RST  0x30           ;Call API
            POP  HL             ;Restore registers
            POP  DE
            POP  BC
            RET


; **********************************************************************
; **********************************************************************
; I2C bus master driver
; **********************************************************************
; **********************************************************************

; Functions provided are:
;     I2C_Start
;     I2C_Stop
;     I2C_Read
;     I2C_Write
;
; This code has delays between all I/O operations to ensure it works
; with the slowest I2C devices
;
; I2C transfer sequence
;   +-------+  +---------+  +---------+     +---------+  +-------+
;   | Start |  | Address |  | Data    | ... | Data    |  | Stop  |
;   |       |  | frame   |  | frame 1 |     | frame N |  |       |
;   +-------+  +---------+  +---------+     +---------+  +-------+
;
;
; Start condition                     Stop condition
; Output by master device             Output by master device
;       ----+                                      +----
; SDA       |                         SDA          |
;           +-------                        -------+
;       -------+                                +-------
; SCL          |                      SCL       |
;              +----                        ----+
;
;
; Address frame
; Clock and data output from master device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | A 7 | A 6 | A 5 | A 4 | A 3 | A 2 | A 1 | R/W | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;
; Data frame 
; Clock output by master device
; Data output by transmitting device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | D 7 | D 6 | D 5 | D 4 | D 3 | D 2 | D 1 | D 0 | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;


; **********************************************************************
; I2C constants


; I2C bus master interface
#IFDEF SC126
I2C_PORT:   .EQU 0x0C           ;Host I2C port address
I2C_SDA_WR: .EQU 7              ;Host I2C write SDA bit number
I2C_SDA_RD: .EQU 7              ;Host I2C read SDA bit number
I2C_SCL_WR: .EQU 0              ;Host I2C write SCL bit number
;2C_SCL_RD: .EQU 0              ;Host I2C read SCL bit number (not supported)
I2C_QUIES:  .EQU 0b10001101     ;Host I2C control port quiescent value
#ENDIF
#IFDEF SC137@20
I2C_PORT:   .EQU 0x20           ;Host I2C port address
I2C_SDA_WR: .EQU 7              ;Host I2C write SDA bit number
I2C_SDA_RD: .EQU 7              ;Host I2C read SDA bit number
I2C_SCL_WR: .EQU 0              ;Host I2C write SCL bit number
I2C_SCL_RD: .EQU 0              ;Host I2C read SCL bit number 
I2C_QUIES:  .EQU 0b10000001     ;Host I2C output port quiescent value
#ENDIF

; I2C support constants
ERR_NONE:   .EQU 0              ;Error = None
ERR_JAM:    .EQU 1              ;Error = Bus jammed [not used]
ERR_NOACK:  .EQU 2              ;Error = No ackonowledge
ERR_TOUT:   .EQU 3              ;Error = Timeout


; **********************************************************************
; Hardware dependent I2C bus functions


; I2C bus transmit frame (address or data)
;   On entry: A = Data byte, or
;                 Address byte (bit zero is read flag)
;             SCL = low, SDA = low
;   On exit:  If successful A=0 and Z flagged
;                SCL = lo, SDA = lo
;             If unsuccessful A=Error and NZ flagged
;                SCL = high, SDA = high, I2C closed
;             BC DE HL IX IY preserved
I2C_Write:  PUSH BC             ;Preserve registers
            PUSH DE
            LD   D,A            ;Store byte to be written
            LD   B,8            ;8 data bits, bit 7 first
@Wr_Loop:   RL   D              ;Test M.S.Bit
            JR   C,@Bit_Hi      ;High, so skip
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = data bit)
            JR   @Bit_Clk
@Bit_Hi:    CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA = data bit)
@Bit_Clk:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = data bit)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = data bit)
            DJNZ @Wr_Loop
; Test for acknowledge from slave (receiver)
; On arriving here, SCL = lo, SDA = data bit
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/ack)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/ack)
            CALL I2C_RdPort     ;Read SDA input
            LD   B,A
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA = hi)
            BIT  I2C_SDA_RD,B
            JR   NZ,@NoAck      ;Skip if no acknowledge
            POP  DE             ;Restore registers
            POP  BC
            XOR  A              ;Return success A=0 and Z flagged
            RET
; I2C STOP required as no acknowledge
; On arriving here, SCL = lo, SDA = hi
@NoAck:     CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = lo)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA = hi)
            POP  DE             ;Restore registers
            POP  BC
            LD   A,ERR_NOACK    ;Return error = No Acknowledge
            OR   A              ;  and NZ flagged
            RET


; I2C bus receive frame (data)
;   On entry: A = Acknowledge flag
;               If A != 0 the read is acknowledged
;             SCL low, SDA low
;   On exit:  If successful A = data byte and Z flagged
;               SCL = low, SDA = low
;             If unsuccessul* A = Error and NZ flagged
;               SCL = low, SDA = low
;             BC DE HL IX IY preserved
; *This function always returns successful
I2C_Read:   PUSH BC             ;Preserve registers
            PUSH DE
            LD   E,A            ;Store acknowledge flag
            LD   B,8            ;8 data bits, 7 first
            CALL I2C_SDA_HI     ;SDA high  (SCL lo, SDA hi/input)
@Rd_Loop:   CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA hi/input)
            CALL I2C_RdPort     ;Read SDA input bit
            SCF                 ;Set carry flag
            BIT  I2C_SDA_RD,A   ;SDA input high?
            JR   NZ,@Rotate     ;Yes, skip with carry flag set
            CCF                 ;Clear carry flag
@Rotate:    RL   D              ;Rotate result into D
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA hi/input)
            DJNZ @Rd_Loop       ;Repeat for all 8 bits
; Acknowledge input byte
; On arriving here, SCL = lo, SDA = hi/input
            LD   A,E            ;Get acknowledge flag
            OR   A              ;A = 0? (indicates no acknowledge)
            JR   Z,@NoAck       ;Yes, so skip acknowledge
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA lo)
@NoAck:     CALL I2C_SCL_HI     ;SCL hi    (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            LD   A,D            ;Get data byte received
            POP  DE             ;Restore registers
            POP  BC
            CP   A              ;Return success Z flagged
            RET


; I2C bus start
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = low, SDA = low
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are high
I2C_Start:  CALL I2C_INIT       ;Initialise I2C control port
;           CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA ??)
;           CALL I2C_SDA_HI     ;SDA high  (SCL hi, SDA hi)
; Generate I2C start condition
            CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; I2C bus stop 
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = high, SDA = high
;             A = 0 and Z flagged as we always succeed
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are low
I2C_Stop:   CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
; Generate stop condition
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA hi)
            XOR  A              ;Return success A=0 and Z flagged
            RET


; **********************************************************************
; I2C bus simple I/O functions
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved

I2C_INIT:   LD   A,I2C_QUIES    ;I2C control port quiescent value
            JR   I2C_WrPort

I2C_SCL_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SCL_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SCL_WR,A
            JR   I2C_WrPort

I2C_SDA_HI: LD   A,(I2C_RAMCPY)
            SET  I2C_SDA_WR,A
            JR   I2C_WrPort

I2C_SDA_LO: LD   A,(I2C_RAMCPY)
            RES  I2C_SDA_WR,A
            ;JR   I2C_WrPort

I2C_WrPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            OUT  (C),A          ;Write A to I2C I/O port
            LD   (I2C_RAMCPY),A ;Write A to RAM copy
            POP  BC             ;Restore registers
            RET

I2C_RdPort: PUSH BC             ;Preserve registers
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            IN   A,(C)          ;Read A from I/O port
            POP  BC             ;Restore registers
            RET


; **********************************************************************
; I2C workspace / variables in RAM

I2C_RAMCPY: .DB  0


