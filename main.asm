PROG_STATE EQU 11H
KPR1R2 EQU 08H
KPR3R4 EQU 09H
LAST_CONV EQU 0BH
HUNDREDS EQU 0CH
TENS EQU 0DH
ONES EQU 0EH
SEGADDR EQU 0H
LCDADDRH EQU 40H
ADCADDRH EQU 80H
RTCADDRH EQU 0C0H
LAST_WRITE EQU 0AH
TEMPR_CONST EQU 18		; Constant used for temperature conversion
S1 EQU 20H				; Constants used for RTC Registers
S10 EQU 21H
MI1 EQU 22H
MI10 EQU 23H
H1 EQU 24H
H10 EQU 25H
D1 EQU 26H
D10 EQU 27H
MO1 EQU 28H
MO10 EQU 29H
Y1 EQU 2AH
Y10 EQU 2BH
W EQU 2CH
CD EQU 2DH
CE EQU 2EH
CF EQU 2FH

ORG 0
	
	;Init
	MOV SP, #50H		;Mov SP out of BANK
	MOV PROG_STATE, #00H	;Set first state
	ACALL INIT_PROC
	ACALL INIT_LCD		;Init LCD
	ACALL INIT_RTC		;Init RTC
	ACALL RAM_TEST
	;Init end
;Program start
;****
;* Note: register 1 holds state
;****
MAIN:
	
	ACALL KEYPAD_SCAN	;Allow for bouncing
	ACALL KEYPAD_SCAN
	ACALL KEYPAD_SCAN
	MOV R0, #MI1
	ACALL READ_FROM_RTC
	ACALL IS_RTC_BUSY
	MOV R0, #MI10
	ACALL READ_FROM_RTC
	ACALL IS_RTC_BUSY
	ACALL SET_STATE
	ACALL DO_CONVERSION
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
;******
;* RTC Interface
;* Procedures that deal with interfacing with the RTC
;******
;*******
;* Rtc initialize function
;* Initializes the RTC and sets all registers to 0 
;*******
INIT_RTC:
	PUSH 0
	PUSH 1					; Push R1, R0 for work
	MOV R0, #CF				
	MOV A, #00H
	ACALL WRITE_TO_RTC		; Start counter and init reset
	MOV R0, #CD
	MOV A, #00H
	ACALL WRITE_TO_RTC		; Set CD Register
	ACALL IS_RTC_BUSY
	MOV R0, #CF
	MOV A, #07H				; Stop counter and reset counter set to 24hr mode
	ACALL WRITE_TO_RTC	
	MOV A, #00H				; Setup for RTC wipe loop
	MOV R0, #S1
	MOV R1, #0BH			; 12 DATA REGISTERS
INIT_RTC_LOOP:
	ACALL WRITE_TO_RTC
	INC R0					; Increment for next RTC reg
	DJNZ R1, INIT_RTC_LOOP			
	POP 1
	POP 0
	RET
;******
;* Is RTC Busy function
;* stalls cpu untill the RTC is usable 
;* Note: R0 is changed
;******
IS_RTC_BUSY:
	MOV R0, #CD
	MOV A, #00H
	ACALL WRITE_TO_RTC
	MOV A, #01H
	ACALL WRITE_TO_RTC
	ACALL READ_FROM_RTC
	ANL A, #02H
	JNZ IS_RTC_BUSY
	MOV A, #00H
	ACALL WRITE_TO_RTC
	RET
;**********
;* Write to RTC function
;* Writes to the RTC I/O Port with R0 as the address and A as the data
;**********
WRITE_TO_RTC:
	SETB P3.5			; Set to I/O map
	MOV DPH, #RTCADDRH
	MOV DPL, R0			; Set lower address
	MOVX @DPTR, A			; Do write
	CLR P3.5
	RET
;**********
;* Read from RTC function
;* Reads from the RTC I/O Port with R0 as the address and A as the data
;* Note: Stores value at address in R0 
;**********
READ_FROM_RTC:
	SETB P3.5			; Set to I/O map
	MOV DPH, #RTCADDRH
	MOV DPL, R0			; Set lower address
	MOVX A, @DPTR		; Do read
	MOV @R0, A		; Store read
	CLR P3.5
	RET
;******
;* ADC Interface
;* Procedures that deal with interfacing with the ADC
;******
;******
;* Read ADC Conversion Function
;* tells the ADC to perform a conversion waits 1ms and reads the conversion
;******
READ_CONVERSION:
	SETB P3.5
	MOV DPH, #ADCADDRH
	MOV DPL, #00H
	MOVX @DPTR, A
	ACALL DELAY_1MS
	MOVX A, @DPTR
	MOV LAST_CONV, A
	CLR P3.5
	RET
;******
;* LCD Interface
;* Procedures that deal with interfacing with the LCD
;******
;******
;* Write to LCD DATA and wait function
;* Combiner function that writes to the LCD and waits while the LCD is not busy
;******
WRITE_TO_LCD_DATA_WAIT:
	ACALL WHILE_LCD_BUSY
	ACALL WRITE_TO_LCD_DATA
	RET
;******
;* Write to LCD CMD and wait function
;* Combiner function that writes to the LCD and waits while the LCD is not busy
;******
WRITE_TO_LCD_CMD_WAIT:
	ACALL WHILE_LCD_BUSY
	ACALL WRITE_TO_LCD_CMD
	RET
