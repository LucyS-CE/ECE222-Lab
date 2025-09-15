;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	A sample style for lab-4
;* Term:		Winter 2013
;*-------------------------------------------------------------------
				THUMB 								; Declare THUMB instruction set 
				AREA 		My_code, CODE, READONLY
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
                EXPORT      EINT3_IRQHandler
				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		           ; R10 is a pointer to the base address for the LEDs
				MOV 		           R3, #0xB0000000			; Move initialize value for turning off LEDs on port 1 to R3
				STR 		           R3, [R10, #0x20]		           ; Turn off three LEDs on port 1, by storing the initialize value to correct address
				MOV 		           R3, #0x0000007C			; Move initialize value for turning off LEDs on port 2 to R3
				STR 		           R3, [R10, #0x40] 		           ; Turn off five LEDs on port 2, by storing the initialize value to correct address

				LDR			R0, =ISER0				; R0 stores the address of Interrupt Set-Enable Register 0
				MOV			R1, #1<<21				; Inserts 1 at bit 21 while other bits are all zero
				LDR			R2, [R0]				           ; Loads current Interrupt Set-Enable State into R2
				ORR			R2, R1					; Sets 1 at bit 21 of Interrupt Set-Enable State
				STR			R2, [R0]				           ; Stores updated state into Interrupt Set-Enable Register 0, to enable EINT3 channel (External INTerrupt 3)

				LDR			R0, =IO2IntEnf			           ; R0 stores the address of GPIO Interrupt Enable for port 2 Falling Edge Register
				MOV			R1, #1<<10				; Inserts 1 at bit 10 while other bits are all zero 
				LDR			R2, [R0]				           ; Loads current GPIO Interrupt Enable for port 2 Falling Edge Register State into R2
				ORR			R2, R1					; Sets 1 at bit 10 of GPIO Interrupt Enable for port 2 Falling Edge Register State
				STR			R2, [R0]				           ; Stores updated state into GPIO Interrupt Enable for port 2 Falling Edge Register, to enable GPIO interrupt on pin P2.10 for falling edge with IO2IntEnF
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD			           ; Init the random number generator with a non-zero number
LOOP 			BL 			RNG					; Random Generator Subroutine will be called at 10Hz to generate a new random number and stores in R11
		                  MOV		       R3, #0xB0000000			     ; Move initialize value for toggling LEDs on port 1 to R3
				LDR			R0, [R10, #0x20]		           ; Get current LEDs state on port 1 status
				EOR			R0, R3					; Toggle the specified bits
				STR 		           R0, [R10, #0x20] 		           ; Store updated LEDs state on port 1 back to LEDs on port 1 address

				MOV			R3, #0x0000007C			; Move initialize value for toggling LEDs on port 2 to R3
				LDR			R0, [R10, #0x40]		           ; Get current LEDs state on port 2 status
				EOR			R0, R3					; Toggle the specified bits
				STR 		           R0, [R10, #0x40] 		           ; Store updated LEDs state on port 1 back to LEDs on port 1 address

				MOV			R0, #1					; Move 1 to R0, which will be passed to delay subroutine as a parameter 
				BL			DELAY					; Delay for 0.1s
				
				B 			LOOP					; Continiously go through loop until receiving an interrupt from INT0
				
				
				
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator
 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			             ; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 100ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		           R13!,{R2, R14}

delayTest		MOV32		           R2, #133000			; we move 133000 to R2 here since we use number of loops 133 calculated in Lab 3 (which is 0.1ms), and times 1000 so that the time base is 0.1s
				CMP			R0, #0				; compare R0 with 0
				BEQ			exitDelay			; if R0 equals 0, then exitDelay
delayLoop		SUBS		           R2, #1				; substract number of loop (133000 in R2) by 1 and set flag
				BNE			delayLoop			; if R2 does not equal to 0, branch to delayLoop and keep looping
				SUBS		           R0, #1				; substract scaled random number in R0 by 1 and set flag
				BNE			delayTest			; if R0 does not equal to 0, branch to delayTest and keep looping

exitDelay		LDMFD		R13!,{R2, R15}

; The Interrupt Service Routine MUST be in the startup file for simulation 
;   to work correctly.  Add it where there is the label "EINT3_IRQHandler
;
;*------------------------------------------------------------------- 
; Interrupt Service Routine (ISR) for EINT3_IRQHandler 
;*------------------------------------------------------------------- 
; This ISR handles the interrupt triggered when the INT0 push-button is pressed 
; with the assumption that the interrupt activation is done in the main program
EINT3_IRQHandler 	
				PUSH 		{R4-R11, LR} 	
					  
				MOV			R6, R11				; move the random number generated in R11 to R6
				MOV			R0, #201			; move 201 to R0 since we use the function (Rn % (200+1)) + 50 to get the scaled number between range 50~250
				UDIV		           R1, R6, R0			; divide (unsigned) R6 as Rn by 201 in R0 and store the result in R1
				MUL			R2, R0, R1			; multiply the quotient in R1 with 201 in R0 and store the result in R2
				SUB			R6, R6, R2			; substract R6 with R2 to get the remainder and store in R6
				ADD			R6, #50				; add the remainder in R6 with 50
displayLoop		
				MOV			R3, R6				; move the scaled numner in R6 to R3
				BL			DISPLAY_NUM			; branch link to DISPLAY_NUM
				MOV			R0, #10				; move 10 to R0
				BL			DELAY				; branch link to DELAY
				CMP			R6, #10				; compare R6 with 10
				BLS			exitDisplayLoop		           ; if R6 is lower or same as 10, branch to exitDisplayLoop
				SUB			R6, #10				; substract R6 with 10
				B			displayLoop 		           ; branch to displayLoop, keep looping
exitDisplayLoop 			
				MOV			R3, #0				; move 0 to R3
				BL			DISPLAY_NUM			; branch link to DISPLAY_NUM to display num in R3
				MOV			R0, #10				; move 10 to R0
				BL			DELAY				; branch link to DELAY, delay for 1s
				LDR			R0, =IO2IntClr		           ; load address in IO2IntClr to R0
				MOV			R1, #1<<10			; move 0b1000000000 to R1 since the bit control interrupt clear for port2.10 is 10
				LDR			R2, [R0]			           ; load the current number in R0(at lable IO2IntClr) to R2
				ORR			R2, R1				; logic OR the number in R1(0b1000000000) and R2, stores the result into R2
				STR			R2, [R0]			           ; store the changed number to address at R0, so that we can set the bit 1 at corresponding bit

				POP 		{R4-R11, PC} 		

;
; Display the number in R3 onto the 8 LEDs
; we use the method of toggling FIO2DIR (which is active low, 0->'1', 1->'0')
DISPLAY_NUM		STMFD		R13!,{R1, R2, R4, R14}
; Usefull commands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations
				AND 		R2, R3, #0xFF		; 0xff is 11111111 in binary, logic AND R3 with 0xff will only give us the lower 8 bit from LSB and stores in R2

				MOV 		           R1, #0				; move 0 to R1, which will be finally stored into I/O to control the on/off the 5 LEDs in port2
				AND 		           R4, R2, #2_1		           ; logic AND R2 with binary number 00000001, so we will only have the LSB and other bit will be clear to 0, and stores in R4
				LSL			R4, #6				; logic shift left the number in R4 by 6 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin6, position bit 7
				ORR			R1, R4				; number in R1 is 0, by logic OR it with number in R4, it will not change the number in R4, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_10		           ; logic AND R2 with binary number 00000010, so we will only have the 2nd bit and other bit will be clear to 0, and stores in R4
				LSL			R4, #4				; logic shift left the number in R4 by 4 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin5, position bit 6
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_100		           ; logic AND R2 with binary number 00000100, so we will only have the 3rd bit and other bit will be clear to 0, and stores in R4
				LSL			R4, #2				; logic shift left the number in R4 by 2 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin4, position bit 5
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_1000		; logic AND R2 with binary number 00001000, so we will only have the 4th bit and other bit will be clear to 0, and stores in R4
				; don't need to shift here, the bit wanted (did not cleared in last step) is at the corresponding port2 pin3, position bit 4
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_10000	           ; logic AND R2 with binary number 00010000, so we will only have the 5th bit and other bit will be clear to 0, and stores in R4
				LSR			R4, #2				; logic shift right the number in R4 by 2 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin2, position bit 3
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				MOV			R0, #0x0000007C		; move 0x0000007c to R0, 0x0000007c = 0...001111100 in binary, the position is bit 7~3 is "1", which fits the corresponding pin6~2
				EOR			R1, R0, R1 			; logic XOR 0x0000007c in R0 with the combined number in R1, so that we can toggle bits of the number and stores the toggled number in R1, since it is active low by default
				STR			R1, [R10, #0x40]	           ; store number in R1 into address (address in R10 + 0x40) to control the on/off of the 5 LEDs in port2

				MOV 		           R1, #0				; move 0 to R1, which will be finally stored into I/O to control the on/off the 3 LEDs in port1
				AND 		               R4, R2, #2_100000	           ; logic AND R2 with binary number 00100000, so we will only have the 6th bit and other bit will be set to 0
				LSL			R4, #26				; logic shift left the number in R4 by 26 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin31, position bit 32
				ORR			R1, R4				; number in R1 is 0, by logic OR it with number in R4, it will not change the number in R4, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_1000000	           ; logic AND R2 with binary number 01000000, so we will only have the 7th bit and other bit will be set to 0
				LSL			R4, #23				; logic shift left the number in R4 by 23 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin29, position bit 30
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				AND 		           R4, R2, #2_10000000	           ; logic AND R2 with binary number 10000000, so we will only have the MSB and other bit will be set to 0
				LSL			R4, #21				; logic shift left the number in R4 by 21 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin28, position bit 29
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the bit info in R4 to R1
				MOV			R0, #0xB0000000		; move 0xb0000000 to R0, 0xb0000000 = 10110...0 in binary, the position is bit 32 30 29 is "1", which fits the corresponding pin6~2
				EOR			R1, R0, R1 			; logic XOR 0xb0000000 in R0 with the combined number in R1, so that we can toggle bits of the number and stores the toggled number in R1, since it is active low by default
				STR			R1, [R10, #0x20]	           ; store number in R1 into address (address in R10 + 0x20) to control the on/off of the 3 LEDs in port1

				LDMFD		R13!,{R1, R2, R4, R15}

;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	           0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	               0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
IO2IntClr		EQU		0x400280AC		; GPIO Interrupt Clear for port 2 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0 

				ALIGN 

				END 
