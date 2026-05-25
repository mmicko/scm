; **********************************************************************
; **  I2C demo/test                             by Stephen C Cousins  **
; **********************************************************************

; This program demonstrates the use of SC126's I2C port with a 
; PCF8574 (I2C remote 8-bit I/O expander)
;
; This code has delays between all I/O operations to ensure it works
; with the slowest I2C devices


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
;          +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA      | A 7 | A 6 | A 5 | A 4 | A 3 | A 2 | A 1 | R/W | ACK |   |
;       ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;            +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL        | |   | |   | |   | |   | |   | |   | |   | |   | |
;       -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;
; Data frame 
; Clock output by master device
; Data output by transmitting device
; Receiving device outputs acknowledge 
;          +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA      | D 7 | D 6 | D 5 | D 4 | D 3 | D 2 | D 1 | D 0 | ACK |   |
;       ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;            +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL        | |   | |   | |   | |   | |   | |   | |   | |   | |
;       -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;

            .PROC Z80           ;SCWorkshop select processor

            .ORG 0x8000


I2C_PORT:   .EQU 0x0C           ;Host I2C port address
I2C_SDA_WR: .EQU 7              ;Host I2C write SDA bit number
I2C_SCL_WR: .EQU 0              ;Host I2C write SCL bit number
I2C_SDA_RD: .EQU 7              ;Host I2C read SDA bit number

I2C_ADDR:   .EQU 0x70           ;I2C device addess


            LD   A,0b11000000   ;SCL and SDA high + LED 1
            CALL I2C_WrPort     ;SCL high and SDA high

            LD   A,I2C_ADDR     ;I2C address to write to
            CALL I2C_Open       ;Open I2C device for write
            RET  NZ

            LD   A,0xAA
            CALL I2C_Write      ;Write I2C device's output bits
            RET  NZ

            LD   DE,1000
            CALL API_Delay      ;Delay 1000ms

            LD   A,0x55
            CALL I2C_Write      ;Write I2C device's output bits
            RET  NZ

            LD   DE,1000
            CALL API_Delay      ;Delay 1000ms

            LD   A,0xFF
            CALL I2C_Write      ;Set output bits
            RET  NZ

            CALL I2C_Close      ;Close I2C device 


            LD   A,I2C_ADDR+1   ;I2C address to write to
            CALL I2C_Open       ;Open I2C device for read

            CALL I2C_Read       ;Read from I2C device

            CALL I2C_Close      ;Close I2C device


            RET



; I2C bus open device
;   On entry: A = Device address (bit zero is read flag)
;             SCL = unknown, SDA = unknown
;   On exit:  If successfully A = 0 and Z flagged
;             If successfully A = Error and NZ flagged
;             SCL = lo, SDA = lo
;             HL IX IY preserved
; Possible errors:  1 = Bus jammed (not implemented)
I2C_Open:   PUSH AF
            CALL I2C_Start      ;Output start condition
            POP  AF
            JR   I2C_Write      ;Write data byte


; I2C bus close device
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  If successfully A=0 and Z flagged
;             If successfully A=Error and NZ flagged
;             SCL = hi, SDA = hi
;             HL IX IY preserved
; Possible errors:  1 = Bus jammed ??????????
I2C_Close:  JR   I2C_Stop       ;Output stop condition


; I2C bus transmit frame (address or data)
;   On entry: A = Data byte, or
;                 Address byte (bit zero is read flag)
;             SCL = low, SDA = low
;   On exit:  If successful A=0 and Z flagged
;                SCL = lo, SDA = lo
;             If unsuccessful A=Error and NZ flagged
;                SCL = high, SDA = high, I2C closed
;             HL IX IY preserved
I2C_Write:  LD   D,A            ;Store byte to be written
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
            XOR  A              ;Return success A=0 and Z flagged
            RET
; I2C STOP required as no acknowledge
; On arriving here, SCL = lo, SDA = hi
@NoAck:     CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA = lo)
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA = lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA = hi)
            LD   A,2            ;Return error 2 - No Ack
            OR   A              ;  and NZ flagged
            RET


; I2C bus receive frame (data)
;   On entry: SCL low, SDA low
;   On exit:  If successful A = data byte and Z flagged
;               SCL = low, SDA = low
;             If unsuccessul A = Error and NZ flagged
;               SCL = low, SDA = low ??? no failures supported
;             HL IX IY preserved
I2C_Read:   LD   B,8            ;8 data bits, 7 first
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
            CALL I2C_SDA_LO     ;SDA low   (SCL lo, SDA lo)
            CALL I2C_SCL_HI     ;SCL hi    (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            LD   A,D            ;Get data byte received
            CP   A              ;Return success Z flagged
            RET


; I2C bus start
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = low, SDA = low
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are high
I2C_Start:  CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA ??)
            CALL I2C_SDA_HI     ;SDA high  (SCL hi, SDA hi)
; Generate I2C start condition
            CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
            RET


; I2C bus stop 
;   On entry: SCL = unknown, SDA = unknown
;   On exit:  SCL = high, SDA = high
;             BC DE HL IX IY preserved
; First ensure SDA and SCL are low
I2C_Stop:   CALL I2C_SDA_LO     ;SDA low   (SCL hi, SDA lo)
            CALL I2C_SCL_LO     ;SCL low   (SCL lo, SDA lo)
; Generate stop condition
            CALL I2C_SCL_HI     ;SCL high  (SCL hi, SDA lo)
            CALL I2C_SDA_HI     ;SDA low   (SCL hi, SDA hi)
            RET


; **********************************************************************
; I2C bus simple I/O functions
;   On entry: No parameters required
;   On exit:  BC DE HL IX IY preserved

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

I2C_WrPort: PUSH BC
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            OUT  (C),A          ;Write A to I2C I/O port
            LD   (I2C_RAMCPY),A ;Write A to RAM copy
            POP  BC
            RET

I2C_RdPort: PUSH BC
            LD   B,0            ;Set up BC for 16-bit
            LD   C,I2C_PORT     ;  I/O address of I2C port
            IN   A,(C)          ;Read A from I/O port
            POP  BC
            RET


; **********************************************************************
; Small computer monitor API

; Delay by DE milliseconds (approx)
;   On entry: DE = Delay time in milliseconds
;   On exit:  IX IY preserved
API_Delay:  LD   C,0x0A
            RST  0x30
            RET


; **********************************************************************
; Workspace / variable in RAM

I2C_RAMCPY: .DB  0








