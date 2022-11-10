;  Now alternate two LEDs, by toggling bits.
;
; Uses undocumented property of BTG with r3
; r3 is treated specially by assembler in the BTG instruction as if it were Out.
;
;  
mov	r0,13			; 13 is 2.5 Hz
mov	[0xf1],r0		; set Clock register
btg	r3,0			; toggle GPIO Out 0.   Note r3 is special.   
btg	r3,1			; toggle GPIO Out 1.   Note r3 is special.
jr	-3			; loop back to btg.

