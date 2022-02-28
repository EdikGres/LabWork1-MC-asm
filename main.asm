/*
 * main.asm
 *
 *  Created: 27.02.2022 11:37:47
 *   Author: atlon
 */ 
.include "m328Pdef.inc"

.def tmp = R16
.def tmp2 = R17
.def counter = R18
.def strptrLow = R19
.def strptrHigh = R20

.equ dot_delay = 1
.equ dash_delay = 3
.equ pause_between_elements_sign = 1
.equ pause_between_signs = 3
.equ pause_between_words = 4 ; because 3+4=7, after pause_between_signs we call pause_between_words

.CSEG
;interrupt vectors
		.ORG	0x0000 ;(reset)
		JMP		Reset
		.ORG	0x000C
		JMP		Watchdog ;(watchdog timer)

		.ORG	INT_VECTORS_SIZE 
;end vectors

; Interrupts ==============================================
Watchdog:
		CLI
		INC		counter
		SEI
		RETI
; End Interrupts ==========================================
; Reset	===================================================
Reset:		
; Flush RAM and Registers
RAM_Flush:	LDI		ZL, Low(SRAM_START)	
			LDI		ZH, High(SRAM_START)
			CLR		R16					
Flush:		ST 		Z+, R16				
			CPI		ZH, High(RAMEND)		
			BRNE	Flush				
			CPI		ZL, Low(RAMEND)		
			BRNE	Flush

			CLR		ZL					
			CLR		ZH
			CLR		R0
			CLR		R1
			CLR		R2
			CLR		R3
			CLR		R4
			CLR		R5
			CLR		R6
			CLR		R7
			CLR		R8
			CLR		R9
			CLR		R10
			CLR		R11
			CLR		R12
			CLR		R13
			CLR		R14
			CLR		R15
			CLR		R16
			CLR		R17
			CLR		R18
			CLR		R19
			CLR		R20
			CLR		R21
			CLR		R22
			CLR		R23
			CLR		R24
			CLR		R25
			CLR		R26
			CLR		R27
			CLR		R28
			CLR		R29
; End flushes
		LDI		R16, Low(RAMEND)	;init stack
		OUT 	SPL, R16			
		LDI 	R16, High(RAMEND)
		OUT 	SPH, R16

		LDI		tmp, DDRD ;init ports
		ORI		tmp, 0b00001100
		OUT		DDRD, tmp

		LDI		strptrLow, low(2*String)	;init str pointer
		LDI		strptrHigh, High(2*String)	
		STS		StrPtr, strptrLow
		STS		StrPtr+1, strptrHigh

		RCALL	WDT_init ;start WDT

		SEI	

		CALL Handler ;start parsing string
; End Reset	====================================================
; Main =========================================================
Main:

		JMP		Main
; End Main =====================================================
; Functions ====================================================
WDT_init:
		CLI
		WDR	
		; Start timed sequence
		LDS		R16, WDTCSR
		ORI		R16, (1<<WDCE) | (1<<WDE) ; change prescaler mode enable
		STS		WDTCSR, R16
		LDI		R16,  (1<<WDP2) | (0<<WDP1) | (0<<WDP0) | (1<<WDIE) ; 0.25s + interrupt
		STS		WDTCSR, R16
		SEI
		RET
;string handler
Handler:
		LDS		ZL, StrPtr
		LDS		ZH, StrPtr+1
Handler_go:
		LPM		R16, Z+
		CPI		R16, 0
		BREQ	VixHandler

		SUBI	R16, 0x61 ;A-0x61=0x00
		;space
		CPI		R16, 0xBF
		BREQ	Space
		;pointer to funtion
		LSL		R16
		;safe strptr
		PUSH	ZL
		PUSH	ZH

		LDI		ZL, low(Table*2)
		LDI		ZH, High(Table*2)

		CLR		R17
		ADD		ZL, R16
		ADC		ZH, R17

		LPM		R16, Z+
		LPM		R17, Z

		MOVW	ZH:ZL, R17:R16

		ICALL

		POP		ZH
		POP		ZL
Space:
		CALL	Delay_between_words	

		RJMP	Handler_go
VixHandler:
		RET
;Delay between signs in word
Delay_between_signs:
		LDI		counter, 0
		RCALL	Off_LED
Delay_signs:
		CPI		counter, pause_between_signs
		BREQ	Vix_delay_signs
		RJMP	Delay_signs
Vix_delay_signs:
		LDI		counter, 0
		RCALL	Off_LED
		RET
;Delay between words
Delay_between_words:
		LDI		counter, 0
		RCALL	Off_LED
Delay_words:
		CPI		counter, pause_between_words
		BREQ	Vix_delay_words
		RJMP	Delay_words
Vix_delay_words:
		LDI		counter, 0
		RCALL	Off_LED
		RET
;Delay between elements in one sign
Delay_between_elements:
		LDI		counter, 0
		RCALL	Off_LED
Delay_elements:
		CPI		counter, pause_between_elements_sign
		BREQ	Vix_delay_elements
		RJMP	Delay_elements
Vix_delay_elements:
		LDI		counter, 0
		RCALL	Off_LED
		RET
;Dot
Dot:
		RCALL	On_LED
		CPI		counter, dot_delay
		BREQ	Vix_dot
		RJMP	Dot
Vix_dot:
		RCALL	Off_LED
		LDI		counter, 0
		RET

;Dash
Dash:
		RCALL	On_LED
		CPI		counter, dash_delay
		BREQ	Vix_dash
		RJMP	Dash
Vix_dash:
		RCALL	Off_LED
		LDI		counter, 0
		RET

;LED controls
On_LED:
		IN		tmp, PORTD 
		ORI		tmp, 0b00001100
		OUT		PORTD, tmp
		RET
Off_LED:
		IN		tmp, PORTD 
		LDI		tmp2, 0b00000000
		AND		tmp, tmp2
		OUT		PORTD, tmp
		RET

; End Functions ================================================
;Letters jump
Table:	.dw		ok_a, ok_b, ok_c, ok_d, ok_e, ok_f, ok_g, ok_h, ok_i, ok_j, ok_k, ok_l, ok_m, ok_n, ok_o, ok_p, ok_q, ok_r, ok_s, ok_t, ok_u, ok_v, ok_w, ok_x, ok_y, ok_z
String:	.db		"churikov eduard sergeevich ",0
;Letters
.include "includes/letters.inc"

; DSEG =====================================================
.DSEG
StrPtr:		.byte	2