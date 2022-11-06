; r0:   temp
; r1:   low nibble a
; r2:   high nibble a
; r3:   low nibble b
; r4:   high nibble b
; r5:   low nibble c
; r6:   high nibble c
; r7:   reg pointer x
; r8:   reg pointer y
; r9:   reg pointer z

; slow down the clock
mov r0, 12
mov r1, 0xf
mov r2, 0x1
mov [r1:r2], r0

; set the page to 1
mov r0, 1
mov r2, 0x0
mov [r1:r2], r0

; clear the registers and set the initial values
mov r1, 0
mov r2, 0
mov r3, 1
mov r4, 0
mov r5, 0
mov r6, 0
mov r7, 0x1
mov r8, 0x2
mov r9, 0

; store the current value of b in c
mov r5, r3 
mov r6, r4

; add a to b, store result in b
add r3, r1
adc r4, r2

; display a on page 1 and 2
mov r0, r2
mov [r8:r9], r0
mov r0, r1
mov [r7:r9], r0
inc r9

; copy the stored value from c to a
mov r1, r5
mov r2, r6

; repeat
jr -12
