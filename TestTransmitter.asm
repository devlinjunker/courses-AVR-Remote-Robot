.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17			; Wait Loop Counter
.def 	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

; Wait Time Constant
.equ	WTime = 30

.equ	BotID = 0b00110011		; Unique XD ID (MSB = 0)

.equ	Signal = 0b10010011		

.equ 	LightsOff = 0x00

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0002					; INT0 Interrupt Vector
		rcall	Transmit		; Function to Transmit when Button Pressed
		reti					; Return from interrupt

.org 	$003C					; USART1 Reciever Interrupt
		rcall 	Recieve
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

	; Initialize Port B - Pin 0 for output
	ldi mpr, $01
	out DDRB, mpr			; Set Port B as Output
	ldi mpr, $00
	out PORTB, mpr			; Default Output set 0
	
	; Initialize Port D for input
	ldi mpr, $00
	out DDRD, mpr			; Set Port D as Input
	ldi mpr, $01
	out PORTD, mpr			; Set Input to Hi-Z
	
	;USART1
	;Enable transmitter, receiver, and Enable receive interrupts
	ldi mpr, (1<<TXEN1)|(1<<RXEN1)|(1<<RXCIE1)
	sts UCSR1B, mpr
	
	;Set frame format: 8data, 2 stop bit
	ldi mpr, (1<<USBS1)|(3<<UCSZ10)
	sts UCSR1C,mpr 

	;Set baudrate at 2400bps
	ldi mpr, $01
	sts UBRR1H, mpr 
	ldi mpr, $A0
	sts UBRR1L, mpr	

	; Initialize external interrupts
	; Set the Interrupt Sense Control to Falling Edge detection
	ldi mpr, $02
	sts EICRA, mpr

	; Set the External Interrupt Mask
	ldi mpr, $01
	out EIMSK, mpr

	sei		; Enable Interrupts


;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:
	rjmp	MAIN
	
;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;-----------------------------------------------------------
; Func: Transmit
; Desc: Transmit signal by placing predetermined signal
; 		in the UDR1 Buffer
;-----------------------------------------------------------

Transmit:	
	ldi mpr, Signal
	sts UDR1, mpr

	ret

;-----------------------------------------------------------
; Func: Recieve
; Desc: Obtains signal from receiever buffer and flashes
; 		light 5 times
;-----------------------------------------------------------

Recieve:	
	
	lds mpr, UDR1
		
	ldi olcnt, 5	
	
BlinkLoop:
	ldi mpr, $01
	out PORTB, mpr
	rcall Wait
	

	ldi mpr, LightsOff
	out PORTB, mpr
	rcall Wait
	
	dec olcnt
	brne BlinkLoop

	ret

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
