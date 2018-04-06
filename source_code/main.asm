SEGADDR EQU 00H
LC EQU 30H			;Loading character

ORG 0
	LJMP INIT				;Jump over vector table
	;Vector Table

ORG 30H
$INCLUDE(LCD.asm)			; Include all src files 
$INCLUDE(RTC.asm)
$INCLUDE(ADC.asm)
$INCLUDE(KeyPad.asm)
INIT:
	MOV SP, #50H			;Mov SP out of BANK
	ACALL INIT_LCD			; Init LCD
	ACALL INIT_RTC			; Init RTC
	ACALL COLOR_SWATCH		; Test colors
	MOV A, #05H				; Set to green
	ACALL WRITE_TO_LCDCLR	
	ACALL RAM_TEST			; Test Ram
	ACALL CLEAR_LCD
	MOV A, #00H				; Display name/class
	ACALL SET_LCD_LINE
	MOV DPTR, #SPLASH1
	ACALL WRITE_STRCNST_TO_LCD
	MOV A, #01H
	ACALL SET_LCD_LINE
	MOV DPTR, #SPLASH2
	ACALL WRITE_STRCNST_TO_LCD
	MOV R1, #10
	ACALL DELAY_XMS
	ACALL CLEAR_LCD

	;Init end
;Program start
;****
;* Note: register 1 holds state
;****
MAIN:
	ACALL READ_HMS_FROM_RTC				; Update h, m, s
	ACALL READ_CONVERSION				; Update temp
	; Write time
	MOV A, #0CH
	ACALL SET_LCD_DDRAM_ADDR
	MOV A, H10
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, H1
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, #':'
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, MI10
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, MI1
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, #':'
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, S10
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	MOV A, S1
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA_WAIT
	ACALL CONVERT_TEMP
	MOV DPTR, #0000H
	MOV R0, A
	ACALL BYTE_TO_STRING
	MOV A, #00H
	ACALL SET_LCD_DDRAM_ADDR
	MOV DPTR, #TEMP_PRE
	ACALL WRITE_STRCNST_TO_LCD
	MOV DPTR, #0000H
	ACALL WRITE_STR_TO_LCD
	;MOV DPTR, #CONV
	;MOVX A, @DPTR
	;ACALL WRITE_TO_LCD_DATA_WAIT
	MOV DPTR, #TEMP_SUF
	ACALL WRITE_STRCNST_TO_LCD
	MOV R1, #10
	ACALL DELAY_XMS
	JMP MAIN
;*********
;* Loading state
;* Retrieves character and updates loading character
;********
UPDATE_LC:
	PUSH 0F0H
	PUSH 0E0H
	PUSH DPH
	PUSH DPL
	INC LC
	MOV B, #04H
	MOV A, LC
	DIV AB
	MOV A, B		;B has remainder
	MOV DPTR, #LOADINGTABLE
	MOVC A, @A+DPTR
	POP DPL
	POP DPH
	POP 0E0H
	POP 0F0H
	RET
	

;*********
;* Delay
;* Delays for 255 * 50 clks
;*********
DELAY_1MS:
	PUSH  3	
	PUSH  4
	MOV   R3, #50			;original 50
HERE2: 
	MOV   R4, #255		;original 255
HERE1: 
	DJNZ  R4, HERE1 	;If R4 != 0 Jump to HERE1
	DJNZ  R3, HERE2		;If R3 != 0 Jump to HERE2
	POP   4
	POP   3
	RET
DELAY_XMS:
	PUSH 1
	HERE3:
	ACALL DELAY_1MS 	; Calls Delay 1ms R1 times
	DJNZ R1, DELAY_XMS
	POP 1
	RET
;********
;* Write 7 seg byte
;* Writes Accumulator to 7 segment display
;********
WRITE_TO_7SEG:
	PUSH DPH
	PUSH DPL
	SETB P3.5
	MOV DPH, #SEGADDR
	MOV DPL, #33H	;doesnt matter
	MOVX @DPTR, A
	CLR P3.5
	POP DPL
	POP DPH
	RET
