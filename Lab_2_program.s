;*----------------------------------------------------------------------------
;* Name: Lab_2_program.s 
;* Purpose: This code template is for Lab 2
;* Author: Eric Praetzel and Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
	THUMB 		; Declare THUMB instruction set 
        AREA 		My_code, CODE, READONLY 	; 
        EXPORT 		__MAIN 		; Label __MAIN is used externally q
	ENTRY 
__MAIN
; The following lines are similar to Lab-1 but use an address, in r4, to make it easier.
; Note that one still needs to use the offsets of 0x20 and 0x40 to access the ports
;
; Turn off all LEDs 
	MOV 		R2, #0xC000				; move 0xC000 into R2
	MOV 		R3, #0xB0000000			; write 0xB0000000 into R3
	MOV 		R4, #0x0				; assign 0x0000 into R4 and clear the upper word
	MOVT 		R4, #0x2009				; assign 0x2009 into R4's upper word 
	ADD 		R4, R4, R2 				; 0x2009C000 - the base address for dealing with the I/O ports
	; Writing 0xB0000000 into memory address 0x2009C020 turns “off” the three LEDs on port 1
	STR 		R3, [R4, #0x20]			           ; Turn off the three LEDs on port 1
	; Writing 0x0000007C into memory address 0x2009C040 turns “off” the five LEDs on port 2
	MOV 		R3, #0x0000007C			; write 0x0000007C into R3
	STR 		R3, [R4, #0x40] 		                      ; Turn off five LEDs on port 2 
	
	MOV 		R8, #0xC000				; move 0xC000 into R8
	MOV 		R9, #0x0			            ; move 0x0 into R9 and clear its upper word
	MOVT 		R9, #0x2009				; move 0x2009 into R9's upper word
	ADD 		R9, R9, R8 				; add 0xC000 with 0x20090000, to get 0x2009C000 - the base address for dealing with the ports

ResetLUT
	LDR                      R5, =InputLUT                                       ; assign R5 to the address at label LUT

; Start processing the characters
				
NextChar
	LDRB       	R0, [R5]					; Read a character to convert to Morse Code
	ADD       	R5, #1             				; point to next value for number of delays, jump by 1 byte
	TEQ                   R0, #0              	              			; test if we hit 0 (null at end of the string) 
	BNE		ProcessChar				; if R0 is not 0, means we still have the next character, so we keep processing it

	; won't go to below code block until R0 equals 0, so we need to add extra delay since it is the end of the word
	MOV		R0, #4					; delay 4 extra spaces (7 total) between words
	BL		DELAY					; branch to delay at the end of the word (we have another branch "LED_OFF_AFTER_EACH" to delay the end of each character) with R0 as parameter
	BEQ         	ResetLUT				; if R0 is 0, means we reach the end of the string, then reset to the start of input

ProcessChar	           BL		CHAR2MORSE	           ; convert ASCII to Morse pattern in R1		
			       B 		           NextChar		        ; move to next character 
;*************************************************************************************************************************************************
;*****************  These are alternate methods to read the bits in the Morse code LUT. You can use them or not **********************************
;************************************************************************************************************************************************* 

;	This is a different way to read the bits in the Morse Code LUT than is in the lab manual.
; 	Choose whichever one you like.
; 
;	First - loop until we have a 1 bit to send  (no code provided)
;
;	This is confusing as we're shifting a 32-bit value left, but the data is ONLY in the lowest 16 bits, so test starting at bit 15 for 1 or 0
;	Then loop thru all of the data bits:
;
;		MOV		R6, #0x8000	; Init R6 with the value for the bit, 15th, which we wish to test
;		LSL		R1, R1, #1	; shift R1 left by 1, store in R1
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;		BEQ		; branch somewhere it's zero
;		BNE		; branch somewhere - it's not zero
;
;		....  lots of code
;		B 		somewhere in your code! 	; This is the end of the main program 
;
;	Alternate Method #2
; Shifting the data left - makes you walk thru it to the right.  You may find this confusing!
; Instead of shifting data - shift the masking pattern.  Consider this and you may find that
;   there is a much easier way to detect that all data has been dealt with.
;
;		LSR		R6, #1		; shift the mask 1 bit to the right
;		ANDS		R7, R1, R6	; R7 gets R1 AND R6, Zero bit gets set telling us if the bit is 0 or 1
;
;
;	Alternate Method #3			; what we chose
; All of the above methods do not use the shift operation properly.
; In the shift operation the bit which is being lost, or pushed off of the register,
; "falls" into the C flag - then one can BCC (Branch Carry Clear) or BCS (Branch Carry Set)
; This method works very well when coupled with an instruction which counts the number 
;  of leading zeros (CLZ) and a shift left operation to remove those leading zeros.

;*************************************************************************************************************************************************
;
;
; Subroutines
;
;			convert ASCII character to Morse pattern
;			pass ASCII character in R0, output in R1
;			index into MorseLuT must be by steps of 2 bytes
CHAR2MORSE	                  STMFD  	R13!,{R14}	        ; push Link Register (return address) on stack
	SUBS		R0, #0x42				; substract ASCII of char in R0 by 0x42 to get the position of corresponding morse pattern in the lookup table
										   ; here we use 0x42 instead of 0x41, for some reason, 41 didn't print expected morse code while 42 printed exactly
	MOV 		R6, #2					; assign 2 to R6
	MUL 		R1, R0, R6				; multiply the corresponding position number by two to get address offset to 'A' in bytes and store in R1
	LDR		R2, =MorseLUT				; assign the address of MorseLUT to R2
	LDR		R0, [R2, R1]				; base on the offset in R1, look up the certain morse pattern of char in the MorseLUT, and load it to R0 
	CLZ		R1, R0					; count leading zeros in R0 and store the number in R1
	MOV		R7, #16					; move 16 to R7 as the counter for the 16 bits' morse pattern
	LSL		R2, R0, R1				; left shift binary morse pattern that stores in R0 by the number of leading zeros that stores in R1 and result goes into R2
	SUB		R1, R7, R1				; substract the counter(R7 stores #16) by the number of removed 0 and store in R1
BitLoop			
	LSLS 		R2, #1					; create a loop to left shift the rest morse partten bits and use the condition code to determine LED on or off
	BLCS		LED_ON				; if the flag is carry then branch to turn on the LED
	BLCC		LED_OFF				; if the flag is clear then branch to turn off the LED
	SUB		R1, #1					; substract the counter by 1
	CMP		R1, #0					; compare the counter with 0 to see if the loop need to be ended
	BNE		BitLoop					; if counter is not equal to 0, then keep looping
	BL		LED_OFF_AFTER_EACH			; otherwise, branch to the branch that used to delay 3 spaces after each character
	LDMFD		R13!,{R15}				; restore LR to R15 the Program Counter to return


; Turn the LED on, but deal with the stack in a simpler way
; NOTE: This method of returning from subroutine (BX  LR) does NOT work if subroutines are nested!!
;
LED_ON 	                  STMFD 	R13!,{R3, R4, R14}       ; push R3 and Link Register (return address) on stack
	MOV		R0, #1					; move 1 to R0
	MOV 		R3, #0xFFFF				; move 0xFFFF to R3 and clear R3's upper word
	MOVT 		R3, #0xEFFF				; move 0xEFFF to R3's upper word, so R3 become 0xEFFFFFFF
	LDR		R4, [R9, #0x20]				; load content from R9 by offset: #0x20 to R4
	AND		R3, R4					; logical AND content in R3 and R4, store result in R3, which can turn on the led
	STR 		R3, [R9, #0x20]				; store content from R3 to the address in R9 with offset
	BL		DELAY					; branch to delay with R0 as parameter
	LDMFD		R13!,{R3, R4, R15}			; restore R3 and LR to R15 the Program Counter to return

; Turn the LED off, but deal with the stack in the proper way
; the Link register gets pushed onto the stack so that subroutines can be nested
;
LED_OFF	                    STMFD	R13!,{R3, R4, R14}       ; push R3 and Link Register (return address) on stack
	MOV		R0, #1					; move 1 to R0
	MOV 		R3, #0x10000000			; move 0xF10000000 to R3
	LDR		R4, [R9, #0x20]				; load content from R9 by offset: #0x20 to R4
	ORR		R3, R4					; logical OR content in R3 and R4, store result in R3, which can turn off the led
	STR 		R3, [R9, #0x20]				; store content from R3 to the address in R9 with offset
	BL		DELAY					; branch to delay with R0 as parameter
	LDMFD		R13!,{R3, R4, R15}			; restore R3 and LR to R15 the Program Counter to return

LED_OFF_AFTER_EACH	       STMFD	R13!,{R3, R4, R14}       ; push R3 and Link Register (return address) on stack
	MOV		R0, #3					; move 3 to R0
	MOV 		R3, #0x10000000			; move 0x10000000 to R3
	LDR		R4, [R9, #0x20]				; load content from R9 by offset: #0x20 to R4
	ORR		R3, R4					; logical OR content in R3 and R4, store result in R3, which can turn off the led
	STR 		R3, [R9, #0x20]				; store content from R3 to the address in R9 with offset
	BL		DELAY					; branch to delay, with R0 as parameter 
	LDMFD		R13!,{R3, R4, R15}			; restore R3 and LR to R15 the Program Counter to return

;	Delay 500ms * R0 times
;	Use the delay loop from Lab-1 but loop R0 times around
;   
DELAY                                 STMFD           R13!,{R2,LR}               ; push R2 and LR onto the stack
MultipleDelay              TEQ     	R0, #0        		           ; compare R0 with 0
	BEQ     		exitDelay      				; if R0 is 0, exit delay
	SUBS    		R0, R0, #1     				; decrement R0
	MOV     		R2, #0x2C2B    				; set R2 to 0x2C2B and clear upper 16 bits
	MOVT       	R2, #0x000A   	 			; set upper 16 bits of R2
loopDelay       	          SUBS        R2, R2, #1 		           ; decrement R2
	BEQ     		MultipleDelay  				; if R2 is 0, repeat delay
	B       		loopDelay     	 			; otherwise, continue looping
exitDelay       LDMFD   R13!,{R2,PC}    ; restore R2 and PC(LR) from the stack and return

;
; Data used in the program
; DCB is Define Constant Byte size
; DCW is Define Constant Word (16-bit) size
; EQU is EQUate or assign a value.  This takes no memory but instead of typing the same address in many places one can just use an EQU
;
		ALIGN				; make sure things fall on word addresses

; One way to provide a data to convert to Morse code is to use a string in memory.
; Simply read bytes of the string until the NULL or "0" is hit.  This makes it very easy to loop until done.
;

InputLUT	DCB		"LSCYE", 0	; strings must be stored, and read, as BYTES, we have a 0 here to specify that the word is end

		ALIGN				; make sure things fall on word addresses
MorseLUT
	DCW 	0x17, 0x1D5, 0x75D, 0x75 	; A, B, C, D
	DCW 	0x1, 0x15D, 0x1DD, 0x55 	; E, F, G, H
	DCW 	0x5, 0x1777, 0x1D7, 0x175 	; I, J, K, L
	DCW 	0x77, 0x1D, 0x777, 0x5DD 	; M, N, O, P
	DCW 	0x1DD7, 0x5D, 0x15, 0x7 	; Q, R, S, T
	DCW 	0x57, 0x157, 0x177, 0x757 	; U, V, W, X
	DCW 	0x1D77, 0x775 			; Y, Z

; One can also define an address using the EQUate directive
;
LED_PORT_ADR	EQU	0x2009c000	; Base address of the memory that controls I/O like LEDs

	END 
