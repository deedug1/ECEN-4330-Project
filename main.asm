PROG_STATE EQU 11H
KPR1R2 EQU 08H
KPR3R4 EQU 09H
SEGADDR EQU 0H
LCDADDRH EQU 0C0H
ADCADDRH EQU 80H
RTCADDRH EQU 0C0H
LAST_WRITE EQU 10H
ORG 0
	
	;Init
	MOV SP, #50H		;Mov SP out of BANK
	MOV PROG_STATE, #00H	;Set first state
	ACALL INIT_PROC
	ACALL INIT_LCD		;Init LCD
	MOV A, #'F'		;Print Test
	ACALL WRITE_TO_LCD_DATA		
	ACALL IS_LCD_BUSY	
	MOV A, #'U'
	ACALL WRITE_TO_LCD_DATA
	MOV A, #'C'
	ACALL IS_LCD_BUSY
	MOV A, #'C'
	ACALL WRITE_TO_LCD_DATA
	ACALL IS_LCD_BUSY
	MOV A, #'K'
	ACALL WRITE_TO_LCD_DATA	
	
;Program start
;****
;* Note: register 1 holds state
;****
MAIN:
	ACALL KEYPAD_SCAN	;Allow for bouncing
	ACALL KEYPAD_SCAN
	ACALL KEYPAD_SCAN
	ACALL SET_STATE
	MOV A, PROG_STATE		;Check state
	JNZ TASK2
	ACALL L3TO8
	ACALL WRITE_TO_7SEG
	JMP MAIN
	TASK2:
	ACALL L0THR7
	ACALL WRITE_TO_7SEG
	JMP MAIN
;*********
;* Init function
;* Small dance function for the 7seg
;* think gameboy color opening
;********
INIT_PROC:
	MOV A, #00H
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #0FFH
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00H
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #0FFH
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00H
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #0FFH
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	RET
;*********
;* Delay
;* Delays for 255 * 50 clks
;*********
DELAY_1MS:
	PUSH  3	
	PUSH  4
	MOV   R3, #50		;original 50
HERE2: 
	MOV   R4, #255		;original 255
HERE1: 
	DJNZ  R4, HERE1 	;If R4 != 0 Jump to HERE1
	DJNZ  R3, HERE2		;If R3 != 0 Jump to HERE2
	POP   4
	POP   3
	RET	
;*********
;* Keypad scan function
;* Scans keypad and stores results in ram addresses 0x08, 0x09
;********
KEYPAD_SCAN:
	;0, 1, 2, 3, 4, 5, 6, 7,
	;C1,C2,C3,C4,R1,R2,R3,R4
	PUSH 0E0H		; Push A register
	PUSH 0F0H		; Push B register
	MOV P1, #0FEH           ; Scan first column
	MOV B, P1		; First column	
	ANL B, #0F0H		; Clear bottom nibble
	MOV P1, #0FDH		; Scan second column
	MOV A, P1		; Second column
	ANL A , #0F0H		; Clear bottom nibble
	SWAP A 			; SWAP 
	ADD A, B		; Combine C1, C2
	MOV KPR1R2, A		; Store result
	MOV P1, #0FBH           ; Scan third column
	MOV B, P1		; Third column	
	ANL B, #0F0H		; Clear bottom nibble
	MOV P1, #0F7H		; Scan fourth column
	MOV A, P1		; Fourth column
	ANL A, #0F0H		; Clear bottom nibble
	SWAP A
	ADD A, B		; Combine C2, C3
	MOV KPR3R4, A		; Store result
	POP 0F0H
	POP 0E0H
	RET
;********
;* Get keypress function
;* Returns first pressed ascii character of result keypad scan in register A
;* Returns 0 if no keys pressed
;* Note: first key = 1 last key = D
;***********	
GET_KEYPRESS_HEX:
	PUSH 0F0H			;Push B register for work
	MOV B, KPR1R2			;Check first two rows	
	MOV A, #0EH			; Key pressed
	JNB B.7, END_GET_KEYPRESS	;If bit is not set end proc	
	MOV A, #07H
	JNB B.6, END_GET_KEYPRESS
	MOV A, #04H		
	JNB B.5, END_GET_KEYPRESS
	MOV A, #01H
	JNB B.4, END_GET_KEYPRESS
	MOV A, #00H
	JNB B.3, END_GET_KEYPRESS
	MOV A, #08H
	JNB B.2, END_GET_KEYPRESS
	MOV A, #05H
	JNB B.1, END_GET_KEYPRESS
	MOV A, #02H
	JNB B.0, END_GET_KEYPRESS
	MOV B, KPR3R4			;Check state of last two rows
	MOV A, #0FH
	JNB B.7, END_GET_KEYPRESS	;If bit is not set end proc	
	MOV A, #09H
	JNB B.6, END_GET_KEYPRESS
	MOV A, #06H		
	JNB B.5, END_GET_KEYPRESS
	MOV A, #03H
	JNB B.4, END_GET_KEYPRESS
	MOV A, #0DH
	JNB B.3, END_GET_KEYPRESS
	MOV A, #0CH
	JNB B.2, END_GET_KEYPRESS
	MOV A, #0BH
	JNB B.1, END_GET_KEYPRESS
	MOV A, #0AH
	JNB B.0, END_GET_KEYPRESS
	MOV A, 0FFH
