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
.def	cmdr = r17				; Command Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotID =  0b00110011		; Unique BotID = $33 (MSB = 0) 

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
	ldi mpr, $0C
	out DDRD, mpr			; Set Port D as Input
	ldi mpr, $F3
	out PORTD, mpr	
	
	;USART1
	;Enable transmitter and reciever
	ldi mpr, (1<<TXEN1)|(1<<RXEN1)
	sts UCSR1B, mpr

	;Set frame format: 8data, 2 stop bit
	ldi mpr, (1<<USBS1)|(3<<UCSZ10)
	sts UCSR1C,mpr

	;Set baudrate at 2400bps
	ldi mpr, 0b00001001
	sts UBRR1H, mpr
	ldi mpr, 0b01100000
	sts UBRR1L, mpr


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
		; Wait for any transmissions to finish
		lds mpr, UCSR1A	
		sbrs mpr, UDRE1	
		rjmp MAIN				; Loop if transmission not finished
		
		; Check Buttons for input
		in cmdr, PIND			; Load PORT D Inputs
		andi cmdr, $F3			; Mask Out Pins 2 & 3
		cpi cmdr, $00			
		breq MAIN				; If no input jump to beginning
		
		; Send BotID
		ldi mpr, BotID			; Load BotID into register
		sts UDR1, mpr			; Output on Transmitter

IDLoop:	; Wait for transmission to finish
		lds mpr, UCSR1A
		sbrs mpr, UDRE1
		rjmp IDLoop				; Loop Until ID Sent
		
		; Call sendCommand Function
		rcall sendCmd			; Call sendCmd routine

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: sendCmd
; Desc: Determines which button was pressed and sends specified
;		signal based on the button
; 		0th button = Forward
; 		1st button = Backward
; 		4nd button = Turn Left
; 		5rd button = Turn Right
; 		6th button = Halt
; 		
;-----------------------------------------------------------
sendCmd:

checkFwd:	; Check if Forward Button was pressed
		cpi cmdr, (1<<0) 	; Check if First Button Pressed
		brne checkBack		; If not go to next button

		ldi mpr, MovFwd		; Load Move Fowards Command into register
		sts UDR1, mpr		; Output to transmitter
		rjmp end			; jump to end

checkBack:	; Check if Back Button was pressed
		cpi cmdr, (1<<1) 	; Check if Second Button Pressed
		brne checkLeft		; If not go to next button
		
		ldi mpr, MovBck		; Load Move Backward Command into register
		sts UDR1, mpr		; Output to transmitter
		rjmp end			; jump to end

checkLeft:	; Check if Left Button was pressed
		cpi cmdr, (1<<4)	; Check if Third Button Pressed
		brne checkRight		; If not go to next button

		ldi mpr, TurnL		; Load Turn Left Command into register
		sts UDR1, mpr		; Output to transmitter
		rjmp end			; jump to end

checkRight:	; Check if Right Button was pressed
		cpi cmdr, (1<<5)	; Check if Fourth Button Pressed
		brne checkHalt		; If not go to next button

		ldi mpr, TurnR		; Load Turn Right Command into register
		sts UDR1, mpr		; Output to transmitter
		rjmp end			; jump to end

checkHalt:	; Check if Halt Button was pressed
		cpi cmdr, (1<<6)	; Check if Fifth Button Pressed
		brne end			; If not go to end
		
		ldi mpr, Halt		; Load Halt Command into register
		sts UDR1, mpr		; Output to transmitter
		rjmp end			; jump to end

end:
		ret					; Return from Function


;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
