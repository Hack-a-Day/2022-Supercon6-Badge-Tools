;  Alternate blinking 2 LEDs by writing a nibble to Out
;
mov	r0,13			; 13 is 2.5 Hz
mov	[0xf1],r0		; set Clock register
;
mov	r0,1			; 0001
;mov	[0x0a],r0		; set Out bits
mov	Out,r0			; you can address the Out register by its name 
mov	r0,2			; 0010
;mov	[0x0a],r0		; set Out bits
mov	Out,r0			; 
jr	-5			; loop back
