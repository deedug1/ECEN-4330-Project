// ChipSelect Code

module chip_select(PSEN, WR, RD, A15, A14, A13, P3_5,
 SEGCSWR, RTCCS, LCDCS, COLOR_CS, ROM1CS, ROM2CS, RAM1CS, RAM2CS, ADCCS  );
	
	//Inputs
	input PSEN;				/*synthesis loc="P2"*/
	input A15;				/*synthesis loc="P3"*/
	input A14;				/*synthesis loc="P4"*/
	input A13;				/*synthesis loc="P5"*/
	input WR;				/*synthesis loc="P6"*/
	input RD;				/*synthesis loc="P7"*/
	input P3_5;	 			/*synthesis loc="P8"*/
	
	
	
	// I/O Pin assignments
	output SEGCSWR;		/*synthesis loc="P23"*/
	output RTCCS;		/*synthesis loc="P22"*/
	output LCDCS;		/*synthesis loc="P21"*/
	output ADCCS;		/*synthesis loc="P14"*/
	output COLOR_CS;	/*synthesis loc="P20"*/
	
	// Memory Pin assignments
	output ROM1CS;	/*synthesis loc="P18"*/
	output ROM2CS;	/*synthesis loc="P17"*/
	output RAM1CS;	/*synthesis loc="P16"*/
	output RAM2CS;	/*synthesis loc="P15"*/
	
	
	// I/O Logic
	assign SEGCSWR = ~WR & P3_5 & PSEN & ~A15 & ~A14 & ~A13;
	assign RTCCS = ~P3_5 | ~PSEN | ~A15 | A14 | A13;
	assign LCDCS = P3_5 & PSEN & ~A15 & ~A14 & A13 & (~RD | ~WR); 
	assign ADCCS = ~P3_5 | ~PSEN | A15 | ~A14 | ~A13;
	assign COLOR_CS =  ~ WR & P3_5 & PSEN & ~A15 & A14 & ~A13 
	
	// Memory logic
	assign ROM1CS = PSEN | A15;
	assign ROM2CS = PSEN | ~A15;
	assign RAM1CS = P3_5 | ~PSEN | A15;
	assign RAM2CS = P3_5 | ~PSEN  | ~A15;
	
	
		
endmodule