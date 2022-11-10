; Blink an led by writing a nibble (4 bits, mapped to the 4 pins) to the Out register 
;
mov	r0,13			; 13 is 2.5 Hz
mov	[0xf1],r0		; set Clock register
;
mov	r0,1			; 0001
mov	Out,r0			; set Out bits
;mov	[0x0a],r0		; you can set Out bits using the address in brackets (see doc) instead of name
mov	r0,0			; 0000
mov	Out,r0			; set Out bits
jr	-4			; loop back 
;
;
; You can turn on and off any combo of the 4 leds on pins Out 0, 1, 2, 3 by writing the corresponding nibble

