
            .CODE

; Interface descriptor
            .DB  0              ;Device ID code (not currently used)
            .DW  @String        ;Pointer to device string
            .DW  TIMTERM_Init   ;Pointer to initialisation code
            .DB  0              ;Hardware flags bit mask
            .DW  TIMTERM_Set    ;Point to device settings code
            .DB  1              ;Number of console devices
            .DW  TIMTERM_RxA    ;Pointer to 1st channel input code
            .DW  TIMTERM_TxA    ;Pointer to 1st channel output code
@String:    .DB  "TIM Terminal "
            .DB  "@ HW"
            .DB  kNull


; Initialise
;   On entry: No parameters required
;   On exit:  Z flagged if device is found and initialised
;             AF BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
; If the device is found it is initialised
TIMTERM_Init:
; Fill screen memory
            LD      BC,0x8000
Loop:
            XOR     A
            OUT     (C),A
            INC     BC
            BIT     7,B
            JR      NZ,Loop
; Initialisation complete
            XOR  A              ;Flag success
            RET                 ;  and return

; Input character
;   On entry: No parameters required
;   On exit:  A = Character input from the device
;             NZ flagged if a character has been found
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TIMTERM_RxA:
            ;JP   kJumpTab+0x30  ;Input from console device 1
            JP   kJumpTab+0x36  ;Input from console device 2


; Output character
;   On entry: A = Character to be output to the device
;   On exit:  If character output successful (eg. device was ready)
;               NZ flagged and A != 0
;             If character output failed (eg. device busy)
;               Z flagged and A = Character to output
;             BC DE HL IX IY I AF' BC' DE' HL' preserved
TIMTERM_TxA:
            PUSH AF
            PUSH BC
            PUSH DE
            PUSH HL
            LD   C,A
            CALL CHROUT      ;Send instruction
            POP  HL
            POP  DE
            POP  BC
            POP  AF
            JP   kJumpTab+0x33  ;Output to console device 1


; Device settings
;   On entry: No parameters required
;   On entry: A = Property to set: 1 = Baud rate
;             B = Baud rate code
;             C = Console device number (1 to 6)
;   On exit:  IF successful: (ie. valid device and baud code)
;               A != 0 and NZ flagged
;             BC DE HL not specified
;             IX IY I AF' BC' DE' HL' preserved
TIMTERM_Set:  XOR  A              ;Return failed to set (Z flagged)
            RET


; **********************************************************************
; **  Terminal emulation
; **********************************************************************
SCROLL: .EQU	0xD0			; scroll register
;
; Prints one character
;
CHROUT:						;character to print is in C
	LD	A,C
	CP	32				;is character a control code?
	JR	C,IS_CONTROL_CHAR
	BIT	7,A				;check if bit 7 is set (>127)
	JP	Z,PRINT_CHAR   			;it's not, continue
	LD	C,46				;if >127, print a dot
	JP	PRINT_CHAR

IS_CONTROL_CHAR:				;process the control character
	CP	13				;CR?
	JR	NZ,NOT_CR
	XOR	A				;get a zero
	LD	(COLUMN_POSITION),A		;set column to 0
	RET

NOT_CR:
	CP	10				;LF?
	JR	NZ,NOT_LF
	LD	A,(ROW_POSITION)		
	INC	A				;increase row counter
	CP	24				;last row?
	JR	C,NOT_LAST_ROW
	CALL	SCROLL_ONE_LINE
	RET

NOT_LAST_ROW:
	LD	(ROW_POSITION),A
	RET

NOT_LF:	
	CP	8				;backspace?
	JR	NZ,UNK_CTRL_CHAR		;no more known control characters
	LD	A,(COLUMN_POSITION)
	DEC	A
	JP	M,PREND
	LD	(COLUMN_POSITION),A
	LD	C,32				;space
	CALL	PRINT_CHAR			;erase character on previous postition
	LD	A,(COLUMN_POSITION)
	DEC	A
	LD	(COLUMN_POSITION),A		;BUG - backspace routine does not move to previous row
						;but deleting the characters furthermore removes them from buffer
	RET

UNK_CTRL_CHAR:					;make an unknown control character printable
	PUSH	BC
	LD	C,05EH				;get a "^" character
	CALL	PRINT_CHAR
	POP	BC
	SET	6,C				;add 64 to control code, to make it a uppercase char
	CALL	PRINT_CHAR
PREND:
	RET

