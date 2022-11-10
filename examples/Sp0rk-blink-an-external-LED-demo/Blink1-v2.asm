; Blink 1 led, on pin Out 0, by toggling 
mov	r0,13			; 13 is 2.5 Hz
mov	[0xf1],r0		; set Clock register
;
btg	r3,0			; toggle GPIO pin 0.  
				; Uses undocumented property of BTG with r3
				; r3 is treated specially by assembler in the BTG instruction as if it were Out.
				; change the 0 to 1,2, or 3 to toggle those pins instead.
jr	-2			; loop back to btg.
