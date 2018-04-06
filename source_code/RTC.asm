RTCADDRH EQU 80H
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
