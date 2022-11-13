; Flash CQ on external LEDs
; very rudimentary
;
start:
	mov r0,11		; Clock speed value
	mov [0xf1],r0		; Clock register
	
	gosub dah               ; gosub - assembler pushes PC (program counter) and jumps.   See assember doc
	gosub dit
	gosub dah
	gosub dit
			
	gosub space
	
	gosub dah
	gosub dah
	gosub dit
	gosub dah
	
	gosub done
		
dit:
	mov r1,1			; 0001
	mov Out,r1			; set Out bits
	mov r1,0			; 0000
	mov Out,r1			; set Out bits
	mov r0,r0			; delay.   Should be able to use nop for this
	ret r0,0			; return (pops PC and puts specified value in R0).  See instruction set doc

dah:
	mov r1,15			; 1111
	mov Out,r1			; set Out bits
	mov r0,r0
	mov r1,0			; 0000
	mov Out,r1			; set Out bits
	mov r0,r0			
	mov r0,r0			
	mov r0,r0
	ret r0,0			; return

space:
	mov r0,r0
	mov r0,r0
	mov r0,r0
	ret r0,0			; return

done:
	jr done

