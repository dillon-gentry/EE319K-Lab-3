;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 1/18/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
		
		LDR R1,= SYSCTL_RCGCGPIO_R	;turn on clock  
		LDRB R0, [R1]				
		ORR R0, #0x30				;Turns on clock for Port E and F
		STRB R0, [R1]				;Stores result into RCGCGPIO addr
		
		NOP
		NOP
		
		LDR R1,= GPIO_PORTE_DIR_R
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTE_DEN_R
		LDRB R0, [R1]
		ORR R0, #0xC
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_PUR_R
		LDRB R0, [R1]
		ORR R0, #0x10
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_CR_R
		LDRB R0, [R1]
		ORR R0, #0xFF
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_DIR_R
		LDRB R0, [R1]
		AND R0, #0xEF
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_DEN_R
		LDRB R0, [R1]
		ORR R0, #0x10
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_LOCK_R
		LDR R0,= GPIO_LOCK_KEY
		STR R0, [R1]
		
		
		
		
     CPSIE  I    					;TExaS voltmeter, scope runs on interrupts
	 
loop  
		
		;Continuously read PE2 bit for 1 or 0 (1 is pressed, 0 is unpressed)
rsw		LDR R1,= GPIO_PORTE_DATA_R
		LDRB R0, [R1]
		LSR R0, #2
		SUBS R0,R12, R0
		BEQ rsw
		
		LDR R1,= GPIO_PORTE_DATA_R ;sets PE2 low
		LDRB R0, [R1]
		AND R0, #0xFB
		STRB R0, [R1]
		
rsw1	LDR R1,= GPIO_PORTE_DATA_R ;checks for contuious press 
		LDRB R0, [R1]
		LSR R0, #2
		SUBS R0,R12, R0
		AND R2, #0
		BEQ update
		BNE rsw1
		
check
		LDR R1,= GPIO_PORTE_DATA_R
		LDRB R0, [R1]
		LSR R0, #2
		SUBS R0,R0,#1
		BEQ update
		BNE noup
		
		
		
update	
		;R2 will be our register to indicate which duty cycle we will go to upon pressing the switch
		; 1=10, 2=30, 3=50, 4=70, 5=90
	
		ADD R2,R2,#1
		
noup    SUBS R2,R2,#1
		BEQ dt10
		
		SUBS R2,R2,#1
		BEQ dt30
		
		SUBS R2,R2,#1
		BEQ dt50
		
		SUBS R2,R2,#1
		BEQ dt70
		
		SUBS R2,R2,#1
		BEQ dt90
		
		AND R2,R2,#0
		BEQ update
	
		;Duty Cycle for 10 %
dt10	AND R2,R2,#0
		ADD R2,R2,#1
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		
		LDR R1,= 0xF4240			;Delay function (150ms)
d10H	SUBS R1, #1
		BNE d10H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x895440			;Delay function (350ms)
d10L	SUBS R1, #1
		BNE d10L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 30 %
dt30	AND R2,R2,#0
		ADD R2,R2,#2
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x2DC6C0			;Delay function (150ms)
d30H	SUBS R1, #1
		BNE d30H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x6ACFC0			;Delay function (350ms)
d30L	SUBS R1, #1
		BNE d30L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 50 %
dt50	AND R2,R2,#0
		ADD R2,R2,#3
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x4C4B40			;Delay function (150ms)
d50H	SUBS R1, #1
		BNE d50H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x4C4B40			;Delay function (350ms)
d50L	SUBS R1, #1
		BNE d50L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 70 %
dt70	AND R2,R2,#0
		ADD R2,R2,#4
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x6ACFC0			;Delay function (150ms)
d70H	SUBS R1, #1
		BNE d70H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x2DC6C0			;Delay function (350ms)
d70L	SUBS R1, #1
		BNE d70L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 90 %
dt90	AND R2,R2,#0
		ADD R2,R2,#5
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x895440			;Delay function (150ms)
d90H	SUBS R1, #1
		BNE d90H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0xF4240			;Delay function (350ms)
d90L	SUBS R1, #1
		BNE d90L
		BEQ check
		;///////////////////////////////////////////////////////
	 B    loop
	 


     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file

