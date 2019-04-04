	org	0x100
	ld	c,9
	ld	de,gfx	;switch to graphics mode
	call	5
	jp	start

Delay ;This will produce a delay roughly proportional to BC * DE
	LD BC, 100h            ;Loads BC with hex 100
Outer
	LD DE, 1000h            ;Loads DE with hex 1000
Inner
	DEC DE                  ;Decrements DE
	LD A, D                 ;Copies D into A
	OR E                    ;Bitwise OR of E with A (now, A = D | E)
	JP NZ, Inner            ;Jumps back to Inner: label if A is not zero
	DEC BC                  ;Decrements BC
	LD A, B                 ;Copies B into A
	OR C                    ;Bitwise OR of C with A (now, A = B | C)
	JP NZ, Outer            ;Jumps back to Outer: label if A is not zero
	RET                     ;Return from call to this subroutine

OutHex8x
; Input: C
	ld  a,c
	rra
	rra
	rra
	rra
	call  Conv
	ld  a,c

Conv
	and  $0F
	add  a,$90
	daa
	adc  a,$40
	daa
	ld	c,a
	call conout
	ret

;Number in a to decimal ASCII
;adapted from 16 bit found in z80 Bits to 8 bit by Galandros
;Example: display a=56 as "056"
;input: a = number
;Output: a=0,value of a in the screen
;destroys af,bc (don't know about hl and de)
DispA
	ld	c,-100
	call	Na1
	ld	c,-10
	call	Na1
	ld	c,-1
Na1	ld	b,'0'-1
Na2	inc	b
	add	a,c
	jr	c,Na2
	sub	c		;works as add 100/10/1
	push af		;safer than ld c,a
	ld	c,b		;char is in b
	CALL	conout	;plot a char. Replace with bcall(_PutC) or similar.
	pop af		;safer than ld a,c
	ret

conout	ld      hl,02h
	ld      d,(hl)
        ld      hl,01h
        ld      e,(hl)
        ld      ix,09h
        add     ix,de
        jp      (ix)
	ret

beep	ld      hl,02h
	ld      d,(hl)
        ld      hl,01h
        ld      e,(hl)
        ld      ix,36h
        add     ix,de
	ld	de,0x0060
	ld 	c,0xFF
        jp      (ix)
	ret

div	;divides d by e and places the quotient in d and the remainder in a 
        xor a          ;0→C  
        ld b,8         ;8→B 
_loop:
        sla	d
        rla
        cp	e
        jr	c, $+4
        sub	e
        inc	d

        djnz	_loop
   
        ret

start	ld      c,1bh
        call    conout
        ld      c,0c7h
        call    conout
        ld      c,01h
        call    conout
        ld      c,1eh
        call    conout
        ld      c,00h
        call    conout
        ld      c,0c8h
        call    conout
	ld	c,9
	ld	de,dot
	call	5
	ld	c,9
	ld	de,line
	call	5
	jp	loop

GetTemp
	LD   A,1CH          ;1CH is the temperature sense command
	OUT  (06H),A        ;Output 1CH to the SIOR
	LD   A,02
	OUT  (01H),A        ;Set RES RDYSIO bit to 1 to reset RDYSIO
  ; at this point the command is being sent to 7508
RDY
	IN   A,(05H)        ;Read RDYSIO bit.  Low=7508 busy
	BIT  3,A            ;test it
	JP   Z,RDY          ;if busy, loop until 7508 op complete
; when here, SIOR contains result of requested command
	IN   A,(06H)        ;Read the raw temperature data
;If A reg = 60H then temperature = 122 degrees F.  
;If A reg = 70H then temperature = 113 degrees F.  
;If A reg = 80H then temperature = 104 degrees F.
;If A reg = 90H then temperature = 97 degrees F.
;If A reg = A0H then temperature = 90 degrees F. 
;If A reg = B0H then temperature = 84 degrees F.
;If A reg = C0H then temperature = 77 degrees F. 
;If A reg = D0H then temperature = 70 degrees F.
;If A reg = E0H then temperature = 64 degrees F.
	
        ;push	af
	;call	DispA
	;ld	c,20h
	;call	conout
	;pop	af

	ld	d,a
	ld	e,16
	call	div	; a/16
	
	ld	a,d
	sub	6 ; reg A now has the index to the temp table
	;ld     c,a
	;push	af
	;call   OutHex8x
	;pop	af
	ld	hl,0
	ld	l,a
	ld	de,temps ;pointer to temp table
	add	hl,de
	ld	a,(hl)
	call	DispA
	;push	af
	;ld	c,a
	;call	OutHex8x
	ret

	;ld	c,01h
	;call	5
	;ld	b,1bh ;check for escape
	;cp	b
	;jp	z,0   ;exit if escape was pressed

loop	
        ld      c,0Ah
        call    conout
        ld      c,0Dh
        call    conout
	call	GetTemp
	call 	beep
	call	Delay
	jp	loop

gfx	defb	1bh,0d0h,3h,24h
dot	defb	0x1b,0xc7,0x1,0x1f,0,0xc9,24h
line	defb	0x1b,0xc6,0,20,0,20,0,40,0,40,0xfe,0xfe,2,24h
crlf	defb	0x0a,0x0b,24h
temps	defb	122,113,104,97,90,84,77,70,64,24h
	end
