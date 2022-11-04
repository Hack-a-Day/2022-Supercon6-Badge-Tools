
; Rain / keypress demo

; init
init: 
mov r0,2  ; go to display page
mov [0xF0], r0

mov r0,7 ; slow down a bit
mov [0xF1], r0

main: 

mov r0, 0xf 
mov [0x20],r0
mov r0, 0xf
mov [0x30],r0

mov r9, 0 ; from counter for falling effect
mov r8, 1 ; to counter for falling effect

; r1 for return values from subroutines
; r2 for stashing values before subroutines

fall:

mov r5, 2 ; page
mov r0, [r5:r9] ; read
mov r2, r0

gosub fadefunction
and r2, r1
mov r0, r2
mov [r5:r8], r0 ; write into next line

mov r5, 3 ; page
mov r0, [r5:r9] ; read
mov r2, r0 ; stash in r2

gosub fadefunction
and r2, r1
mov r0, r2
mov [r5:r8], r0 ; write into next line

; next line
inc r9
inc r8
; test for r9 == 15, then start from top again
; equiv: don't reset if r9 != 15
mov r0, r9
cp r0, 15

skip nz, 0 ; two b/c the goto/gosub evaluates to two commands each.  yoiks, that's a trap.  and zero is 4 -- maybe should fix this too
gosub delay
goto main

goto fall

; count to 16
delay: 
mov r0, 0
mov r1, 0

inc r0
cp R0,0
skip z,1
jr -4
inc r1
mov r0, r1
cp r0, 0
skip z,1
jr -9


ret r0,0




fadefunction: ; returns a 3x-strenghtened random number

mov r0, [0xff]
mov r1, r0

mov r0, [0xff]
or r1, r0

mov r0, [0xff]
or r1, r0

ret R0, 0

