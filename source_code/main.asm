KPR1R2 EQU 08H
KPR3R4 EQU 09H
CONV EQU 000BH
TEMP EQU 000CH
HUNDREDS EQU 0CH
TENS EQU 0DH
ONES EQU 0EH
SEGADDR EQU 00H
LCDADDRH EQU 20H
LCDCLRADDRH EQU 40H
ADCADDRH EQU 60H
RTCADDRH EQU 80H
LAST_WRITE EQU 0AH
TEMPR_CONST EQU 18		; Constant used for temperature conversion
S1 EQU 20H						; Constants used for RTC Registers
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
LC EQU 30H			;Loading character
LCDL1 EQU 0FF00H
LCDL2 EQU 0FF14H
LCDL3 EQU 0FF28H
LCDL4 EQU 0FF3CH

ORG 0
	LJMP INIT				;Jump over vector table
	;Vector Table
	
ORG 30H
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
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
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
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	JMP MAIN
;*********
;* Loading state
;* Retrieves character and updates loading character
;********
UPDATE_LC:
	PUSH 0F0H
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
	POP 0F0H
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
	MOV R0, #CF				
	MOV A, #04H
	ACALL WRITE_TO_RTC		; Start counter and init reset
	MOV R0, #CD
	MOV A, #04H
	ACALL WRITE_TO_RTC		; Set CD Register
	ACALL WHILE_RTC_BUSY
	MOV R0, #CF
	MOV A, #07H				; Stop counter and reset counter set to 24hr mode
	ACALL WRITE_TO_RTC	
	MOV A, #00H				; Setup for RTC wipe loop
	MOV R0, #S1
	ACALL WRITE_TO_RTC		;S10
	MOV R0, #S10
	ACALL WRITE_TO_RTC		;MI1
	MOV R0, #MI1
	ACALL WRITE_TO_RTC		;MI10
	MOV R0, #MI10
	ACALL WRITE_TO_RTC		;H1
	MOV R0, #H1
	ACALL WRITE_TO_RTC		;H10
	MOV R0, #H10
	ACALL WRITE_TO_RTC		;D1
	MOV R0, #D1
	ACALL WRITE_TO_RTC		;D10
	MOV R0, #D10
	ACALL WRITE_TO_RTC		;MO1
	MOV R0, #MO1
	ACALL WRITE_TO_RTC		;MO1
	MOV R0, #MO10
	ACALL WRITE_TO_RTC		;MO10
	MOV R0, #Y1
	ACALL WRITE_TO_RTC		;Y1
	MOV R0, #Y10
	ACALL WRITE_TO_RTC		;Y10
	MOV R0, #W
	ACALL WRITE_TO_RTC		;W
	MOV R0, #CF
	MOV A, #04H			; Un-stop
	ACALL WRITE_TO_RTC
	POP 0
	RET
;******
;* Is RTC Busy function
;* stalls cpu untill the RTC is usable 
;* Note: R0 is changed
;******
WHILE_RTC_BUSY:
	PUSH 0E0H
	PUSH 0
WHILE_RTC_BUSY_LOOP:
	MOV R0, #CD
	MOV A, #00H
	ACALL WRITE_TO_RTC
	MOV A, #01H
	ACALL WRITE_TO_RTC
	ACALL READ_FROM_RTC
	ANL A, #02H
	JNZ WHILE_RTC_BUSY_LOOP
	MOV A, #00H
	ACALL WRITE_TO_RTC
	POP 0
	POP 0E0H
	RET
;**********
;* Write to RTC function
;* Writes to the RTC I/O Port with R0 as the address and A as the data
;**********
WRITE_TO_RTC:
	PUSH DPH
	PUSH DPL
	SETB P3.5			; Set to I/O map
	MOV DPH, #RTCADDRH
	MOV DPL, R0			; Set lower address
	MOVX @DPTR, A		; Do write
	CLR P3.5
	POP DPL
	POP DPH
	RET
;**********
;* Read from RTC function
;* Reads from the RTC I/O Port with R0 as the address and A as the data
;* Note: Stores value at address in R0 
;**********
READ_FROM_RTC:
	PUSH DPH
	PUSH DPL
	SETB P3.5			; Set to I/O map
	MOV DPH, #RTCADDRH
	MOV DPL, R0			; Set lower address
	MOVX A, @DPTR		; Do read
	ANL A, #0FH			; Remove garbage in high nibble
	MOV @R0, A			; Store read
	CLR P3.5
	POP DPH
	POP DPL
	RET
