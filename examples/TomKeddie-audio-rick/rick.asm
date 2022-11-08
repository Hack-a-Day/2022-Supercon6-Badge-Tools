; Audio output, assumes speaker and amplifier on gpio0
;
; Tuned to fairly accurate tones using Saleae Logic Analyser
;
; @TomKeddie 2022
;
;   a4f,  415Hz
;   a5f,  830Hz
;   b4f,  466Hz
;   c5,   523Hz
;   c5s,  554Hz
;   e5f,  659Hz
;   f5,   698Hz

start:
    mov r0,1
    mov [0xf1],r0
    gosub   b4f
    gosub pause
    gosub   b4f
    gosub pause
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub pause
; 2
    gosub   f5
    gosub   f5
    gosub   f5
    gosub pause
    gosub   f5
    gosub   f5
    gosub   f5
    gosub pause
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub   e5f
; 3
    gosub pause
    gosub   b4f
    gosub pause
    gosub   b4f
    gosub pause
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub pause
; 4
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub pause
    gosub   c5
    gosub pause
    gosub   b4f
    gosub   b4f
    gosub pause
; 5
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
; 6
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub pause
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   c5
    gosub   c5
    gosub   c5
    gosub pause
    gosub   b4f
    gosub pause
; 6a
    gosub   a4f
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub   a4f
    gosub pause
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub pause
; 7
    gosub   b4f
    gosub pause
    gosub   b4f
    gosub pause
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub pause
; 8
    gosub   f5
    gosub pause
    gosub   f5
    gosub pause
    gosub   e5f
    gosub pause
; 8a
    gosub   b4f
    gosub pause
    gosub   b4f
    gosub pause
    gosub   a4f
    gosub pause
    gosub   a4f
    gosub pause
; 8b
    gosub   a5f
    gosub   a5f
    gosub   a5f
    gosub pause
    gosub   c5
    gosub   c5
    gosub   c5
    gosub pause
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub pause
    gosub   c5
    gosub pause
    gosub   b4f
    gosub   b4f
    gosub pause
; 9
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
    gosub   c5s
    gosub pause
; 10
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub pause
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   c5
    gosub   c5
    gosub   c5
    gosub pause
; 10a
    gosub   b4f
    gosub pause
    gosub   a4f
    gosub   a4f
    gosub pause
    gosub pause
    gosub pause
    gosub   a4f
    gosub   a4f
    gosub pause
; 10B
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub   e5f
    gosub pause
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
    gosub   c5s
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
; --------------------------------------------------------------------------
; ~698Hz for f5        
f5:
    mov r1, 1
    mov r6, 2
    mov r7, 12
    mov r8, 15
f5_loop:
    xor out,r1
    mov r2,15
f5_0:
    dec r2
        skip z,1
    jr f5_0 ; 1042Hz
    mov r2,6
f5_1:
    dec r2
        skip z,1
    jr f5_1 ;  821 Hz

        and r0,r0
    
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
    jr f5_loop

; ~659Hz for E5f        
e5f:
    mov r1, 1
    mov r6, 3
    mov r7, 8
    mov r8, 14
e5f_loop:
    xor out,r1
    mov r2,15
e5f_0:
    dec r2
        skip z,1
    jr e5f_0 ; 1042Hz
    mov r2,7
e5f_1:
    dec r2
        skip z,1
    jr e5f_1 ;  821 Hz

        and r0,r0
        and r0,r0
    
    ; nested loop counters
    dec r8
    skip nz,2
    mov r8,14 ; reload lsb
    dec r7    ; decrement 2sb
    skip nz,2
    mov r7,8 ; decrement 3sb
    dec r6
    skip nz,2
    mov out,0
    ret r0,0
    jr e5f_loop

; ~554Hz for C5s        
c5s:
    mov r1, 1
    mov r6, 2
    mov r7, 10
    mov r8, 15
c5s_loop:
    xor out,r1
    mov r2,15
c5s_0:
    dec r2
        skip z,1
    jr c5s_0 ; 1042Hz
    mov r2,12
c5s_1:
    dec r2
        skip z,1
    jr c5s_1 ;  821 Hz

        and r0,r0
    
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
    jr c5s_loop


; ~523Hz for C5            
c5:
    mov r1, 1
    mov r6, 2
    mov r7, 9
    mov r8, 15
c5_loop:
    xor out,r1
    mov r2,15
c5_0:
    dec r2
        skip z,1
    jr c5_0 ; 1042Hz
    mov r2,14
c5_1:
    dec r2
        skip z,1
    jr c5_1 ;  821 Hz
    
    ; nested loop counters
    dec r8
    skip nz,2
    mov r8,15 ; reload lsb
    dec r7    ; decrement 2sb
    skip nz,2
    mov r7,8 ; decrement 3sb
    dec r6
    skip nz,2
    mov out,0
    ret r0,0
    jr c5_loop


; ~466Hz for B4F            
b4f:
    mov r1, 1
    mov r6, 1
    mov r7, 15
    mov r8, 15
b4f_loop:
    xor out,r1
    mov r2,15
b4f_0:
    dec r2
        skip z,1
    jr b4f_0 ; 1042Hz
    mov r2,15
b4f_1:
    dec r2
        skip z,1
    jr b4f_1 ;  821 Hz
    mov r2,3
b4f_2:
    dec r2
        skip z,1
    jr b4f_2 ; 350Hz
    
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
    jr b4f_loop

; ~830Hz for A5F
a5f:
    mov r1, 1
    mov r6, 6
    mov r7, 9
    mov r8, 15
a5f_loop:
    xor out,r1
    mov r2,15
a5f_0:
    dec r2
        skip z,1
    jr a5f_0 ; 1042Hz
    mov r2,2
a5f_1:
    dec r2
        skip z,1
    jr a5f_1
    mov r2,7

    and r0,r0
    
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
    jr a5f_loop

    
; ~415Hz for A4F
a4f:
    mov r1, 1
    mov r6, 2
    mov r7, 7
    mov r8, 15
a4f_loop:
    xor out,r1
    mov r2,15
a4f_0:
    dec r2
        skip z,1
    jr a4f_0 ; 1042Hz
    mov r2,15
a4f_1:
    dec r2
        skip z,1
    jr a4f_1 ;  821 Hz
    mov r2,7
a4f_2:
    dec r2
        skip z,1
    jr a4f_2 ; 350Hz
    
    ; nested loop counters
    dec r8
    skip nz,2
    mov r8,15 ; reload lsb
    dec r7    ; decrement 2sb
    skip nz,2
    mov r7,7 ; decrement 3sb
    dec r6
    skip nz,2
    mov out,0
    ret r0,0
    jr a4f_loop
