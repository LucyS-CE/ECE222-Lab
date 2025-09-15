;*----------------------------------------------------------------------------
;* Name: Lab_1_program.s 
;* Purpose: This code flashes one LED at approximately 1 Hz frequency 
;* Author: Rasoul Keshavarzi 
;*----------------------------------------------------------------------------*/
	THUMB		; Declare THUMB instruction set 
	AREA		My_code, CODE, READONLY 	; 
	EXPORT		__MAIN 		; Label __MAIN is used externally q
	ENTRY 
__MAIN
; The following operations can be done in simpler methods. They are done in this 
; way to practice different memory addressing methods. 
; MOV moves into the lower word (16 bits) and clears the upper word
; MOVT moves into the upper word
; show several ways to create an address using a fixed offset and register as offset
;   and several examples are used below
; NOTE MOV can move ANY 16-bit, and only SOME >16-bit, constants into a register
; BNE and BEQ can be used to branch on the last operation being Not Equal or EQual to zero
;
	MOV 		R2, #0xC000		; move 0xC000 into R2
	MOV 		R4, #0x0		; initialize R4 register to 0 to build address
	MOVT 		R4, #0x2009		; assign 0x20090000 into R4
	ADD 		R4, R4, R2 		; add 0xC000(lower part) in R2 to R4 to get 0x2009C000 

	MOV 		R3, #0x0000007C	; move initial value for port P2 into R3 
	STR 		R3, [R4, #0x40] 	              ; Turn off five LEDs on port 2 
	; Writing 0x0000007C into memory address 0x2009C040 turns “off” the five LEDs on port 2

	MOV 		R3, #0xB0000000	; move initial value for port P1 into R3
	STR 		R3, [R4, #0x20]	               ; Turn off three LEDs on Port 1 using an offset
	; Writing 0xB0000000 into memory address 0x2009C020 turns “off” the three LEDs on port 1

; Toggling bit 28 of the address 0x2009C020 will cause the corresponding LED (P1.28) to alternate between “on” and “off”. 
; The memory address is 32 bits wide (bit 31 down to bit 0). 
; You should switch between 0xB0000000 and 0xA0000000 to flash the LED on pin P1.28.

	MOV 		R2, #0x20		; put Port 1 offset into R2 for user later

	MOV 		R0, #0x2C2B		; move 0x2C2B into R0
	MOVT 		R0, #0x000A		; move 0x000A as higher part into R0
	; because # of loops * 3/4MHz(1/4 for SUBS & 2/4 for BNE) = 0.5s 
	; by calculation, we got the # of loops is (2/3)*10^6 ≈ 666667 = 0xA2C2B
	; seperate into two part, then we got 0x000A(higher) and 0x2C2B(lower)

loop
	SUBS 		R0, #1 			; Decrement r0 and set the N,Z,C status bits
;
; 	Approximately five lines of code
; 	are required to complete the program 
;
	BNE		loop			; exit loop when number of loop is equal to 0
	MOV 		R0, #0x2C2B
	MOVT 		R0, #0x000A		; re-assign the number of loop to R0
	
	MOV 		R3, #0x10000000	; move 0x10000000 to R3
	LDR			R5, [R4, R2]		; load content from R4 and R2 to R5, to see if the led is on or not 
	EOR			R3, R5			; use XOR to determine how to toggle the led and store the result to R3
	STR 			R3, [R4, R2] 		; store the content from R4 and R2 to R3
; write R3 port 1, YOU NEED to toggle bit 28 first

	B 			loop		; keep the led flash forever

 	END

	;	Instruction: ADD R4，R4，R2
	;	Hand Assembly: 1110 00 0 0100 0 0100 0100 00000000 0010