PRINT_CHAR:
	LD	A,C				;C is char to print
	SUB	020H				;-32
	LD	C,A
	LD	B,10				;char is 10 pixels
	MULT				;char * 10 (pixela)
	LD	HL,CHARSET
	ADD	HL,BC				;BC is offset from start of font data
	EX	DE,HL
	CALL	GET_ADDRESS			;get RAM location in BC
	LD	L,10
	JR	C,PRINT_FROM_HALF		;if carry is set, char starts from half byte in screen RAM
PRINT_FROM_FULL:
	PUSH	HL
	LD	A,(DE)				;DE is character address in charset
	RLCA
	RLCA
	RLCA
	RLCA
	AND	0FH
	LD	HL,PIXEL_TABLE
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	OUT	(C),A
	INC	B
	LD	A,(DE)
	AND	0FH
	LD	HL,PIXEL_TABLE
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	AND	0FH
	LD	L,A
	IN	A,(C)
	AND	0F0H
	OR	L
	OUT	(C),A
	DEC	B
	INC	C
	INC	DE
	POP	HL
	DEC	L
	JR	NZ,PRINT_FROM_FULL
	JR	PRINT_DONE
PRINT_FROM_HALF:
	PUSH	HL
	LD	A,(DE)
	RLCA
	RLCA
	AND	3
	LD	HL,PIXEL_TABLE
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	AND	0F0H
	LD	L,A
	IN	A,(C)
	AND	0FH
	OR	L
	OUT	(C),A
	INC	B
	LD	A,(DE)
	RRCA
	RRCA
	AND	0FH
	LD	HL,PIXEL_TABLE
	ADD	A,L
	LD	L,A
	LD	A,(HL)
	OUT	(C),A
	DEC	B
	INC	C
	INC	DE
	POP	HL
	DEC	L
	JR	NZ,PRINT_FROM_HALF
PRINT_DONE:
	LD	A,(COLUMN_POSITION)
	INC	A
	CP	80				;end of row?
	JR	NZ,NEXT_COL			;no
	XOR	A				;yes, new column is zero
NEXT_COL:
	LD	(COLUMN_POSITION),A		;save new column position
	JP	NZ,PREND			;and finish if column is not zero
	LD	A,(ROW_POSITION)		
	CP	23				;last line?
	JR	NZ,NEXT_ROW			;no
	CALL	SCROLL_ONE_LINE			;yes
	RET					;and finish
NEXT_ROW:
	INC	A
	LD	(ROW_POSITION),A		;save new row position
	RET					;and finish

GET_ADDRESS:
	LD	A,(ROW_POSITION)
	LD	B,A
	LD	C,10
	MULT				;row x10
	LD	A,(SCROLL_LOCATION)
	ADD	A,C
	LD	C,A
	LD	A,(COLUMN_POSITION)
	LD	B,A
	ADD	A,A
	ADD	A,B				;col x3
	ADD	A,2				;+2
	SRL	A				;div /2
	LD	B,A
	SET	7,B				;plus high bit
	RET					;if carry set, it is odd char in row
	
SCROLL_ONE_LINE:
	LD	A,(SCROLL_LOCATION)
	ADD	A,10
	LD	(SCROLL_LOCATION),A
	OUT0	(SCROLL),A
	ADD	A,0E6H
	LD	C,A
	LD	B,080H
	LD	E,0DH

CLEAR_LINES_IN_E:
	XOR	A
CLRL1:	
	LD	D,E
	PUSH	BC
CLRL2:	
	OUT	(C),A
	INC	C
	OUT	(C),A
	INC	C
	DEC	D
	JR	NZ,CLRL2
	POP	BC
	INC	B
	JR	NZ,CLRL1
	RET
	
PIXEL_TABLE:

	.DB	$00
	.DB	$C0
	.DB	$30
	.DB	$F0
	.DB	$0C
	.DB	$CC
	.DB	$3C
	.DB	$FC
	.DB	$03
	.DB	$C3
	.DB	$33
	.DB	$F3
	.DB	$0F
	.DB	$CF
	.DB	$3F
	.DB	$FF

