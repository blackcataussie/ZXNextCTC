	; Allow the Next paging and instructions
	DEVICE 	ZXSPECTRUMNEXT
	SLDOPT 	COMMENT WPMEM, LOGPOINT, ASSERTION
	org     	$8000

CTCTest	NEXTREG 	7,$00000000		; 3.5 mhz
	call	ClrDisp
	call 	InitInterrupts

.Wait	halt
	ld	de,(CTC2Count)
	ld	hl,CTCTextValue
	call	Convert16BitToDecText
	ld	hl,CTCTextValue
	call	WriteNumericString
	jr	.Wait

CTCTextValue	db	'00000',0

;--------------------------------------------------------------------
; Convert 16bit number to ascii
; DE=16 bit value
; HL=mem location for ascii output
Convert16BitToDecText
	push	bc
	push	af

	ld	bc,10000
	call	.GetAsciiValue
	ld	bc,1000
	call	.GetAsciiValue
	ld	bc,100
	call	.GetAsciiValue
	ld	c,10
	call	.GetAsciiValue
	ld	a,'0'
	add	a,e
	ld	(hl),a

	pop	af
	pop	bc
	ret

.GetAsciiValue	ld	a,'0'-1
	ex	de,hl
	or	a	; Clear carry bit
1	inc	a
	sbc	hl,bc
	jr	nc,1b
	add	hl,bc
	ex	de,hl
	ld	(hl),a
	inc	hl
	ret

;--------------------------------------------------------------------
; Write String to screen
; HL = 0 terminated text string
WriteNumericString
	push	hl
	ld	de,$1000
	pixelad
	pop	de

.NextNum	ld	a,(de)
	or	a
	ret	z		; return if 0 - end string value

	push 	hl
	push	de
	call	WriteChar		; write char to screen
	pop	de
	pop	hl

	inc	hl		; next char mem location
	inc	de
	jr	.NextNum

WriteChar	push	bc
2	push	hl		; save scrren mem loc

	; Calc char data index
	sub	'0'
	ld	d,a
	ld	e,8d
	mul	d,e		
	ld     	hl,AsciiNumeric
	add	hl,de
	ex	de,hl		; de=char

	; Write to screen memory HL
	pop	hl
	ld      	b,8d
3	ld      	a,(de)
	ld      	(hl),a
	pixeldn			; next mem line
	inc     	de
	djnz    	3b

	pop	bc
	ret
AsciiNumeric	DB 0,60,70,74,82,98,60,0	; 0
	DB 0,24,40,8,8,8,62,0	; 1
	DB 0,60,66,2,60,64,126,0	; 2
	DB 0,60,66,12,2,66,60,0	; 3
	DB 0,8,24,40,72,126,8,0	; 4
	DB 0,126,64,124,2,66,60,0	; 5
	DB 0,60,64,124,66,66,60,0	; 6
	DB 0,126,2,4,8,16,16,0	; 7
	DB 0,60,66,60,66,66,60,0	; 8
	DB 0,60,66,66,62,2,60,0	; 9

;--------------------------------------------------------------------
ClrDisp	xor	a
	out	($fe),a
	ld	hl,$4000
	ld	de,$4001
	ld	bc,$17ff
	ld	(hl),a
	ldir

	inc	hl
	inc	de
	ld	bc,$02ff
	ld	(hl),%00000111
	ldir

	ret

;--------------------------------------------------------------------
InitInterrupts	di
	push af
	push bc

	ld 	a,$c0	
	ld 	bc,$243b
	out 	(c),a
	inc	b
	in 	a,(c)
	and	%00001000				; Preserve NMI
	or	(IntVector & %11100000) | %00000001		; set im2 vector and HW IM2 mode
	nextreg 	$c0,a	

	ld	a, IntVector >> 8
	ld	i,a
	im 	2

	xor	a
	ld	(CTC2Count),a
	ld	(CTC2Count+1),a

	nextreg 	$C4,%00000000 
	nextreg 	$C5,%00000100		; CTC enbable interrupts
	nextreg 	$C6,%00000000		; Disable UART0 and UART1 interrupts.

	nextreg 	$c8,%11111111
	nextreg 	$c9,%11111111
	nextreg 	$ca,%11111111

	nextreg	$cc,%10000000		; NMI will interrupt dma
	nextreg	$cd,%00000100		; ctc2 will interrupt dma
	nextreg	$ce,%00000000		; UART no interrupt dma

	; CTC channel 0
	; Timer, prescaler 16, count 175 = 28,000T on zero
	ld	bc,$183B
	ld	a,%00010111
	out	(c),a
	ld	a,175
	out	(c),a

	; CTC channel 1
	; Cascade from CTC 0
	; Counter, count 125 = 350,000T on zero
	ld	bc,$193B
	ld	a,%01011111
	out	(c),a
	ld	a,125
	out	(c),a

	; CTC channel 2
	; Cascade from CTC 1
	; Counter, count 80 = 28,000,000T on zero, Interrupt
	ld	bc,$1A3B
	ld	a,%11011111
	out	(c),a
	ld	a,80
	out	(c),a

	pop	bc
	pop	af
	ei
	ret

;--------------------------------------------------------------------
; interrupt handlers
CTC2Count	defw	0

IntCTC2	nextreg 	$c9,%00000100		; Clear interrupt
	push	hl
	ld	hl,(CTC2Count)
	inc	hl
	ld	(CTC2Count),hl
	pop	hl
IntHandler	ei
	reti

	.ALIGN 32
IntVector	DW IntHandler,IntHandler,IntHandler,IntHandler,IntHandler,IntCTC2,IntHandler,IntHandler
	DW IntHandler,IntHandler,IntHandler,IntHandler,IntHandler,IntHandler,IntHandler,IntHandler
STACK_SIZE 	equ 100      	; in words
stack_bottom	defs    	STACK_SIZE*2, 0
stack_top	equ	$

	SAVENEX OPEN "CTCTest.nex", CTCTest, stack_top
	SAVENEX CORE 3,1,5
	SAVENEX CFG 7,0,0,0
	SAVENEX AUTO
	SAVENEX CLOSE
