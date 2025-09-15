; ECE-222 Lab ... Winter 2013 term 
; Lab 3 sample code 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR	           ; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports
				MOV 		           R3, #0xB0000000		; move initialize value for turning off LEDs on port 1 to R3
				STR 			R3, [R10, #0x20]		; Turn off three LEDs on port 1, by storing the initialize value to correct address
				MOV 		           R3, #0x0000007C		; move initialize value for turning off LEDs on port 2 to R3
				STR 			R3, [R10, #0x40] 		; Turn off five LEDs on port 2, by storing the initialize value to correct address

				BL			simpleCounter			; simple counter subroutine will be called every time we reset the circuit after the LEDs are turned off for the first time

				MOV 		           R3, #0xB0000000		; move initialize value for turning off LEDs on port 1 to R3
				STR 			R3, [R10, #0x20]		; Turn off three LEDs on port 1, by storing the initialize value to correct address
				MOV 		              R3, #0x0000007C		; move initialize value for turning off LEDs on port 2 to R3 
				STR 			R3, [R10, #0x40] 		; Turn off five LEDs on port 2, by storing the initialize value to correct address 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD			; Init the random number generator with a non-zero number			 
loop			; todo: 查是否都满足了，那一堆形容什么gpio active low的读懂
			; todo code done ?: 将randomnum里的数字进行一个延时，好像要进行一定程度的限制数字or add什么offset
; rngLoop			
				BL			RandomNum			; branch link to RandomNum to get the random number stored in R11
				; according to the lab tutorial, we can use ((Rn%9)+2)*10000 to get the scaled number for waiting time
				MOV		           R0, #9				; move 9 to R0
				SDIV			R1, R11, R0			; divide the random number got before in R11 by 9 in R0, and store the result in R1
				MUL			R2, R0, R1			; multiply the quotient in R1 from last step by 9 in R0, so we can get the whole number of a number times 9
				SUB			R11, R11, R2			; get the remainder of random number/9 
				ADD			R11, #2				; by the function above, we add 2 to number in R11
				MOV32		           R0, #10000			; move a 32 bit number, 10000(into 32bit) to R0
				MUL			R11, R0				; multiply number in R11 by 10000 in R0, and stores the result in R11
				MOV		           R0, R11				; move the number in R11 to R0
				BL			DELAY				; branch to the delay subroutine
				; todo code done: 亮的时候同时开始polling，polling的每一个poll都需要检测是否INTO变成了ON， ON了就直接exit polling处理数据进R3
				MOV		           R3, #0x90000000		; move 0x90000000 to R3
				STR 			R3, [R10, #0x20]		; store 0x90000000 in to the address of (address in R10 + 0x20 = 0x2009c020)
				MOV 		           R3, #0				; move 0 to R3
polling			MOV		           R0, #1				; move 1 to R0
				BL			DELAY				; branch link to DELAY
				ADD			R3, #1				; add 1 to R3
				LDR			R0, [R10, #0x54]		; load the number at address (address in R10 + 0x54 = 0x2009c054) FIO2PIN
				TST			R0, #2_10000000000	           ; test the 11th bit from LSB, which corresponding to the pin10 (pin num start at 0), according to the I/O port appendix, it refers to the INT0 button
				BNE			polling				; if R0 does not equal to 0, branch to polling, keep looping
				; todo code done: 对R3数据进行处理，逐个delay，最后也要delay 5s 
				MOV		           R6, R3				; move number in R3 to R6, it makes a temprory variable that can be used later in the loop
displayLoop 		MOV		           R3, R6				; move number in R6 to R3
				BL 			DISPLAY_NUM			; branch link to DISPLAY_NUM	
				MOV 		           R0, #20000			; move 20000 to R0, since we need delay 2s here (20000*0.1ms = 2s)
				BL			DELAY				; branch link to DELAY
				LSR 			R3, #8				; logic shift right the number in R3 by 8 bit (since 8 LEDs)
				BL 			DISPLAY_NUM			; branch link to DISPLAY_NUM	
				MOV 		           R0, #20000			; move 20000 to R0, since we need delay 2s here (20000*0.1ms = 2s)
				BL			DELAY				; branch link to DELAY
				LSR 			R3, #8				; logic shift right the number in R3 by 8 bit (since 8 LEDs)
				BL 			DISPLAY_NUM			; branch link to DISPLAY_NUM	
				MOV 		           R0, #20000			; move 20000 to R0, since we need delay 2s here (20000*0.1ms = 2s)
				BL			DELAY				; branch link to DELAY
				LSR 			R3, #8				; logic shift right the number in R3 by 8 bit (since 8 LEDs)
				BL 			DISPLAY_NUM			; branch link to DISPLAY_NUM	
				MOV 		           R0, #20000			; move 20000 to R0, since we need delay 2s here (20000*0.1ms = 2s)
				BL			DELAY				; branch link to DELAY
				MOV 		           R3, #0xB0000000		; move initialize value for turning off LEDs on port 1 to R3
				STR 			R3, [R10, #0x20]		; Turn off three LEDs on port 1, by storing the initialize value to correct address
				MOV 		           R3, #0x0000007C		; move initialize value for turning off LEDs on port 2 to R3
				STR 			R3, [R10, #0x40] 		; Turn off five LEDs on port 2, by storing the initialize value to correct address
				MOV		           R0, #50000			; move 50000 to R0, since we need delay 5s here (50000*0.1ms = 5s)
				BL			DELAY				; branch link to DELAY

				B 			displayLoop			; branch to displayLoop, keep looping to display the reaction time of user

;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD		R13!,{R1, R2, R4, R14}
; todo code done: Usefull commands:  RBIT (reverse bits), BFC (bit field clear), LSR & LSL to shift bits left and right, ORR & AND and EOR for bitwise operations
				AND 			R2, R3, #0xFF			; 0xff is 11111111 in binary, logic AND R3 with 0xff will only give us the lower 8 bit from LSB and stores in R2

				MOV 		           R1, #0				; move 0 to R1
				AND 			R4, R2, #2_1			; logic AND R2 with binary number 00000001, so we will only have the LSB and other bit will be clear to 0, and stores in R4
				LSL			R4, #6				; logic shift left the number in R4 by 6 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin6, position bit 7
				ORR			R1, R4				; number in R1 is 0, by logic OR it with number in R4, it will not change the number in R4, and store the number in R4 to R1
				AND 			R4, R2, #2_10			; logic AND R2 with binary number 00000010, so we will only have the bit before LSB and other bit will be clear to 0, and stores in R4
				LSL			R4, #4				; logic shift left the number in R4 by 4 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin5, position bit 6
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				AND 			R4, R2, #2_100			; logic AND R2 with binary number 00000100, so we will only have the second bit before LSB and other bit will be clear to 0, and stores in R4
				LSL			R4, #2				; logic shift left the number in R4 by 2 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin4, position bit 5
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				AND 			R4, R2, #2_1000		; logic AND R2 with binary number 00001000, so we will only have the third bit before LSB and other bit will be clear to 0, and stores in R4
				; don't need to shift here, the bit wanted (did not cleared in last step) is at the corresponding port2 pin3, position bit 4
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				AND 			R4, R2, #2_10000		; logic AND R2 with binary number 00010000, so we will only have forth bit before the LSB and other bit will be clear to 0, and stores in R4
				LSR			R4, #2				; logic shift right the number in R4 by 2 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port2 pin2, position bit 3
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				MOV		           R0, #0x0000007C		; move 0x0000007c to R0, 0x0000007c = 01111100 in binary,  the position is bit 7~3 is "1", which fits the corresponding pin6~2
				EOR			R1, R0, R1 			; logic XOR 0x0000007c in R0 with the combined number in R1, so that we can toggle bits of the number and stores the toggled number in R1, since it is active low by default
				STR			R1, [R10, #0x40]		; store number in R1 into address (address in R10 + 0x40) to control the on/off of the 5 LEDs in port2

				MOV 		           R1, #0				; move 0 to R1
				AND 			R4, R2, #2_100000		; logic AND R2 with binary number 00100000, so we will only have the LSB and other bit will be set to 0
				LSL			R4, #26				; logic shift left the number in R4 by 26 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin31, position bit 32
				ORR			R1, R4				; number in R1 is 0, by logic OR it with number in R4, it will not change the number in R4, and store the number in R4 to R1
				AND 			R4, R2, #2_1000000		; logic AND R2 with binary number 01000000, so we will only have the LSB and other bit will be set to 0
				LSL			R4, #23				; logic shift left the number in R4 by 23 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin29, position bit 30
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				AND 			R4, R2, #2_10000000	               ; logic AND R2 with binary number 10000000, so we will only have the LSB and other bit will be set to 0
				LSL			R4, #21				; logic shift left the number in R4 by 21 bit, so the bit wanted (did not cleared in last step) is moved to the corresponding port1 pin28, position bit 29
				ORR			R1, R4				; number in R1 is from above, by logic OR it with number in R4, it will combine "1"s in the number in R4 and R1, and store the number in R4 to R1
				MOV		           R0, #0xB0000000		; move 0xb0000000 to R0
				EOR			R1, R0, R1 			; logic XOR 0xb0000000 in R0 with the combined number in R1, so that we can toggle bits of the number and stores the toggled number in R1, since it is active low by default
				STR			R1, [R10, #0x20]		; store number in R1 into address (address in R10 + 0x20) to control the on/off of the 3 LEDs in port1

				LDMFD		R13!,{R1, R2, R4, R15}

;
; R11 holds a 16-bit random number via a pseudo-random sequence as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 holds a non-zero 16-bit number.  If a zero is fed in the pseudo-random sequence will stay stuck at 0
; Take as many bits of R11 as you need.  If you take the lowest 4 bits then you get a number between 1 and 15.
; If you take bits 5..1 you'll get a number between 0 and 15 (assuming you right shift by 1 bit).
;
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program OR ELSE!
; R11 can be read anywhere in the code but must only be written to by this subroutine
RandomNum		STMFD		R13!,{R1, R2, R3, R14}

				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			  ; the new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				
				LDMFD		R13!,{R1, R2, R3, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
;               The formula to determine the number of loop cycles is equal to Clock speed x Delay time / (#clock cycles)
;               where clock speed = 4MHz and if you use the BNE or other conditional branch command, the #clock cycles =
;               2 if you take the branch, and 1 if you don't.

DELAY			STMFD		R13!,{R2, R14}
		; todo code done v: code to generate a delay of 0.1mS * R0 times
delayTest		MOV		           R2, #133			; set the number of loops is 133, move it to R2, by 4MHz*(0.1ms/2+1) = 133.33 ≈ 133
				CMP			R0, #0				; compare R0 with 0
				BEQ			exitDelay			; if R0 equals 0, then exitDelay
delayLoop		SUBS		           R2, #1				; substract number of loop (133 in R2) by 1 and set flag
				BNE			delayLoop			; if R2 does not equal to 0, branch to delayLoop and keep looping (loop for 0.1ms)
				SUBS		           R0, #1				; substract scaled random number in R0 by 1 and set flag
				BNE			delayTest			; if R0 does not equal to 0, branch to delayTest and keep looping (loop for R0 times 0.1ms)

exitDelay			LDMFD		R13!,{R2, R15}

; simpleCounter subroutine				
simpleCounter		PUSH		{R3, R14}

				MOV		           R3, #0x00			; move 0x00 to R3, increment start at 0x00
counterLoop		BL			DISPLAY_NUM			; branch link to DISPLAY NUM subroutine
				MOV		           R0, #1000			; move 1000 to R0, since we need a 100ms(= 1000*0.1ms) delay for each number increment
				BL			DELAY				; branch link to DELAY
				ADD			R3, #1				; add 1 to number in R3 
				CMP			R3, #0xff			; compare R3 with 0xff (255)
				BLT 			counterLoop			; branch to counterLoop when R3 less than 0xff(255), keep looping

				POP			{R3, R15}


LED_BASE_ADR	EQU 	           0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 

; Report questions
; 1. 8 bit: 0xFF = 255, => 225*0.1ms = 22.5ms; 
;     16 bit: 0xFFFF = 65535, => 65535*0.1ms = 6.5535s; 
;     24 bit: 0xFFFFFF = 16777215, => 16777215*0.1ms = 1677.7215s;
;     32 bit: 0xFFFFFFFF = 4294967295, => 4294967295*0.1ms = 429496.7295s;
;
; 2. 16 bit because it can be 65535*0.1ms = 6.5535s which contains the normal reaction time range of human, 125~375ms from Human Benchmark - Reaction Time Test
;
; 3. function ((Rn%9)+2)*10000 from lab tutorial, from Rn%9, the range we can get is 0~8, and by +2, the range become 2~10
;      since the base time delay is 0.1ms, so at the end we need to times 10000 to transform to unit in [s]
