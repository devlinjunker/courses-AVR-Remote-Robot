;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 6 of ECE 375
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
.def	waitcnt = r17			; Wait Loop Counter
.def 	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

; Wait Time Constant
.equ	WTime = 100

; Constants for interactions
.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotID = 0b00110011		; Unique XD ID (MSB = 0)

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forwards Command
.equ	MovBck =  $00						;0b00000000 Move Backwards Command
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Command
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Command
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0002					; INT4 Interrupt Vector
		rcall	HitRight		; Function to handle Hit Right
		reti					; Return from interrupt

.org 	$0004					; INT5 Interrupt Vector
		rcall 	HitLeft			; Function to handle Hit Lef
		reti					; Return from interrupt

.org 	$0024
		rcall 	RecieveID
		reti

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

	; Initialize Port B for output
	ldi mpr, $FF
	out DDRB, mpr			; Set Port B as Output
	ldi mpr, $00
	out PORTB, mpr			; Default Output set 0

	; Initialize Port D for input
	ldi mpr, $00
	out DDRD, mpr			; Set Port E as Input
	ldi mpr, (1<<WskrL)|(1<<WskrR)
	out PORTD, mpr			; Set Input to Hi-Z
	
	
	;USART1
	;Enable receiver and Enable receive interrupts
	ldi mpr, (1<<TXEN1)|(1<<RXEN1)|(1<<RXCIE1)
	sts UCSR1B, mpr
	;Set frame format: 8data, 2 stop bit
	ldi mpr, (1<<USBS1)|(3<<UCSZ01)
	sts UCSR1C,mpr
	;Set baudrate at 2400bps
	ldi mpr, 0b00001001
	sts UBRR1H, mpr
	ldi mpr, 0b01100000
	sts UBRR1L, mpr

	; Initialize external interrupts
	; Set the Interrupt Sense Control to Falling Edge detection
	ldi mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
	sts EICRA, mpr
	ldi mpr, $00
	out EICRB, mpr

	; Set the External Interrupt Mask
	ldi mpr, (1<<INT0)|(1<<INT1)
	out EIMSK, mpr

	sei


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
	; Send command to Move Robot Forward 
	ldi mpr, MovFwd
	out PORTB, mpr

	rjmp	MAIN	

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: RecieveID
; Desc: Obtains first signal from receiever buffer and compares
; 		against the designated BotID. If our BOT, poll reciever
; 		complete flag until command recieved then call RecieveCmd
;-----------------------------------------------------------
RecieveID:	
		; Save variable by pushing them to the stack
		push mpr
		in mpr, SREG
		push mpr
		
		lds mpr, UDR1 	; Get signal from buffer
		cpi mpr, BotID	; Compare against BotID
		brne RcvSkip	; If not equal, return to main

CmdLoop:
		lds r17, UCSR1A
		cpi r17, (1<<RXC1)
		breq Recieve		; If Equal, poll for Recieve Complete
		rjmp CmdLoop		; If Not Complete: Loop
Recieve:		
		rcall RecieveCmd	; If Complete: Jump to RecieveCmd

RcvSkip: 
		; Restore variable by popping them from the stack in reverse order
		pop mpr
		out SREG, mpr
		pop mpr
		ret		; End a function with RET

;-----------------------------------------------------------
; Func: Hit_Right
; Desc: Handles when Right Whisker is triggered
;		Moves TekBot backwards for 1 second, then 
;		turns left for 1 second, then continues forward
;-----------------------------------------------------------
HitRight:
		; Save variable by pushing them to the stack
		push mpr
		push waitcnt
		in mpr, SREG
		push mpr		

		; Move Backwards for 1 Second
		ldi mpr, MovBck
		out PORTB, mpr
		ldi waitcnt, WTime
		rcall Wait
		
		; Turn Left for 1 Second
		ldi mpr, TurnL
		out PORTB, mpr
		ldi waitcnt, WTime
		rcall Wait
		
		; Restore variable by popping them from the stack in reverse order
		pop mpr
		out SREG, mpr
		pop waitcnt
		pop mpr
		ret		; End a function with RET


;-----------------------------------------------------------
; Func: Hit_Left
; Desc: Handles when Left Whisker is triggered
;		Moves TekBot backwards for 1 second, then 
;		turns right for 1 second, then continues forward
;-----------------------------------------------------------
HitLeft:
		; Save variable by pushing them to the stack
		push mpr
		push waitcnt
		in mpr, SREG
		push mpr		

		; Move Backwards for 1 Second
		ldi mpr, MovBck
		out PORTB, mpr
		ldi waitcnt, WTime
		rcall Wait
		
		; Turn Right for 1 Second
		ldi mpr, TurnR
		out PORTB, mpr
		ldi waitcnt, WTime
		rcall Wait
		
		; Restore variable by popping them from the stack in reverse order
		pop mpr
		out SREG, mpr
		pop waitcnt
		pop mpr
		ret		; End a function with RET

;-----------------------------------------------------------
; Func: Wait
; Desc: Wait loop that will wait for waitcnt*(~10ms).
;		beginning of your functions
;-----------------------------------------------------------
Wait:	
		; Save variable by pushing them to the stack
		push waitcnt
		push ilcnt
		push olcnt
		
		ldi waitcnt, WTime

Loop:	ldi olcnt, 224
OLoop:	ldi ilcnt, 237
ILoop:	dec ilcnt
		brne ILoop
		dec olcnt
		brne OLoop
		dec waitcnt
		brne Loop
		
		; Restore variable by popping them from the stack in reverse order
		pop olcnt
		pop ilcnt
		pop waitcnt
		ret		; End a function with RET

;-----------------------------------------------------------
; Func: RecieveID
; Desc: Obtains first signal from receiever buffer and compares
; 		against the designated BotID. If our BOT, poll reciever
; 		complete flag until command recieved then call RecieveCommand
;-----------------------------------------------------------
RecieveCmd:	
		; Save variable by pushing them to the stack
		push mpr
		in mpr, SREG
		push mpr
		
		lds mpr, UDR1 	; Get command from buffer
		LSL mpr			; Shift out MSB (1 to represent signal)
		cpi mpr, MovFwd
		brne checkBack

checkFwd:		
		ldi mpr, MovFwd
		out PORTB, mpr
		rjmp exit
		 
checkBack:
		cpi mpr, MovBck
		brne checkLeft
		
		ldi mpr, MovBck
		out PORTB, mpr
		rjmp exit		

checkLeft:
		cpi mpr, TurnL
		brne checkRight

		ldi mpr, TurnL
		out PORTB, mpr
		rjmp exit

checkRight:
		cpi mpr, TurnR
		brne checkHalt

		ldi mpr, TurnR
		out PORTB, mpr
		rjmp exit

checkHalt:
		cpi mpr, Halt
		brne exit 

		ldi mpr, Halt
		out PORTB, mpr
		rjmp exit

exit: 
		; Restore variable by popping them from the stack in reverse order
		pop mpr
		out SREG, mpr
		pop mpr
		ret		; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************



;***********************************************************
;*	Additional Program Includes
;***********************************************************