;******
;* LCD command write function
;* Writes data stored in A to the LCD CMD register
;******
WRITE_TO_LCD_CMD:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #00H		;Instruction address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	RET
;******
;* LCD data write function
;* Writes data stored in A to the LCD data register
;******
WRITE_TO_LCD_DATA:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #01H		;DATA address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	RET
;******
;* LCD control read function
;* Reads the LCD control register
;******
READ_FROM_LCD_CMD:
	SETB P3.5
	MOV DPH, #LCDADDRH
	MOV DPL, #02H		;Instruction address READ
	MOVX A, @DPTR
	CLR P3.5
	RET
;*******
;* Clear LCD function
;* Clears LCD screen
;*******	
CLEAR_LCD:
	MOV A, #00000001B	;Clear display
	ACALL WRITE_TO_LCD_CMD	
	RET
;*******
;* Return home LCD function
;* Returns the LCD cursor to the home posistion (wherever that is)
;*******
CURSOR_HOME:
	MOV A, #00000010B
	ACALL WRITE_TO_LCD_CMD
	RET
;*******
;* While LCD Busy function
;* Loops while the LCD is BUSY
;*******	
WHILE_LCD_BUSY:
 	ACALL READ_FROM_LCD_CMD		;Read LCD controller
 	ANL A, #80H					;Mask Busy Flag
 	JNZ WHILE_LCD_BUSY
 	RET
;*******
;* LCD Init
;* Initializes the LCD with the follwing specs (TBD)
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
	ACALL WRITE_TO_LCD_CMD	;CG RAM
	MOV A, #0DFH			;Status Mraker
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #10000000B
	ACALL WRITE_TO_LCD_CMD	;DDR RAM
	MOV A, #0BFH			;Status marer
	ACALL WRITE_TO_7SEG
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	MOV A, #00000010B
	ACALL WRITE_TO_LCD_CMD
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	RET
;******
;* Binary to BCD converter function
;* Converts an 8 bit binary in A to 4 bit BCD
;* Stores the result in ram adresses 0CH, 0DH, 0EH
;*****		
BINARY_TO_BCD:
	PUSH 0E0H		;Push registers for work
	PUSH 0F0H
	MOV B, #100
	DIV AB			;Divide A contains remainder
	MOV HUNDREDS, A		;Store quotient
	MOV A, B
	MOV B, #10
	DIV AB			;Divide A contains remainder
	MOV TENS, A		;Store quotient
	MOV A, B
	MOV B, #1		
	DIV AB			;Divide A contains remainder
	MOV ONES, A		;Store quotient
	POP 0F0H		;Pop registers
	POP 0E0H
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
;********
;* 3 to 8 logic
;* dumb function that mimic three to 8 logic
;********
L3TO8:
	MOV A, KPR3R4		; Load R3, R4 data
	CPL A
	ANL A, #07H			; Wipe all but last three keys  (C, B, A)
	MOV DPTR, #SEGTABLE	; Mov dptr to segment table
	MOVC A, @A+DPTR		; Load
	RET
;*********
;* EX RAM test
;* Function for testing the External ram of the system
;********
RAM_TEST:
	CLR P3.5			; Move to memory map
	MOV DPTR, #0F0FFH
	MOV A, #'Z'
	MOVX @DPTR, A
	MOV DPTR, #0000H
	MOV A, #'A'
	MOVX @DPTR, A
	MOVX A, @DPTR
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV DPTR, #0F0FFH
	MOVX A, @DPTR
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV A, #'D'
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	RET
;*****
;* do a conversion
;* Dumb function that does a conversion and displays the value scanned if * key was pressed
;******
DO_CONVERSION:
	MOV A, KPR1R2			; Check to see if star was pressed
	CPL A
	ANL A, #80H
	JZ  END_DO_CONVERSION	; * was not pressed
CONVERSION_LOOP:
	ACALL KEYPAD_SCAN		; * Is pressed loop untill it is not pressed
	ACALL KEYPAD_SCAN		; Allow for bouncing
	ACALL KEYPAD_SCAN	
	MOV A, KPR1R2
	CPL A
	ANL A, #80H
	JNZ CONVERSION_LOOP		; # still pressed
	ACALL READ_CONVERSION	; Start conversion and display
	MOV A, LAST_CONV		; Load last conversion value
	MOV B, #TEMPR_CONST
	MUL AB					; LSB store in ACC
	MOV B, #10		
	DIV AB					; Divide by 10 to convert from volts to Celsius 
	ACALL BINARY_TO_BCD		; Convert to BCD to print
	ACALL CLEAR_LCD			; Reset LCD
	ACALL WHILE_LCD_BUSY
	ACALL CURSOR_HOME
	ACALL WHILE_LCD_BUSY
	MOV A, HUNDREDS			; Write 100s
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV A, TENS				; Write 10s
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV A, ONES				; Write 1s
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV A, MI10
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	MOV A, MI1
	ORL A, #30H
	ACALL WRITE_TO_LCD_DATA
	ACALL WHILE_LCD_BUSY
	;End do conversion and display
END_DO_CONVERSION:
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