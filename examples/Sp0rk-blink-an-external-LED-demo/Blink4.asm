;  light 4 leds
mov	r0,13			; 13 is 2.5 Hz
mov	[0xf1],r0		; set Clock register.  
;
mov	r0,1
mov	Out,r0
mov	r0,2
mov	Out,r0
mov	r0,4
mov	Out,r0
mov	r0,8
mov	Out,r0
;
mov	r0,8
mov	Out,r0
mov	r0,4
mov	Out,r0
mov	r0,2
mov	Out,r0
mov	r0,1
mov	Out,r0
;
jr	-17			; loop back 
;
;
;  Exercises for the reader: 
;  Figure out iteration, branching etc.
;  Input works the same way but on register In
;  Wire up more than 4 LEDs and blink them
;  Control your toaster

