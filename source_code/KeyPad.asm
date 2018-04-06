KPR1R2 EQU 08H
KPR3R4 EQU 09H
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