;********
;* Is less than or equal to
;* checks to see if B is less than or equal to A
;* Set F0 accordingly
;*********
IS_LESS_OR_EQUAL:
	PUSH 0E0H
	MOV PSW, #00H	;Clear PSW to not alter subb
	SUBB A, B		;A > B
	MOV F0, C		;Set based on carry
	CPL F0	
	POP 0E0H
	RET

;*********
;* EX RAM test
;* Function for testing the External ram of the system
;********
RAM_TEST:
	MOV DPTR, #RAMTEST_M
	ACALL WRITE_STRCNST_TO_LCD		; Write first string
	; Begin test
	CLR P3.5					;Set to Memory Map
	MOV DPTR, #0000H			;Start at the beginning
	RAM_TEST_WRITE_LOOP:
	MOV A, #55H					;Test val
	MOVX @DPTR, A				;Write
	INC DPTR					;next address
	MOV A, DPH	
	MOV B, DPL
	ADD A, B
	JNZ RAM_TEST_WRITE_LOOP
	MOV DPTR, #0000H			;Verify from beginning
	RAM_TEST_READ_LOOP:
	MOV A, #55H
	MOVX A, @DPTR
	CJNE A, #55H, RAM_TEST_ERROR
	INC DPTR
	MOV A, DPH
	MOV B, DPL
	ADD A, B
	JNZ RAM_TEST_READ_LOOP
	RET
RAM_TEST_ERROR:
	MOV A, #00H
	ACALL SET_LCD_LINE
	MOV DPTR, #RAMTESTE_M
	ACALL WRITE_STRCNST_TO_LCD
	RET
;*********
;* General functions
;*********
;*********
;* Byte to string
;* Converts a byte to a decimal coded string placed @DPTR
;********
BYTE_TO_STRING:
	PUSH 0E0H	
	PUSH 0F0H	
	PUSH 1		; Work regs
	; Calculate String length
	CLR P3.5	; Set to EX-RAM
	MOV A, R0
	MOV R1, #00H
STRING_LENGTH_LOOP:
	MOV B, #10
	DIV AB
	INC R1
	JNZ STRING_LENGTH_LOOP
	MOV A, R1		; Place terminator
	ADD A, DPL
	MOV DPL, A
	MOV A, #00H
	ADDC A, DPH
	MOV DPH, A
	MOV A, #00H
	MOVX @DPTR, A
	MOV A, R0
CONVERT_LOOP:
	MOV B, #10
	DIV AB				; Divide by 10
	XCH A, B
	ORL A, #30H		; Store  remainder value in DPTR - 1
	PUSH 0E0H
	MOV A, DPL
	SUBB A, #01H
	MOV DPL, A
	MOV A, DPH
	SUBB A, #00H
	MOV DPH, A
	POP 0E0H
	MOVX @DPTR, A
	XCH A, B
	JNZ CONVERT_LOOP
	POP 1
	POP 0F0H
	POP 0E0H
	RET

COLOR_SWATCH:
	MOV R7, #07H
COLOR_LOOP:
	MOV A, R7
	ACALL WRITE_TO_LCDCLR
	MOV R1, #10
	ACALL DELAY_XMS
	DJNZ R7, COLOR_LOOP
	RET

SEGTABLE: DB 0FEH,0FDH,0FBH,0F7H,0EFH,0DFH,0BFH,7FH;a, b, c, d, e, f, g, df 
LOADINGTABLE: DB "-\|/"
RAMTEST_M: DB  "   TESTING EXRAM    ",0
RAMTESTE_M: DB "    EXRAM ERROR     ",0
SPLASH1: DB "Justin Pachl", 0
SPLASH2: DB "ECEN-4330 2018",0
TEMP_PRE: DB "TEMP: ",0
TEMP_SUF: DB 0DFH, 43H, 00H
END