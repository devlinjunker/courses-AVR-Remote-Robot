;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register


.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotID =  0b00110011		;Unique XD ID (MSB = 0)

; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forwards Command
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backwards Command
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Command
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Command
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Command
.equ	Freez =   ($80|$F8)
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt


.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
	;Stack Pointer 
	ldi mpr, HIGH(RAMEND)
	out SPH, mpr
	ldi mpr, LOW(RAMEND)
	out SPL, mpr
	
	; Initialize Port D for input
	ldi mpr, $00
	out DDRD, mpr			; Set Port D as Input
	ldi mpr, $FF
	out PORTD, mpr	

	;USART0
	;Set baudrate at 2400bps
	ldi mpr, 0b00001001
	sts UBRR0H, mpr
	ldi mpr, 0b01100000
	out UBRR0L, mpr
	;Enable transmitter
	ldi mpr, (1<<TXEN0)
	out UCSR0B, mpr
	;Set frame format: 8data, 2 stop bit
	ldi r16, (1<<USBS0)|(3<<UCSZ00)
	sts UCSR0C,r16
	;Other


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		sbis UCSR0A, UDRE0		; Loop until all Transmissions finished
		rjmp MAIN
		
		in mpr, PIND			; Load PORT D Inputs
		andi mpr, $1F			; Mask Out 5-7 Pins
		cpi mpr, $00			
		breq MAIN				; If no input jump to beginning
		
		ldi r17, BotID			; Load BotID into register
		out UDR0, r17			; Output on Transmitter

IDLoop:
		sbis UCSR0A, UDRE0		; Loop until transmission finished
		rjmp IDLoop
		rcall sendCmd			; Call sendCmd routine

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: sendCmd
; Desc: Determines which button was pressed and sends specified
;		singal based on the button
; 		0th button = Forward
; 		1st button = Backward
; 		2nd button = Turn Left
; 		3rd button = Turn Right
; 		4th button = Halt
; 		
;-----------------------------------------------------------
sendCmd:

checkFwd:
		cpi mpr, (1<<0) 	; Check if First Button Pressed
		brne checkBack		; If not go to next button

		ldi r17, MovFwd		; Load Move Fowards Command into register
		out UDR0, r17		; Output to transmitter
		rjmp end			; jump to end
checkBack:
		cpi mpr, (1<<1) 	; Check if Second Button Pressed
		brne checkLeft		; If not go to next button
		
		ldi r17, MovBck		; Load Move Backward Command into register
		out UDR0, r17		; Output to transmitter
		rjmp end			; jump to end
checkLeft:
		cpi mpr, (1<<2)		; Check if Third Button Pressed
		brne checkRight		; If not go to next button

		ldi r17, TurnL		; Load Turn Left Command into register
		out UDR0, r17		; Output to transmitter
		rjmp end			; jump to end
checkRight:
		cpi mpr, (1<<3)		; Check if Fourth Button Pressed
		brne checkHalt		; If not go to next button

		ldi r17, TurnR		; Load Turn Right Command into register
		out UDR0, r17		; Output to transmitter
		rjmp end			; jump to end
checkHalt:
		cpi mpr, (1<<4)		; Check if Fifth Button Pressed
		brne end			; If not go to end
		
		ldi r17, Halt		; Load Halt Command into register
		out UDR0, r17		; Output to transmitter
		rjmp end			; jump to end
end:

		ret					; Return from Function


;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
