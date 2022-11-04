; Bouncing ball demo

; init
init: 
mov r8, 14 ; x coordinate, 16 values mapped to 8 LEDs
mov r9, 8 ; y coordinate

mov r6, 1 ; x direction (-1)
mov r7, 1 ; y direction 

mov r3, r8 ; previous ball x
mov r4, r8 ; previous ball y

mov r5, 2 ; page
mov r2, 0 ; storage for the ball's bit

mov r0,r5  ; go to display page
mov [0xF0], r0

mov r0,4 ; slow down a bit
mov [0xF1], r0


main:
; check bounds X
mov r0, r8
cp r0,15
skip nz, 1 
mov r6, 15 ; (-1)

cp r0,0
skip nz, 1 
mov r6, 1

; check bounds Y
mov r0, r9
cp r0,15
skip nz, 1 
mov r7, 15 ; (-1)

cp r0,0
skip nz, 1 
mov r7, 1

mov r3, r8 ; copy old x
mov r4, r9 ; copy old y
; move X
add r8, r6 
; move Y
add r9, r7

; random lurch
mov r0, [0xFF]
cp r0, 0 ; if rnd == 0
skip nz, 0
mov r0, r8 ; and current X >= 1
cp r0, 1 ; 
skip nc, 1
dec r8


; display
gosub draw_ball
gosub clear_ball

; ALU toggle
mov R0, [0xFC] ; get keypress status
bit R0,0; ; tests if not pressed, in Z
skip z,3
mov R0, [0xF3]
btg R0,3
mov [0xF3], R0

goto main
; endless loop

org 0x100 ; I like to keep my subroutines far out.   
draw_ball:
mov r2, r8 ; copy current x into disp register
gosub set_page

bclr r2, 2 ; clear page bit -- now contains bit position
mov r0, r2 ; gonna loop to shift bit
mov r2, 1 ; r2 has bit position zero
cp r0, 0 ; set z when it's zero
skip z, 3 
add r2,r2 ; 
dec r0
jr -5 ; 

; r2 should now contain one bit in the right position
mov r0, r2 
mov [r5:r9], r0
ret R0, 0; not looking at return code anyway

org 0x180
set_page: ; ( needs x coordinate in r2 )
and r0,0 ; clear out the carry bit
rrc r2     ; 16 -> 8, bit 2 is page, bits 0,1 contain bit position
bit r2, 2 ; tests if it is zero(!)
skip z, 2 
mov r5,3 ; page 3 if on
jr 1
mov r5,2 ; page 2 if off
ret R0, 0

org 0x200 
clear_ball:
mov r2, r3 ; copy old x disp register
gosub set_page
mov r0, 0;
mov [r5:r4], r0
ret R0, 0






