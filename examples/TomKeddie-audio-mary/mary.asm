; Audio output, assumes speaker and amplifier on gpio0
;
; Tuned to fairly accurate tones using Saleae Logic Analyser
;
; @TomKeddie 2022
;
;  c4     261     // 261 Hz MIDDLE C
;  d4     293
;  e4     330
;  g4     392

start:
	mov r0,1
	mov [0xf1],r0
	
        gosub e4		
	gosub pause
        gosub d4
	gosub pause
        gosub c4
	gosub pause
        gosub d4
	gosub pause

        gosub e4
	gosub pause
        gosub e4
	gosub pause
        gosub e4
	gosub pause

        gosub d4
	gosub pause
        gosub d4
	gosub pause
        gosub d4
	gosub pause

        gosub e4
	gosub pause
        gosub g4
	gosub pause
        gosub g4
	gosub pause

        gosub e4
	gosub pause
        gosub d4
	gosub pause
        gosub c4
	gosub pause

        gosub d4
	gosub pause
        gosub e4
	gosub pause
        gosub e4
	gosub pause
        gosub e4
	gosub pause
        gosub e4
	gosub pause

        gosub d4
	gosub pause
        gosub d4
	gosub pause
        gosub e4
	gosub pause
        gosub d4
	gosub pause
        gosub c4
	gosub pause

done:
	jr done

pause:
	mov r6, 7
	mov r7, 15
	mov r8, 15
p_loop:
	; nested loop counters
	dec r8
	skip nz,2
	mov r8,15 ; reload lsb
	dec r7    ; decrement 2sb
	skip nz,2
	mov r7,15
	dec r6
	skip nz,1
	ret r0,0
	jr p_loop



; ~261Hz for C
c4:
	mov r1, 1
	mov r6, 2
	mov r7, 9
	mov r8, 15
c4_loop:
	xor out,r1
	mov r2,15
c4_0:
	dec r2
        skip z,1
	jr c4_0 ; 1042Hz
	mov r2,15
c4_1:
	dec r2
        skip z,1
	jr c4_1 ;  821 Hz
	mov r2,15
c4_2:
	dec r2
        skip z,1
	jr c4_2 ; 350Hz
	mov r2,15
c4_3:
	dec r2
        skip z,1
	jr c4_3 ; 302Hz
	
	; nested loop counters
	dec r8
	skip nz,2
	mov r8,15 ; reload lsb
	dec r7    ; decrement 2sb
	skip nz,2
	mov r7,9 ; decrement 3sb
	dec r6
	skip nz,2
	mov out,0
	ret r0,0
	jr c4_loop

; ~293Hz for D
d4:
	mov r1, 1
	mov r6, 2
	mov r7, 10
	mov r8, 15
d4_loop:
	xor out,r1
	mov r2,15
d4_0:
	dec r2
        skip z,1
	jr d4_0 ; 1042Hz
	mov r2,15
d4_1:
	dec r2
        skip z,1
	jr d4_1 ;  821 Hz
	mov r2,15
d4_2:
	dec r2
        skip z,1
	jr d4_2 ; 350Hz
	mov r2,8
d4_3:
	dec r2
        skip z,1
	jr d4_3 ; 302Hz
	
	; nested loop counters
	dec r8
	skip nz,2
	mov r8,15 ; reload lsb
	dec r7    ; decrement 2sb
	skip nz,2
	mov r7,10 ; decrement 3sb
	dec r6
	skip nz,2
	mov out,0
	ret r0,0
	jr d4_loop

; ~330Hz for E
e4:
	mov r1, 1
	mov r6, 2
	mov r7, 11
	mov r8, 15
e4_loop:
	xor out,r1
	mov r2,15
e4_0:
	dec r2
        skip z,1
	jr e4_0 ; 1042Hz
	mov r2,15
e4_1:
	dec r2
        skip z,1
	jr e4_1 ;  821 Hz
	mov r2,15
e4_2:
	dec r2
        skip z,1
	jr e4_2 ; 350Hz
	mov r2,3
e4_3:
	dec r2
        skip z,1
	jr e4_3 ; 302Hz
	
	; nested loop counters
	dec r8
	skip nz,2
	mov r8,15 ; reload lsb
	dec r7    ; decrement 2sb
	skip nz,2
	mov r7,11 ; decrement 3sb
	dec r6
	skip nz,2
	mov out,0
	ret r0,0
	jr e4_loop

; ~394Hz for G
g4:
	mov r1, 1
	mov r6, 2
	mov r7, 13
	mov r8, 15
g4_loop:
	xor out,r1
	mov r2,15
g4_0:
	dec r2
        skip z,1
	jr g4_0 ; 1042Hz
	mov r2,15
g4_1:
	dec r2
        skip z,1
	jr g4_1 ;  821 Hz
	mov r2,7
g4_2:
	dec r2
        skip z,1
	jr g4_2 ; 350Hz
	mov r2,3
g4_3:
	dec r2
        skip z,1
	jr g4_3 ; 302Hz
	
	; nested loop counters
	dec r8
	skip nz,2
	mov r8,15 ; reload lsb
	dec r7    ; decrement 2sb
	skip nz,2
	mov r7,13 ; decrement 3sb
	dec r6
	skip nz,2
	mov out,0
	ret r0,0
	jr g4_loop
