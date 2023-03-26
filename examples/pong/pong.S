Page		EQU	0xf0
Clock		EQU	0xf1
Sync		EQU	0xf2
WrFlags		EQU	0xf3
RdFlags		EQU	0xf4
SetCtrl		EQU	0xf5
SerLow 	 	EQU	0xf6
SerHigh		EQU	0xf7
Received	EQU	0xf8
AutoOff		EQU	0xf9
OutB		EQU	0xfa
InB		EQU	0xfb
KeyStatus	EQU	0xfc
KeyReg		EQU	0xfd
Dimmer		EQU	0xfe
Random		EQU	0xff

    ball_x EQU 0x40
    ball_y EQU 0x41
    ball_direction EQU 0x42
    pedal_1_x EQU 0x43
    pedal_2_x EQU 0x44

    pedal_length EQU 3
    
    screen_page	EQU	0x2
    
init:
    mov r0, screen_page
    mov [Page], r0
    mov r0, 1
    mov [Clock], r0
    mov r0, 0x9  ; use 250ms timer
    mov [Sync], r0
    goto main

move_ball:
    mov r0, [ball_direction]
    mov r4, r0
    mov r1, 0b1

    and r1, r4
    skip nz, 1
    jr up

left:
    mov r0, [ball_x]
    cp r0, 0
    skip nz, 1
    jr turn_right
    dec r0
    mov [ball_x], r0
    jr up
turn_right:
    mov r0, [ball_direction]
    bclr r0, 0
    bset r0, 2
    mov [ball_direction], r0

up:
    mov r1, 0b10
    and r1, r4
    skip nz, 1
    jr right

    mov r0, [ball_y]
    cp r0, 0
    skip nz, 1
    jr turn_down
    dec r0
    mov [ball_y], r0
    jr right
turn_down:  
    mov r0, [ball_direction]
    bclr r0, 1
    bset r0, 3
    mov [ball_direction], r0

right:
    mov r1, 0b100
    and r1, r4
    skip nz, 1
    jr down

    mov r0, [ball_x]
    cp r0, 7
    skip nc, 1
    jr turn_left
    inc r0
    mov [ball_x], r0
    jr down
turn_left:
    mov r0, [ball_direction]
    bclr r0, 2
    bset r0, 0
    mov [ball_direction], r0
    
down:
    mov r1, 0b1000
    and r1, r4
    skip nz, 1
    ret r0, 1

    mov r0, [ball_y]
    cp r0, 15
    skip nc, 1
    jr turn_up

    inc r0
    mov [ball_y], r0
    ret r0, 1

turn_up:
    mov r0, [ball_direction]
    bclr r0, 3
    bset r0, 1
    mov [ball_direction], r0

    ret r0, 1
    
    
    
render_ball:
    mov r2, screen_page + 1
    mov r3, 0
    mov r0, [ball_y]
    mov r4, r0

    jr ball_loop
    
second_part:
    mov r3, 0
    dec r2
    
ball_loop:
    mov r0, r3
    sub r0, r4
    skip z, 1
    jr no_ball
    jr ball

no_ball:
    mov r0, 0
    mov [r2:r3], r0
    jr after_ball
ball:
    mov r0, r2
    cp r0, screen_page
    skip nz, 1
    jr ball_left

ball_right:
    mov r0, [ball_x]
    cp r0, 4
    skip c, 1
    jr no_ball

    mov r1, 4
    sub r0, r1

    mov r1, 1
ball_right_cont:
    cp r0, 0
    skip z, 3
    add r1, r1
    dec r0
    jr ball_right_cont
    
    mov r0, r1
    mov [r2:r3], r0
    jr after_ball
    
ball_left:
    mov r0, [ball_x]
    cp r0, 4
    skip nc, 1
    jr no_ball

    mov r1, 1
ball_left_cont:
    cp r0, 0
    skip z, 3
    add r1, r1
    dec r0
    jr ball_right_cont
    
    mov r0, r1
    mov [r2:r3], r0

after_ball:
    mov r0, r3
    cp r0, 0xf
    skip z, 2
    inc r3
    jr ball_loop

    mov r0, r2
    cp r0, screen_page
    skip z, 1
    jr second_part
    ret r0, 1

pedal_2_render:
    mov r0, [pedal_2_x]
    cp r0, 0
    skip nz, 4
    mov r0, 0b0111
    mov [screen_page:0x0], r0
    mov r0, 0b0
    mov [screen_page + 1:0x0], r0
    cp r0, 1
    skip nz, 4
    mov r0, 0b1110
    mov [screen_page:0x0], r0
    mov r0, 0b0
    mov [screen_page +1:0x0], r0
    cp r0, 2
    skip nz, 4
    mov r0, 0b1100
    mov [screen_page:0x0], r0
    mov r0, 0b0001
    mov [screen_page + 1:0x0], r0
    cp r0, 3
    skip nz, 4
    mov r0, 0b1000
    mov [screen_page:0x0], r0
    mov r0, 0b0011
    mov [screen_page + 1:0x0], r0
    cp r0, 4
    skip nz, 4
    mov r0, 0b0000
    mov [screen_page:0x0], r0
    mov r0, 0b0111
    mov [screen_page + 1:0x0], r0
    cp r0, 5
    skip nz, 4
    mov r0, 0b0000
    mov [screen_page:0x0], r0
    mov r0, 0b1110
    mov [screen_page + 1:0x0], r0
    ret r0, 0