;********
;* Read Hours Minutes and Seconds function
;* Function that reads the hours and minutes and seconds registers of the RTC.
;*******
READ_HMS_FROM_RTC:
	PUSH 0
	PUSH 0E0H
	MOV R0, #H10
READ_HMS_LOOP:
	ACALL WHILE_RTC_BUSY		; Make sure RTC is not busy
	ACALL READ_FROM_RTC			; Read current register and store in ram
	DEC R0
	MOV A, R0
	CJNE A, #19H, READ_HMS_LOOP ; Repeat until finished
	POP 0E0H
	POP 0
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
	PUSH DPH
	PUSH DPL
	SETB P3.5
	MOV DPH, #ADCADDRH
	MOV DPL, #00H
	MOVX @DPTR, A
	ACALL DELAY_1MS
	MOVX A, @DPTR
	CLR P3.5
	MOV DPTR, #CONV
	MOVX @DPTR, A
	POP DPL
	POP DPH
	RET
;******
;*	Convert Temperature funciton
;*  Converts the CONVerstion to temperature and stores the result in TEMP
;****** 
CONVERT_TEMP:
	PUSH DPH
	PUSH DPL					; Push A, DPTR for work
	CLR P3.5
	MOV DPTR, #CONV				; Load last conversion
	MOVX A, @DPTR
	CLR C
	RLC A
	MOV DPTR, #TEMP
	MOVX @DPTR, A				; store calculated temp
	POP DPL
	POP DPH
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
	PUSH DPH
	PUSH DPL
	MOV DPH, #LCDADDRH
	MOV DPL, #00H		;Instruction address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	POP DPL
	POP DPH
	RET
;******
;* LCD data write function
;* Writes data stored in A to the LCD data register
;******
WRITE_TO_LCD_DATA:
	SETB P3.5
	PUSH DPH
	PUSH DPL
	MOV DPH, #LCDADDRH
	MOV DPL, #01H		;DATA address WRITE
	MOVX @DPTR, A		;Write what is stored in A
	CLR P3.5
	POP DPL
	POP DPH
	RET
;******
;* LCD control read function
;* Reads the LCD control register
;******
READ_FROM_LCD_CMD:
	SETB P3.5
	PUSH DPH
	PUSH DPL
	MOV DPH, #LCDADDRH
	MOV DPL, #02H		;Instruction address READ
	MOVX A, @DPTR
	CLR P3.5
	POP DPL
	POP DPH
	RET
;*******
;* While LCD Busy function
;* Loops while the LCD is BUSY
;*******	
WHILE_LCD_BUSY:
	PUSH 0E0H
WHILE_LCD_BUSY_LOOP:
 	ACALL READ_FROM_LCD_CMD		;Read LCD controller
 	ANL A, #80H					;Mask Busy Flag
 	JNZ WHILE_LCD_BUSY_LOOP
	POP 0E0H
 	RET
;*******
;* Write to LCD COLOR PORT fuction
;* Writes a value in A to the LCD Color port
;*******
WRITE_TO_LCDCLR:
	SETB P3.5
	MOV DPH, #LCDCLRADDRH
	MOV DPL, #00H		;Doesn't matter
	MOVX @DPTR, A		
	CLR P3.5
	RET
;*******
;* Write to LCD String function
;* Write 0 Terminated string CONSTANT to LCD 
;* DPTR is assumed to be set to location of String
;*******
WRITE_STRCNST_TO_LCD:
	PUSH DPH
	PUSH DPL
	PUSH 0E0H
STRCNST_WRITE_LOOP:
	MOV A, #00H
	MOVC A, @A+DPTR			
	JZ END_WRITE_STRCNST_TO_LCD	; Found 0 end loop
	ACALL WRITE_TO_LCD_DATA_WAIT
	INC DPTR					; INC OFFSET
	SJMP STRCNST_WRITE_LOOP
END_WRITE_STRCNST_TO_LCD:
	POP 0E0H
	POP DPL				
	POP DPH
	RET
;*******
;* Write to LCD String function
;* Write 0 Terminated string to LCD 
;* DPTR is assumed to be set to location of String
;*******
WRITE_STR_TO_LCD:
	PUSH DPH
	PUSH DPL
	PUSH 0E0H