CHARSET:
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$20
	.DB	$00
	
	.DB	$00
	.DB	$50
	.DB	$50
	.DB	$50
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$50
	.DB	$50
	.DB	$F8
	.DB	$50
	.DB	$F8
	.DB	$50
	.DB	$50
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$78
	.DB	$A0
	.DB	$70
	.DB	$28
	.DB	$F0
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$C0
	.DB	$C8
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$98
	.DB	$18
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$40
	.DB	$A0
	.DB	$A0
	.DB	$40
	.DB	$A8
	.DB	$90
	.DB	$68
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$10
	.DB	$20
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$40
	.DB	$40
	.DB	$20
	.DB	$10
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$40
	.DB	$20
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$70
	.DB	$F8
	.DB	$70
	.DB	$88
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$20
	.DB	$20
	.DB	$F8
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$20
	.DB	$40
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F8
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$08
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$80
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$98
	.DB	$A8
	.DB	$C8
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$60
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$08
	.DB	$30
	.DB	$40
	.DB	$80
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$10
	.DB	$20
	.DB	$10
	.DB	$08
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$30
	.DB	$50
	.DB	$90
	.DB	$F8
	.DB	$10
	.DB	$10
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$80
	.DB	$F0
	.DB	$08
	.DB	$08
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$38
	.DB	$40
	.DB	$80
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$08
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$40
	.DB	$40
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$08
	.DB	$10
	.DB	$E0
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$00
	.DB	$00
	.DB	$30
	.DB	$30
	.DB	$20
	.DB	$40
	
	.DB	$00
	.DB	$08
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$20
	.DB	$10
	.DB	$08
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F8
	.DB	$00
	.DB	$F8
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$80
	.DB	$40
	.DB	$20
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$80
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$08
	.DB	$10
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$20
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$B8
	.DB	$A8
	.DB	$B0
	.DB	$80
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$F8
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$E0
	.DB	$90
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$90
	.DB	$E0
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$80
	.DB	$80
	.DB	$F0
	.DB	$80
	.DB	$80
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$80
	.DB	$80
	.DB	$F0
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$80
	.DB	$98
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$F8
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$38
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$90
	.DB	$60
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$90
	.DB	$A0
	.DB	$C0
	.DB	$A0
	.DB	$90
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$D8
	.DB	$D8
	.DB	$A8
	.DB	$A8
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$C8
	.DB	$A8
	.DB	$98
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$A8
	.DB	$90
	.DB	$68
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$A0
	.DB	$90
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$80
	.DB	$70
	.DB	$08
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$50
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$A8
	.DB	$A8
	.DB	$D8
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$50
	.DB	$20
	.DB	$50
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$50
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$08
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$80
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$40
	.DB	$40
	.DB	$40
	.DB	$40
	.DB	$40
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$80
	.DB	$40
	.DB	$20
	.DB	$10
	.DB	$08
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$70
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$50
	.DB	$88
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$20
	.DB	$10
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$70
	.DB	$08
	.DB	$78
	.DB	$88
	.DB	$78
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$80
	.DB	$80
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$80
	.DB	$80
	.DB	$78
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$08
	.DB	$08
	.DB	$78
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$F8
	.DB	$80
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$78
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$08
	.DB	$70
	
	.DB	$00
	.DB	$80
	.DB	$80
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$00
	.DB	$60
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$00
	.DB	$30
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$10
	.DB	$60
	
	.DB	$00
	.DB	$80
	.DB	$80
	.DB	$90
	.DB	$A0
	.DB	$C0
	.DB	$A0
	.DB	$90
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$60
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$D0
	.DB	$A8
	.DB	$A8
	.DB	$A8
	.DB	$A8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$70
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$70
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F0
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$F0
	.DB	$80
	.DB	$80
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$78
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$08
	.DB	$08
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$B8
	.DB	$C0
	.DB	$80
	.DB	$80
	.DB	$80
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$78
	.DB	$80
	.DB	$70
	.DB	$08
	.DB	$F0
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$20
	.DB	$70
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$10
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$50
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$A8
	.DB	$A8
	.DB	$50
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$50
	.DB	$20
	.DB	$50
	.DB	$88
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$88
	.DB	$78
	.DB	$08
	.DB	$70
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$F8
	.DB	$10
	.DB	$20
	.DB	$40
	.DB	$F8
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$10
	.DB	$20
	.DB	$20
	.DB	$40
	.DB	$20
	.DB	$20
	.DB	$10
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$20
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$40
	.DB	$20
	.DB	$20
	.DB	$10
	.DB	$20
	.DB	$20
	.DB	$40
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$40
	.DB	$A8
	.DB	$10
	.DB	$00
	.DB	$00
	.DB	$00
	.DB	$00
	
	.DB	$00
	.DB	$F8
	.DB	$F8
	.DB	$F8
	.DB	$F8
	.DB	$F8
	.DB	$F8
	.DB	$F8
	.DB	$00
	.DB	$00

; **********************************************************************
; **  Variables
; **********************************************************************

            .DATA

COLUMN_POSITION: .DB 0
ROW_POSITION:    .DB 0
SCROLL_LOCATION: .DB 0

; No variables used


; **********************************************************************
; **  End of driver                                                   **
; **********************************************************************

