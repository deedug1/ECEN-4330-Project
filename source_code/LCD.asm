LCDADDRH EQU 20H
LCDCLRADDRH EQU 40H	
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
    LCDLINETABLE: DB 00H, 40H, 14H, 54H ;line_1, line_2, line_3, line_4 