pedal_1_render:
    mov r0, [pedal_1_x]
    cp r0, 0
    skip nz, 4
    mov r0, 0b0111
    mov [screen_page:0xf], r0
    mov r0, 0b0
    mov [screen_page + 1:0xf], r0
    cp r0, 1
    skip nz, 4
    mov r0, 0b1110
    mov [screen_page:0xf], r0
    mov r0, 0b0
    mov [screen_page +1:0xf], r0
    cp r0, 2
    skip nz, 4
    mov r0, 0b1100
    mov [screen_page:0xf], r0
    mov r0, 0b0001
    mov [screen_page + 1:0xf], r0
    cp r0, 3
    skip nz, 4
    mov r0, 0b1000
    mov [screen_page:0xf], r0
    mov r0, 0b0011
    mov [screen_page + 1:0xf], r0
    cp r0, 4
    skip nz, 4
    mov r0, 0b0000
    mov [screen_page:0xf], r0
    mov r0, 0b0111
    mov [screen_page + 1:0xf], r0
    cp r0, 5
    skip nz, 4
    mov r0, 0b0000
    mov [screen_page:0xf], r0
    mov r0, 0b1110
    mov [screen_page + 1:0xf], r0
    ret r0, 0

move_pedal_1_left:
    mov r0, [pedal_1_x]
    cp r0, 0
    skip z, 2

    dec r0
    mov [pedal_1_x], r0
    ret r0, 0

move_pedal_1_right:
    mov r0, [pedal_1_x]
    cp r0, 5
    skip z, 2

    inc r0
    mov [pedal_1_x], r0
    ret r0, 0

move_pedal_2_left:
    mov r0, [pedal_2_x]
    cp r0, 0
    skip z, 2

    dec r0
    mov [pedal_2_x], r0
    ret r0, 0

move_pedal_2_right:
    mov r0, [pedal_2_x]
    cp r0, 5
    skip z, 2

    inc r0
    mov [pedal_2_x], r0
    ret r0, 0

    
check_failure:
    mov r0, [ball_y]
    cp r0, 0
    skip z, 1
    jr check_failure_2

    mov r0, [ball_direction]
    mov r1, 0b10
    and r0, r1
    skip nz, 1
    jr check_failure_2
    
    mov r0, [pedal_2_x]
    mov r2, r0

    mov r0, [ball_x]

    sub r0, r2
    cp r0, 3
    skip nc, 1
    ret r0, 1
    ret r0, 0
    
check_failure_2:
    cp r0, 0xf
    skip z, 1
    ret r0, 0

    mov r0, [ball_direction]
    mov r1, 0b1000
    and r0, r1
    skip nz, 1
    ret r0, 0

    mov r0, [pedal_1_x]
    mov r2, r0

    mov r0, [ball_x]

    sub r0, r2
    cp r0, 3
    skip nc, 1
    ret r0, 1
    ret r0, 0
    
main:
    mov r0, 2
    mov [ball_x], r0

    mov r0, 8
    mov [ball_y], r0

    mov r0, 0b0110
    mov [ball_direction], r0

    mov r0, 3
    mov [pedal_1_x], r0

    mov r0, 4
    mov [pedal_2_x], r0

    
main_loop:
    mov r0, [Random]
    cp r0, 0
    skip z, 1
    jr rest_of_turn

    mov r0, [ball_x]
    cp r0, 0
    skip nz, 1
    jr rest_of_turn
    dec r0
    mov [ball_x], r0

rest_of_turn:   
    gosub move_ball
    gosub render_ball
    gosub pedal_1_render
    gosub pedal_2_render

    mov r0, [KeyReg]
    cp r0, 1
    skip nz, 3
    gosub move_pedal_1_right
    jr wait
    
    cp r0, 2
    skip nz, 3
    gosub move_pedal_1_left
    jr wait

    cp r0, 11
    skip nz, 3
    gosub move_pedal_2_right
    jr wait

    cp r0, 12
    skip nz, 3
    gosub move_pedal_2_left
    jr wait

wait:   
  	mov	r0,[RdFlags]
	bit	r0,0	; Bit 0 is UserSync.
	skip	nz,1
	jr	-4

    gosub check_failure
    cp r0, 1
    skip nz, 1
    jr main
    

    jr main_loop
