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
		sbis UCSR0A, UDRE0
		rjmp MAIN
		
		in mpr, PIND
		andi mpr, $1F
		cpi mpr, $00
		breq MAIN
		
		ldi r17, BotID
		out UDR0, r17

IDLoop:
		sbis UCSR0A, UDRE0
		rcall sendCmd
		rjmp IDLoop

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: sendCmd
; Desc: Obtains first signal from receiever buffer and compares
; 		against the designated BotID. If our BOT, poll reciever
; 		complete flag until command recieved then call RecieveCommand
;-----------------------------------------------------------
sendCmd:

checkFwd:
		cpi mpr, (1<<0)
		brne checkBack

		ldi r17, MovFwd
		out UDR0, r17
		rjmp end
checkBack:
		cpi mpr, (1<<1)
		brne checkLeft
		
		ldi r17, MovBck
		out UDR0, r17
		rjmp end
checkLeft:
		cpi mpr, (1<<2)
		brne checkRight

		ldi r17, TurnL
		out UDR0, r17
		rjmp end
checkRight:
		cpi mpr, (1<<3)
		brne checkHalt

		ldi r17, TurnR
		out UDR0, r17
		rjmp end
checkHalt:
		cpi mpr, (1<<4)
		brne end
		
		ldi r17, Halt
		out UDR0, r17
		rjmp end
end:

		ret


;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************
