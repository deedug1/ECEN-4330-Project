CONV EQU 000BH
TEMP EQU 000CH
ADCADDRH EQU 60H
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