END_GET_KEYPRESS:
	POP 0F0H
	RET
;********
;* Write 7 seg byte
;* Writes Accumulator to 7 segment display
;********
WRITE_TO_7SEG:
	SETB P3.5
	MOV DPH, #SEGADDR
	MOV DPL, #33H	;doesnt matter
	MOVX @DPTR, A
	CLR P3.5
	RET
WRITE_TO_LCD_CMD:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #00H		;Instruction address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	RET
WRITE_TO_LCD_DATA:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #01H		;DATA address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	RET
READ_FROM_LCD_CMD:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #02H		;Instruction address READ
	MOVX A, @DPTR
	CLR P3.5
	RET
;*******
;* Is LCD Busy function
;* Loops while the LCD is BUSY
;*******	
IS_LCD_BUSY:
 	ACALL READ_FROM_LCD_CMD		;Read LCD controller
 	ANL A, #80H			;Mask BF
 	JNZ IS_LCD_BUSY
 	RET
;*******
;* LCD Init
;* Initializes the LCD with the follwing specs ()
;********
INIT_LCD:
	MOV A, #00111100B		;Function set
	ACALL WRITE_TO_LCD_CMD		
	MOV A, #0FEH			;Status Marker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00111100B		;Function set
	ACALL WRITE_TO_LCD_CMD
	MOV A, #0FDH			;Status Marker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00001111B		;Display ON
	ACALL WRITE_TO_LCD_CMD		
	MOV A, #0FBH			;Status Marker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00000001B		;Clear Display
	ACALL WRITE_TO_LCD_CMD		
	MOV A, #0F7H			;Status Marker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00000110B		;Set Entry Mode
	ACALL WRITE_TO_LCD_CMD	
	MOV A, #0EFH			;Status Marker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #01000000B
	ACALL WRITE_TO_LCD_CMD		;CG RAM
	MOV A, #0DFH			;Status Mraker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #10000000B
	ACALL WRITE_TO_LCD_CMD		;DDR RAM
	MOV A, #0BFH			;Status marer
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00000010B
	ACALL WRITE_TO_LCD_CMD
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	RET		
;********
;* Is less than or equal to
;* checks to see if B is less than or equal to A
;* Set F0 accordingly
;*********
IS_LESS_OR_EQUAL:
	PUSH 0E0H
	MOV PSW, #00H		;Clear PSW to not alter subb
	SUBB A, B		;A > B
	MOV F0, C		;Set based on carry
	CPL F0	
	POP 0E0H
	RET
;********
;* 3 to 8 logic
;* dumb function that mimic three to 8 logic
;********
L3TO8:
	MOV A, KPR3R4		; Load R3, R4 data
	CPL A
	ANL A, #07H		; Wipe all but last three keys  (C, B, A)
	MOV DPTR, #SEGTABLE	; Mov dptr to segment table
	MOVC A, @A+DPTR		; Load
	RET
;********
;* 0 through 7 logic
;* dumb function that mimics 0 through 7 logic
;********
L0THR7:
	ACALL GET_KEYPRESS_HEX
	MOV B, A
	MOV A, #07H
	ACALL IS_LESS_OR_EQUAL
	JNB F0, NOT_7
	MOV A, B
	MOV DPTR, #SEGTABLE	; Mov dptr to segment table
	MOVC A, @A+DPTR		; Load
	MOV LAST_WRITE, A		; Store last displayed value
	RET
NOT_7:  
	MOV A, LAST_WRITE		;Load last displayed value
	RET
	
;**********
;* Set state logic
;* dumb function that mimic state machine
;*********
SET_STATE:
	MOV A, KPR3R4
	CPL A
	ANL A, #80H		;Check #
	JZ EXIT_SET_STATE	;# Not pressed
STATE_LOOP:
	ACALL KEYPAD_SCAN	;# Is pressed loop untill it is not pressed
	ACALL KEYPAD_SCAN	;Allow for bouncing
	ACALL KEYPAD_SCAN	
	MOV A, KPR3R4
	CPL A
	ANL A, #80H
	JNZ STATE_LOOP		;# still pressed
	MOV A, PROG_STATE		;INV STATE
	CPL A
	MOV PROG_STATE, A
	ACALL INIT_PROC
EXIT_SET_STATE:
   	RET

SEGTABLE: DB 0FEH,0FDH,0FBH,0F7H,0EFH,0DFH,0BFH,7FH;a, b, c, d, e, f, g, df 
END