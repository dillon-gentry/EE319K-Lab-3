;****************** main.s ***************
; Program written by: Jordon and Dillon
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
		
		LDR R1,=SYSCTL_RCGCGPIO_R	;turn on clock  
		LDRB R0, [R1]				
		ORR R0, #0x30				;Turns on clock for Port E and F
		STRB R0, [R1]				;Stores result into RCGCGPIO addr
		
		NOP
		NOP
		
		LDR R1,= GPIO_PORTE_DIR_R    ;Code that makes PE3 an input
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTE_DEN_R    ;Enables PE2 and PE3
		LDRB R0, [R1]
		ORR R0, #0xC
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_PUR_R    ;Enables Pull Up Resistor
		LDRB R0, [R1]
		ORR R0, #0x10
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_CR_R     ;Enables Control Register
		LDRB R0, [R1]
		ORR R0, #0xFF
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_DIR_R    ;Makes sure PF4 is 0, since its an output
		LDRB R0, [R1]
		AND R0, #0xEF
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_DEN_R    ;Enables PF4 
		LDRB R0, [R1]
		ORR R0, #0x10
		STRB R0, [R1]
		
		LDR R1,= GPIO_PORTF_LOCK_R   ;Lock and Key
		LDR R0,= GPIO_LOCK_KEY
		STR R0, [R1]
		
		
		
		
     CPSIE  I    					;TExaS voltmeter, scope runs on interrupts
	 

		
		AND R2,R2,#0
		ADD R2,R2,#1
		BNE dt30
		
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
        LDR R1,= GPIO_PORTF_DATA_R
		LDRB R0, [R1]
		AND R0, #0x10
		SUBS R0, R0, #0
		BEQ brled
		
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
		BEQ dt50
		
		SUBS R2,R2,#1
		BEQ dt70
		
		SUBS R2,R2,#1
		BEQ dt90
		
		SUBS R2,R2,#1
		BEQ dt10
		
		SUBS R2,R2,#1
		BEQ dt30
		
		AND R2,R2,#0
		
		BNE update
	
		;Duty Cycle for 10 %
dt10	AND R2,R2,#0
		ADD R2,R2,#4
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		
		LDR R1,= 0xA3002 ;0xF6602			;Delay function (50 ms)
d10H	SUBS R1, #1
		BNE d10H
		
		;if code doesn't work put check here to see if 1 or 0 (switch status)
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x5B284F ;0x88960F			;Delay function (450ms)
d10L	SUBS R1, #1
		BNE d10L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 30 %
dt30	AND R2,R2,#0
		ADD R2,R2,#5
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x1E601B ;2E3205			;Delay function (150ms)
d30H	SUBS R1, #1
		BNE d30H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x46E23C  ;6AA362			;Delay function (350ms)
d30L	SUBS R1, #1
		BNE d30L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 50 %
dt50	AND R2,R2,#0
		ADD R2,R2,#1
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x5B2E08 ;6CFE08			;Delay function (250ms)
d50H	SUBS R1, #1
		BNE d50H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x5B2E08  ;6CFE08			;Delay function (250ms)
d50L	SUBS R1, #1
		BNE d50L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 70 %
dt70	AND R2,R2,#0
		ADD R2,R2,#2
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x7FE23C  ;6AA362			;Delay function (350ms)
d70H	SUBS R1, #1
		BNE d70H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0x36601B ;2E3205			;Delay function (150ms)
d70L	SUBS R1, #1
		BNE d70L
		BEQ check
		;////////////////////////////////////////////////////////
		
		;Duty Cycle for 90 %
dt90	AND R2,R2,#0
		ADD R2,R2,#3
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 high
		LDRB R0, [R1]
		ORR R0, #0x8
		STRB R0, [R1]
		
		LDR R1,= 0x5B284F ;0x88960F			;Delay function (450ms)
d90H	SUBS R1, #1
		BNE d90H
		
		LDR R1,= GPIO_PORTE_DATA_R	;Set PE3 low
		LDRB R0, [R1]
		AND R0, #0xF7
		STRB R0, [R1]
		
		LDR R1,= 0xA3002 ;0xF6602			;Delay function (50ms)
d90L	SUBS R1, #1
		BNE d90L
		BEQ check
		;///////////////////////////////////////////////////////

		;Stage 5 Breathing Light Code		
		
brled
		AND R1,#0			;R1 will be downtime
		AND R2,#0			;R2 will be uptime 
		AND R3,#0			;R3 will be space to store stuff
		AND R4,#0			;R4 will be some shit
		
brtwo	LDR R1,= 0xFFF		;downtime= 5000
		ADD R2, #1			;uptime= 1
		
test	ADD R4,R2,#0
		ADD R5,R1,#0
		LDR R3,= GPIO_PORTE_DATA_R		;turn on
		LDRB R0, [R3]
		ORR R0, #0x8
		STRB R0, [R3]
							
up		LDR R3,= GPIO_PORTF_DATA_R		;delay uptime
		LDRB R0, [R3]
		ORR R0, #0xEF
		SUBS R0, #0xEF
		BNE dt30
		SUBS R4, #1
		BNE up
		
		LDR R3,= GPIO_PORTE_DATA_R		;turn off
		LDRB R0, [R3]
		AND R0, #0xF7
		STRB R0, [R3]
		
dwn		LDR R3,= GPIO_PORTF_DATA_R		;delay downtime
		LDRB R0, [R3]
		ORR R0, #0xEF
		SUBS R0, #0xEF
		BNE dt30
		SUBS R5, #1
		BNE dwn				
		
		ADD R2,#1
		SUBS R1,#1
		BNE test

tog		AND R1,#0
		AND R2,#0			 
		AND R3,#0		
		AND R4,#0
		LDR R1,= 0xFFF		;downtime= 5000
		ADD R2, #1			;uptime= 1
		
extest	ADD R4,R2,#0
		ADD R5,R1,#0
		LDR R3,= GPIO_PORTE_DATA_R		;turn on
		LDRB R0, [R3]
		ORR R0, #0x8
		STRB R0, [R3]
							
exup	LDR R3,= GPIO_PORTF_DATA_R		;delay uptime
		LDRB R0, [R3]
		ORR R0, #0xEF
		SUBS R0, #0xEF
		BNE dt30
		SUBS R5, #1
		BNE exup
		
		LDR R3,= GPIO_PORTE_DATA_R		;turn off
		LDRB R0, [R3]
		AND R0, #0xF7
		STRB R0, [R3]
		
exdwn	LDR R3,= GPIO_PORTF_DATA_R		;delay downtime
		LDRB R0, [R3]
		ORR R0, #0xEF
		SUBS R0, #0xEF
		BNE dt30
		SUBS R4, #1
		BNE exdwn				
		
		ADD R2,#1
		SUBS R1,#1
		BNE extest
		BEQ brled
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		


     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
