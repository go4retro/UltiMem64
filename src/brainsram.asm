 if 0
http://sid.fi/~tnt/tmp/brainsram.zip

$c000
	bit 7 is mmu regs visible
		(1 = on, and if set to 0, it will disappear,
		and I don't have a way to turn it back on yet).
	bit 0 is mmu enabled
$c001
	8 bit mapping set to view in $c01x (0-255)
$c002
	8 bit mapping to use (0-255)


each mapping set is 16 bytes, and each mapping is 1 byte 0-255 that
tells what 4kB page in the first 1MB  to use for that 4kB space in RAM
(slot #0 is $000-$0fff, 1 = 1xxx, 2 = 2xxx, etc.)

 endif


	processor	6502

MMU	= $c000
MMU_VISIBLE	= $80
MMU_ENABLED	= $81

	seg.u	zp
	org	$fb
ptr	ds.w	1
delta	ds.b	1



	seg	code

	org	$0801

;	BASIC stub "SYS2061"
	dc.w	.link
	dc.w	2019
	HEX	9e 32 30 36 31 00
.link	dc.w	0


START

;	we don't want interference from interrupts or VIC-II

	sei
	lda	#0
	sta	$d011
	sta	$d015
	JSR	WaitRast


;	make MMU visible, do NOT activate it yet so we are safe no matter what the mapping is

	lda	#MMU_VISIBLE
	sta	MMU

;	make mapping set #0 visible and use it

	lda	#0
	sta	MMU+1
	sta	MMU+2

;	map the first 64 KB of SRAM to C64 memory

	ldx	#$0f
.init	txa
	sta	MMU+$10,x
	dex
	bpl	.init

;	enable MMU

	lda	#MMU_VISIBLE|MMU_ENABLED
	sta	MMU






;	now test memory banks 1-255 at $1000

TESTMEM

	ldx	#1		; bank number in X

.test1	stx	$d020		; show that we are working
	stx	MMU+$11

	jsr	StartTest
.floop	txa			; fill one page with arithmetic sequence, starting with page number
.fill	sta	(ptr),y
	cmp	(ptr),y		; quick test for stuck-at and transition faults
	bne	.error1
	eor	#$ff
	sta	(ptr),y
	cmp	(ptr),y
	bne	.error1
	eor	#$ff
	sta	(ptr),y
	cmp	(ptr),y
	bne	.error1

	clc
	adc	delta
	iny
	bne	.fill
	jsr	ChangePage
	bcc	.floop

;	see if we read the same values back - limited address decoder fault test

	jsr	StartTest
.cloop	txa
.cmp	cmp	(ptr),y
	bne	.error1
	clc
	adc	delta
	iny
	bne	.cmp
	jsr	ChangePage
	bcc	.cloop

	inx			; repeat until 255 pages done
	bne	.test1


;	now read all banks again to test for crosstalk between banks

	ldx	#1

.test2	stx	$d020
	stx	MMU+$11
	;stx	MMU+1

	jsr	StartTest
.xloop	txa			; fill one page with arithmetic sequence, starting with page number
.xcmp	cmp	(ptr),y
	bne	.error2
	clc
	adc	delta
	iny
	bne	.xcmp
	jsr	ChangePage
	bcc	.xloop

	inx			; repeat until 255 pages done
	bne	.test2


;	test complete, show green screen for five seconds

	lda	#5
	sta	$d020
	ldx	#250
.delay	jsr	WaitRast
	dex
	bne	.delay

	jmp	TESTMEM		; repeat ad infinitum




;	memory error inside 4 KB block

.error1	lda	#$e1
	dc.b	$2c
.error2	lda	#$e2

	ldy	#$1b
	sty	$d011

	jsr	.prhex
	lda	#$20
	jsr	$ffd2
	txa
	jsr	.prhex
	lda	#$20
	jsr	$ffd2
	lda	$1000
	jsr	.prhex
	lda	#$0d
	jmp	$ffd2

.prhex	pha
	lsr
	lsr
	lsr
	lsr
	jsr	.prn
	pla
.prn	and	#$0f
	ora	#$30
	cmp	#$3a
	bcc	.num
	adc	#6
.num	jmp	$ffd2


StartTest
	lda	#1
	sta	delta

	lda	#>$1000
	ldy	#<$1000
	sty	ptr
	sta	ptr+1
	rts

ChangePage
	inc	delta		; increment common difference
	inc	ptr+1
	lda	ptr+1
	cmp	#>$2000
	rts

WaitRast
	bit	$d011
	bpl	*-3
	bit	$d011
	bmi	*-3
	rts