STR_WRITE_LOOP:
	MOV A, #00H
	MOVX A, @DPTR			
	JZ END_WRITE_STR_TO_LCD	; Found 0 end loop
	ACALL WRITE_TO_LCD_DATA_WAIT
	INC DPTR					; INC OFFSET
	SJMP STR_WRITE_LOOP
END_WRITE_STR_TO_LCD:
	POP 0E0H
	POP DPL				
	POP DPH
	RET
;*******
;* Clear LCD function
;* Clears LCD screen
;*******	
CLEAR_LCD:
	PUSH 0E0H
	MOV A, #00000001B	;Clear display
	ACALL WRITE_TO_LCD_CMD	
	POP 0E0H
	RET
;*******
;* Return home LCD function
;* Returns the LCD cursor to the home posistion (wherever that is)
;*******
CURSOR_HOME:
	PUSH 0E0H
	MOV A, #00000010B
	ACALL WRITE_TO_LCD_CMD
	POP 0E0H
	RET

;*******
;* Set line funciton
;* Sets the cursor to the start of the line stored in A (0-3)
;*******
SET_LCD_LINE:
	PUSH 0E0H
	PUSH DPH
	PUSH DPL
	MOV DPTR, #LCDLINETABLE	;Set dptr to address of linetable
	MOVC A, @A+DPTR			;Load value from table
	ACALL SET_LCD_DDRAM_ADDR
	POP DPL
	POP DPH
	POP 0E0H
	RET

;*******
;* Write to LCD DDRAM Address
;* Changes pointer to LCD DDRAM and sets up the LCD_WRITE_DATA to write to DDRAM
;*******
SET_LCD_DDRAM_ADDR:
	PUSH 0E0H
	ORL A, #80H
	ACALL WRITE_TO_LCD_CMD_WAIT
	POP 0E0H
	RET
;*******
;* Write to LCD CGRAM Address
;* Changes pointer to LCD CGRAM and sets up the LCD_WRITE_DATA to write to CGRAM
;*******
SET_LCD_CGRAM_ADDR:
	PUSH 0E0H
	ORL A, #40H
	ACALL WRITE_TO_LCD_CMD_WAIT
	POP 0E0H
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
	MOV A, #00001100B		;Display ON
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
;* Binary to BCD converter function (TODO)
;* Converts an 8 bit binary in A to 4 bit BCD
;* Stores the result in ram adresses 0CH, 0DH, 0EH
;*****		
BINARY_TO_BCD:
	PUSH 0E0H		;Push registers for work
	PUSH 0F0H
	MOV B, #100
	DIV AB				;Divide A contains quotient
	MOV HUNDREDS, A		;Store quotient
	MOV A, B
	MOV B, #10
	DIV AB				;Divide A contains quotient
	MOV TENS, A			;Store quotient
	MOV A, B
	MOV B, #1		
	DIV AB				;Divide A contains quotient
	MOV ONES, A			;Store quotient
	POP 0F0H			;Pop registers
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
;* Converts a byte to a decimal coded string
;********
BYTE_TO_STRING:
	PUSH 0E0H	
	PUSH 0F0H	
	PUSH 1; Work regs
	; Calculate String length
	CLR P3.5	; Set to EX-RAM
	MOV A, R0
	MOV R1, #00H
STRING_LENGTH_LOOP:
	MOV B, #10
	DIV AB
	INC R1
	JNZ STRING_LENGTH_LOOP
	MOV A, R1	; Place terminator
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
	DIV AB			; Divide by 10
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
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	ACALL DELAY_1MS
	DJNZ R7, COLOR_LOOP
	RET
LCDLINETABLE: DB 00H, 40H, 14H, 54H ;line_1, line_2, line_3, line_4 
SEGTABLE: DB 0FEH,0FDH,0FBH,0F7H,0EFH,0DFH,0BFH,7FH;a, b, c, d, e, f, g, df 
LOADINGTABLE: DB "-\|/"
RAMTEST_M: DB  "   TESTING EXRAM    ",0
RAMTESTE_M: DB "    EXRAM ERROR     ",0
SPLASH1: DB "Justin Pachl", 0
SPLASH2: DB "ECEN-4330 2018",0
TEMP_PRE: DB "TEMP: ",0
TEMP_SUF: DB 0DFH, 43H, 00H
END