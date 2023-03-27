;; flappy.asm - Flappy Bird (Flappy Bit?) for the Supercon/Hackaday Berlin badge.
;;
;; Copyright (c) 2023 Simen E. Sørensen | @simenzhor@mastodon.social
;;
;; I have used some functions from Octavian Voicu's "General Purpose Library" (in octav-snake/snake.asm). 
;; Octav's original library is written for a game played in portrait mode, 
;; so I have modified some functions to work better in the landscape mode.
;; I have kept Octav's original coordinate system, where x exists in the range 0-7 and y in the range 0-14.
;; The coordinate system's origin is in the top left corner (assuming portrait mode) near the R0/PAGE+1 labels 
;; I have also used the registry definitions from Bradon Kanyid / Rattboi (in rattboi-falldown/falldown.asm).

; Constants/parameters.
screen_page	EQU	0x2					; memory page for the screen
start_x		EQU	7					; initial position of the bird
start_y		EQU	2	
start_hole_min_size	EQU	6			; initial min_size of hole in the wall (can randomly grow 1 pixel by introducing zero from "carry")
jump_btn_bitmask EQU 3				; bitmask for deciding which button to use for jumping (3 means the LSB-button in the "Operand Y" section, labeled "++++" in silkscreen)
delta_x_jump EQU 2
delta_x_fall EQU 1
game_speed_divider EQU 7 			; speed of the sync signal (the worst case processing time must be able to happen within this time to keep constant framerate - but it should be as fast as possible to register keypresses)
start_fall_speed_divider EQU 10		; initial fall speed of the bird. It divides the "Sync" clock
start_wall_speed_divider EQU 5		; initial speed of the walls. It divides the "Sync" clock
minimum_wall_speed_divider EQU 2 	; 
minimum_wall_hole_size EQU 1
increase_wall_speed_every_n_wall EQU 5; How many walls to pass before their speed increases
decrease_wall_hole_every_n_wall EQU 3 ; How many walls to pass before their hole size decreases


; Global variables.
; These point to memory addresses where data is stored. 
; The "screen" uses addresses [0x20, 0x40)
bird_y_ptr		EQU	0x40			; bird position
bird_x_ptr		EQU	0x41
wall_y_ptr	    EQU	0x42			; y position of wall
top_wall_shape_ptr	EQU	0x43		; pattern of the top half of the wall (the four rows labeled PAGE)
bot_wall_shape_ptr	EQU	0x44		; pattern of the bottom half of the wall (the four rows labeled PAGE+1)
wall_speed_divider_ptr	EQU	0x45	; current difficulty pt.1 (speed of the wall) 
wall_hole_size_ptr EQU 0x46 		; current difficulty pt.2 (size of hole in the wall)
fall_speed_cnt_ptr	EQU	0x47		; fall speed of the bird. It divides the "Sync" clock
wall_speed_cnt_ptr	EQU	0x48		; speed of the walls. It divides the "Sync" clock. Initial speed is specified in the start_wall_speed_divider variable
inc_wall_speed_cnt_ptr EQU 0x49 	; counter that is used to determine how many walls to pass before increasing their speed
dec_wall_hole_size_cnt_ptr EQU 0x4a ; counter that is used to determine how many walls to pass before decreasing the size of the hole


score_ptr_lsn		EQU	0x4e	; 8-bit score pointer, least significant nibble
score_ptr_msn		EQU	0x4f	; 8-bit score pointer, most significant nibble


;;;;
;;;; Game loop.
;;;;

init:
	mov	r0,screen_page
	mov	[Page],r0		
	mov	r0, F_100_kHz		
	mov	[Clock],r0		; Clock = 100 kHz

	mov	r0, game_speed_divider ; Set frequency divider for "sync" signal
	mov	[Sync],r0

	; init "counter" register
	mov r0, start_fall_speed_divider
	mov [fall_speed_cnt_ptr], r0
	; init counter variable
	mov r0, start_wall_speed_divider
	mov [wall_speed_divider_ptr], r0

	; init score
	mov r0, 0
	mov [score_ptr_msn], r0
	mov [score_ptr_lsn], r0

	; init difficulty counters
	mov r0, increase_wall_speed_every_n_wall
	mov [inc_wall_speed_cnt_ptr], r0
	mov r0, decrease_wall_hole_every_n_wall
	mov [dec_wall_hole_size_cnt_ptr], r0

	; init bird position
	mov r0, start_x; mov x coord to r0
	mov [bird_x_ptr], r0; store new x coord in variable
	mov r8, r0		; mov x coord to r8 for subroutine-call
	mov r0, start_y; mov x coord to r0
	mov [bird_y_ptr], r0; store new y coord in variable
	mov r9, r0		; mov y coord to r9 for subroutine-call
	GOSUB set_pixel

	; init wall
	mov r0, 0xf
	mov [wall_y_ptr], r0; store wall_y
	mov r0, start_hole_min_size
	mov [wall_hole_size_ptr], r0; init size of hole in wall
	GOSUB generate_new_wall

game_loop:

	gosub 	move_and_draw_wall
	cp		r0,1 			; Draw wall returns 1 if bird collides with wall
	skip	nz,3
	mov 	r5, 1			; r5 = crash_type 1 (wall crash)
	goto	game_over

	gosub	move_and_draw_bird		; Draw bird returns 1 if bird collides with floor or ceiling
	cp		r0,1 			
	skip	nz,3
	mov 	r5, 0 			; r5 = crash_type 0 (floor or ceiling crash)
	goto	game_over

	gosub	user_sync
	goto	game_loop

game_over:
	mov r4, 3 ; Number of blinks in die_animation
	gosub	die_animation
	gosub	clear_screen
	gosub   display_final_score
	gosub 	clear_key_press_flags
	gosub	wait_key_press
	gosub	clear_screen
	goto	init

; move_and_draw_wall()
; Moves the wall and redraws it. Also checks if the bird crashed into the wall.
; 
; returns 0 if no crash was detected
; returns 1 if the bird crashed into the wall
move_and_draw_wall:
	; Adjust speed of wall with a counter (divides the user_sync clock)
	mov r0, [wall_speed_cnt_ptr]
	dec r0 ; decrement counter
	mov [wall_speed_cnt_ptr], r0
	skip z, 1 ; 
	; wall_speed_cnt still contains a value above 0
	ret r0, 0

	mov r0, [wall_speed_divider_ptr]
	mov [wall_speed_cnt_ptr], r0; reset counter

	; Ready to move wall. But before we do, check if it's about to crash into the bird
	; Check if wall is on same column as the bird
	mov r0, [bird_y_ptr]
	mov r1, r0 ; store bird_y in r1
	mov r0, [wall_y_ptr]
	dec r0; r0 = "next_wall_y
	sub r0, r1 ;  next_wall_y - bird_y == 0
	skip z, 2
	; next_wall_y != bird_y:
	GOTO no_potential_collision
	; next_wall_y == bird_y:
	GOSUB detect_wall_collision
	cp	r0,1
	skip nz,1 ;if detect_collision returns 1, collision happened. Propagate this to the game loop.
	ret r0, 1 ; return 1 to indicate COLLISION!

	; next_wall_y != bird_y:
	no_potential_collision:
	; Remove previously drawn wall
	GOSUB clear_wall

	; Move wall and redraw
	mov r0, [wall_y_ptr]; r0 = wall_y
	dec r0; move wall to the left				(sets C if R0 < 0)
	mov [wall_y_ptr], r0; store new pos in var
	skip c, 4 ; if R0 >= 0, skip next line
	GOSUB 	generate_new_wall
	GOSUB	add_point


	mov r0, [wall_y_ptr]; r0 = wall_y
	mov r9, r0;  place wall_y in r9
	mov r8, 2 ; page 2 (top half) to r8
	mov r0, [top_wall_shape_ptr] ; fetch top half of wall
	mov	[r8:r9], r0; Draw top half of wall
	mov r8, 3 ; page 3 (bottom half) to r8
	mov r0, [bot_wall_shape_ptr] ; fetch bottom half of wall
	mov	[r8:r9], r0; Draw bottom half of wall 

	; repaint bird in case it was cleared with the wall
	GOSUB repaint_bird

	
	ret r0, 0


; move_and_draw_bird()
; checks if bird has jumped, fallen or crashed. Redraws bird in the new position.
;
; returns 0 if no crash was detected
; returns 1 if the bird crashed with the floor or ceiling
move_and_draw_bird:
	GOSUB get_dir_key
	cp r0, 0xf ; check if no key was pressed
	skip nz, 2 ; 
	; no key was pressed
	goto apply_gravity
	; key was pressed
	cp r0, jump_btn_bitmask ; Check if key was "jump key"
	skip z, 1
	;unused key was pressed
	ret r0, 0
	; jump-key was pressed

	gosub 	clear_key_press_flags

	; Ready to move bird upwards. But before we do, check if it's about to crash into the ceiling
	GOSUB detect_ceiling_collision
	cp		r0, 1 			; detect_ceiling_collision returns 1 if bird collides with ceiling
	skip	nz, 1
	ret 	r0, 1			; return 1 to indicate crash

	GOSUB clear_bird

	mov r0, [bird_x_ptr]; mov x coord to r0
	add r0, delta_x_jump; increment x coord
	mov [bird_x_ptr], r0; store new x coord in variable
	mov r8, r0		; mov x coord to r8 for subroutine-call
	mov r0, [bird_y_ptr]; mov y coord to r0
	mov r9, r0		; mov y coord to r9 for subroutine-call
	GOSUB set_pixel
	ret r0, 0

	apply_gravity:

		mov r0, [fall_speed_cnt_ptr]
		dec r0 ; decrement counter
		mov [fall_speed_cnt_ptr], r0
		skip z, 1 ; if fall_speed_cnt == 0: jump across the next line
		; fall_speed_cnt still contains a value above 0
		ret r0, 0

		; fall_speed_cnt has counted down to 0. APPLY GRAVITY!!!
		mov r0, start_fall_speed_divider ; reset fall_speed_cnt
		mov [fall_speed_cnt_ptr], r0
		
		; Ready to move bird downwards. But before we do, check if it's about to crash into the floor
		GOSUB detect_floor_collision
		cp		r0, 1 			; detect_floor_collision returns 1 if bird collides with ceiling
		skip	nz, 1
		ret 	r0, 1			; return 1 to indicate crash 

		; Move bird downwards
		GOSUB clear_bird
		mov r0, [bird_x_ptr]; mov x coord to r0
		mov r1, delta_x_fall; store fall constant in r1
		sub r0, r1; Decrement x coord 
		mov [bird_x_ptr], r0; store new x coord in variable
		mov r8, r0		; mov x coord to r8 for subroutine-call
		mov r0, [bird_y_ptr]; mov y coord to r0
		mov r9, r0		; mov y coord to r9 for subroutine-call
		GOSUB set_pixel
		ret r0, 0

; clear_bird()
; Preserves: r4, r5, r6.
clear_bird:
	mov r0, [bird_x_ptr]; mov x coord to r0
	mov r8, r0		; mov x coord to r8 for subroutine-call
	mov r0, [bird_y_ptr]; mov y coord to r0
	mov r9, r0		; mov y coord to r9 for subroutine-call
	GOSUB clear_pixel
	ret r0, 0

; repaint_bird()
; Preserves: r4, r5, r6.
; repaints the bird in its current position. Is used when there's a chance that the bird has been
; unintentionally cleared. For example by clear_wall()
repaint_bird:
	mov r0, [bird_x_ptr]; 
	mov r8, r0		; r8 = bird_x (for subroutine-call)
	mov r0, [bird_y_ptr];
	mov r9, r0		; r9 = bird_y (for subroutine-call)
	GOSUB set_pixel
	ret r0, 0

; clear_wall()
; uses r0, r8, r9
clear_wall:
	mov r0, [wall_y_ptr]; get variable value
	mov r9, r0;  place wall_y in r9
	mov r0, 0x0 ; Clear r0
	mov r8, 2 ; page 2 to r8
	mov	[r8:r9], r0; Clear wall from top half of screen
	mov r8, 3 ; page 3 to r8
	mov	[r8:r9], r0; Clear wall from bottom half of screen 
	ret r0, 0

; detect wall collision (must be run before clearing wall and bird) 
;
; modifies r0,r1,r2,  r8,r9
;
; Fetches the two pages for the bird column and the two pages of the wall column,
; then does a bitwise AND to check for collision between the two
;
; For detecting collisions with floor and ceiling, use detect_frame_collision
detect_wall_collision:
	mov r0, [wall_y_ptr]
	mov r8, r0; 		r8 = wall_y
	mov r0, [bird_y_ptr]
	mov r9, r0;        r9 = bird_y

	mov r1, 2 ; page 2
	mov r0, [r1:r8] ; 
	mov r2, r0 ; r2 = top half of wall column
	mov r0, [r1:r9] ; r0 = top half of bird column
	and r0, r2; Z=0 if collision
	skip z, 1
	ret r0, 1 ; collision in top half!
	
	mov r1, 3 ; page 3
	mov r0, [r1:r8] ; 
	mov r2, r0 ; r2 = top half of wall column
	mov r0, [r1:r9] ; r0 = top half of bird column
	and r0, r2; Z=0 if collision
	skip z, 1
	ret r0, 1 ; collision in top half!
	
	ret r0,0 ; no collision :)

; Detect if collision with floor is about to occur when applying gravity. 
; modifies r0 and r1
detect_floor_collision:
	
	mov r0, [bird_x_ptr]
	mov r1, r0 			; r1 = bird_x
	mov r0, delta_x_fall
	sub r1, r0 			; (r1 = next_bird_x) if next_bird_x < 0: collision occured 
	skip c, 1			; C is cleared if underflow occurs
	; prev_bird_x == 0:
	ret r0, 1 ; return 1 to indicate COLLISION!
	; prev_bird_x != 0:
	ret r0, 0

; Detect if collision with ceiling is about to occur when jumping. 
; modifies r0 
detect_ceiling_collision:
	mov r0, [bird_x_ptr]
	add r0, delta_x_jump	; r0 = next_bird_x
	skip c, 4				; C gets set if overflow occurs in ADD
	cp r0, 8				; if next_bird_x >= 8: collision occured
	skip c, 2				; C gets set if R >= 8
	; next_bird_x != 0:
	GOTO no_floor_collision
	; next_bird_x == 0:
	; Move bird close to wall to indicate that this is where the crash happened
	GOSUB clear_bird
	mov r0, 7			; 7 = closest LED to ceiling
	mov [bird_x_ptr], r0
	GOSUB repaint_bird
	ret r0, 1 ; return 1 to indicate COLLISION!

	; prev_bird_x != 0:
	no_floor_collision:
	ret r0, 0

; die_animation blinks LEDs to indicate crash (num_blinks=r4, crash_type=r5)
;
; crash_type == 1: wall crash 
; 	Blink bird and wall if collision is with wall.
; crash_type == 0: frame crash (floor or ceiling)
; 	Blink only bird if collision is with floor or ceiling
;
; modifies r0, r3, r8,r9
die_animation:

	;Delay for LED ON
	mov r3, 15
	GOSUB user_sync
	dsz r3; Decrement r3 and ignore next instruction if zero
	jr -4
	
	; Turn off bird LED
	GOSUB clear_bird 

	; Check if wall should be turned off
	mov r0, r5
	cp r0, 0
	skip z, 2 ; if crash_type != 0: clear wall
	GOSUB clear_wall
	
	;Delay for LED OFF
	mov r3, 15
	GOSUB user_sync
	dsz r3; Decrement r3 and ignore next instruction if zero
	jr -4

	; Repaint bird
	GOSUB repaint_bird

	; Repaint wall
	mov r0, [wall_y_ptr]
	mov r9, r0
	mov r8, 2 ; page 2 (top half) to r8
	mov r0, [top_wall_shape_ptr] ; fetch top half of wall
	mov	[r8:r9], r0; Draw top half of wall
	mov r8, 3 ; page 3 (bottom half) to r8
	mov r0, [bot_wall_shape_ptr] ; fetch bottom half of wall
	mov	[r8:r9], r0; Draw bottom half of wall 
	

	dsz r4; Decrement r4 (num_blinks) and ignore next instruction if zero
	jr die_animation
	ret r0, 0


increase_difficulty:
	mov r0, [score_ptr_lsn] ; low nibble
	mov r2, r0
	mov r0, [score_ptr_msn] ; high nibble
	mov r1, r0
	; score = (r1:r2)
	check_wall_speed_counter:
		mov r0, [inc_wall_speed_cnt_ptr] ; r0 = increase wall speed counter
		dec r0
		mov [inc_wall_speed_cnt_ptr], r0
		skip z, 1 ; 
		jr check_wall_hole_counter

		; reset counter
		mov r0, increase_wall_speed_every_n_wall
		mov [inc_wall_speed_cnt_ptr], r0

		; increase wall speed
		mov r0, [wall_speed_divider_ptr]
		cp r0, minimum_wall_speed_divider ; compare current divider and the minimum one
		skip z, 2
		dec r0
		mov [wall_speed_divider_ptr], r0
	check_wall_hole_counter:
		mov r0, [dec_wall_hole_size_cnt_ptr] ; r0 = increase wall speed counter
		dec r0
		mov [dec_wall_hole_size_cnt_ptr], r0
		skip z, 1 ; 
		ret r0, 0

		; reset counter
		mov r0, decrease_wall_hole_every_n_wall
		mov [dec_wall_hole_size_cnt_ptr], r0

		; reduce wall hole size
		mov r0, [wall_hole_size_ptr]
		cp r0, minimum_wall_hole_size ; compare current divider and the minimum one
		skip z, 2
		dec r0
		mov [wall_hole_size_ptr], r0
	ret r0, 0

generate_new_wall:
	; Fill entire row with LEDs
	mov r8, 0b1111
	mov r9, 0b1111

	; shift in R5 zeros (the hole in the wall)
	mov r0, [wall_hole_size_ptr]
	mov r5, r0
	shiftloop_add_hole:
		and r0, 0; Clear "Carry" flag (this is the zero that we add)
		rrc r9
		rrc r8
		dsz r5
		jr shiftloop_add_hole

	; shift hole to a random position
	mov r0, [Random]
	mov r5, r0; number of shifts
	and r0, 0 ; Clear "Carry" flag (this may add an extra zero to the hole in the wall)
	shiftloop_move_hole:
		rrc R9
		rrc R8
		dsz R5
		jr shiftloop_move_hole

	; store new wall
	mov r0, r8
	mov [top_wall_shape_ptr], r0; store top half of wall
	mov r0, r9
	mov [bot_wall_shape_ptr], r0; store bottom half of wall

	ret r0, 0
display_final_score:
	
	mov	r0,[score_ptr_lsn]
	mov	r9,r0
	mov	r0,[score_ptr_msn]
	mov	r8,r0
	gosub	draw_score_landscape
	ret r0, 0

add_point:
	mov r0, 0
	mov r2, r0
	mov r0, [score_ptr_lsn] ; low nibble
	mov r1, r0
	mov r0, [score_ptr_msn] ; high nibble
	inc r1
	adc r0, r2 ; 8-bit increment (add zero, with carry)
	; score = (r0:r1)
	mov [score_ptr_msn], r0
	mov r0, R1
	mov [score_ptr_lsn], r0
	; RET R0, 0
	GOSUB	increase_difficulty
	ret r0,0

;; debug_crash_location is basically `printf("HERE!")`.
;; When called, it will turn on the entire screen.
;; If the screen doesn't change, the crash happened earlier than the call to this function 
debug_crash_location:
	mov r1, 14; set max column (in flappy bird coords)
	mov r2, 2; page2
	mov r3, 3; page3
	
	mov r0, 0xf
	mov [r2:r1], r0
	mov [r3:r1], r0
	dsz r1
	jr -5
	ret r0, 0


;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Register definitions from 
; Falldown by Bradon Kanyid / Rattboi
; MIT License 2022
;
;;;;;;;;;;;;;;;;;;;;;;;;;

; symbols for special registers
Page        EQU 0xf0
Clock       EQU 0xf1
  F_250_kHz EQU 0
  F_100_kHz EQU 1
  F_30_kHz  EQU 2
  F_10_kHz  EQU 3
  F_3_kHz   EQU 4
  F_1_kHz   EQU 5
  F_500_Hz  EQU 6
  F_200_Hz  EQU 7
  F_100_Hz  EQU 8
  F_50_Hz   EQU 9
  F_20_Hz   EQU 10
  F_10_Hz   EQU 11
  F_5_Hz    EQU 12
  F_2_Hz    EQU 13
  F_1_Hz    EQU 14
  F_1_2_Hz  EQU 15
Sync        EQU 0xf2
WrFlags     EQU 0xf3
  LedsOff   EQU 3
  MatrixOff EQU 2
  InOutPos  EQU 1
  RxTxPos   EQU 0
RdFlags     EQU 0xf4
  Vflag     EQU 1
  UserSync  EQU 0       ; cleared after read
SerCtl      EQU 0xf5
  RxError   EQU 3       ; cleared after read
SerLow      EQU 0xf6
SerHigh     EQU 0xf7
Received    EQU 0xf8
AutoOff     EQU 0xf9
OutB        EQU 0xfa
InB         EQU 0xfb
KeyStatus   EQU 0xfc
  AltPress  EQU 3
  AnyPress  EQU 2
  LastPress EQU 1
  JustPress EQU 0       ; cleared after read
KeyReg      EQU 0xfd
Dimmer      EQU 0xfe
Random      EQU 0xff


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                                        ;;;;
;;;;                        General Purpose Library                         ;;;;
;;;;                   Copyright (c) 2022 Octavian Voicu                    ;;;;
;;;;                              MIT License                               ;;;;
;;;;                                                                        ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;  These are mostly self-contained functions that may be reused in other
;;;;  programs with little or no modifications.
;;;;

;;;;;;;;;;;;;;;;;
;;             ;;
;;  Functions  ;;
;;             ;;
;;;;;;;;;;;;;;;;;
;;
;; Timing:
;; - user_sync()
;;
;; Direction keys and screen coordinates:
;; - wait_key_press()
;; - get_dir_key() -> dir
;; - delta_position(y, x, dir) -> new_y, new_x
;; - get_random_position() -> y, x
;;
;; Drawing digits:
;; - byte_to_base_10(byte) -> hundreds, tens, units
;; - draw_digit(digit, y, x)
;; - draw_triplet(pattern, y, x)
;;
;; Digit pixel maps (3x5):
;; - digit_N (N=0..9)
;;
;; Low level drawing:
;; - clear_screen(pattern)
;; - put_pixel(y, x, c)
;; - set_pixel(y, x)
;; - clear_pixel(y, x)
;; - get_pixel(y, x) -> c
;; - get_screen_addr(y, x) -> addr, mask
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               ;;
;;  Library Calling Conventions  ;;
;;                               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; - Input arguments are passed in r9, r8, r7, r6, r5, r4 (in order, as needed).
;; - Simple constants may be returned through r0. Other values may be returned
;;   through the same registers used for input arguments, in the same order
;;   (e.g. r9, r8).
;; - Byte values should be passed and returned in little-endian order (least
;;   significant nibble first). For example, if a function accepts a single byte
;;   argument, r9 will hold the low nibble and r8 the high nibble.
;; - Registers r0, r4, r5, r6, r7, r8, r9 are generally caller-saved (volatile).
;;   A function may change them as needed and does not need to restore them.
;; - If a function doesn't need all the volatile registers it should prefer to
;;   to use the higher order ones and document which ones it preserves.
;; - Registers r1, r2, r3 are callee-saved (non-volatile). A function may change
;;   them, but they must be restored before returning (e.g. using xhr).
;; - Only one function in the call stack may use xhr.
;; - If a function calls another function that uses xhr, it is not allowed to
;;   use xhr unless it calls xhr to restore the registers before the call.
;; - A function is considered to use xhr if any function it calls uses xhr, even
;;   if xhr is not used in the function itself.
;; - Tail calls are encouraged, especially when this reduces the call depth of
;;   the function. E.g. use goto instead of gosub and omit the ret when the last
;;   instruction is a function call and the r0 return value and/or the output
;;   registers from this function call can be returned directly.


;; user_sync()
;;
;; Preserves: r4, r5, r6, r7, r8, r9.
;;
;; Waits for UserSync flag in RdFlags to be set. The period is controlled via
;; the Sync register. Once read, the flag is reset and will be set again when
;; the next period is elapsed.
user_sync:
	mov	r0,[RdFlags]
	bit	r0,0	; Bit 0 is UserSync.
	skip	nz,1
	jr	-4
	ret	r0,0

;; get_user_sync() -> r0=sync
;;
;; Preserves: r4, r5, r6, r7, r8, r9.
;;
;; Returns 1 iff the UserSync flag in RdFlags is set.
get_user_sync:
	mov	r0,[RdFlags]
	bit	r0,0	; Bit 0 is UserSync.
	skip	nz,1
	ret	r0,0
	ret	r0,1

;; Key constants used for get_dir_key.
;; The values correspond to keys defined for KeyReg.
key_unused1	EQU	9	; operand y 8
key_unused2	EQU	10	; operand y 4
key_unused3	EQU	11	; operand y 2
key_jump	EQU	12	; operand y 1

;; wait_key_press()
;;
;; Preserves: r4, r5, r6, r7, r8, r9.
;;
;; Waits until a key recognied by get_dir_key is pressed.
wait_key_press:
	gosub	get_dir_key
	cp	r0,0xf
	skip	nz,1
	jr	-5
	ret	r0,0

clear_key_press_flags:
	mov r0, 0
	mov [KeyStatus],r0
	mov [KeyReg],r0
	ret r0, 0

;; get_dir_key() -> r0=dir
;;
;; Preserves: r4, r5, r6, r7, r8, r9.
;;
;; Checks is any of the recognized keys were just pressed (see key_* definitions).
;; Return value is 0, 1, 2, 3 (corresponding to the dir parameter of delta_position),
;; or 0xf if no new key was pressed.
get_dir_key:
	mov	r0,[KeyStatus]
	and	r0,0x1
	skip	nz,1
	ret	r0,0xf
	mov	r0,[KeyReg]
	cp	r0,key_unused2
	skip	nz,3
	gosub clear_key_press_flags
	ret	r0,0	; up
	cp	r0,key_unused1
	skip	nz,3
	gosub clear_key_press_flags
	ret	r0,1	; left
	cp	r0,key_unused3
	skip	nz,3
	gosub clear_key_press_flags
	ret	r0,2	; down
	cp	r0,key_jump
	skip	nz,3
	gosub clear_key_press_flags
	ret	r0,jump_btn_bitmask	; jump
	ret	r0,0xf

;; delta_position(r9=y, r8=x, r7=dir) -> r0=ok r9=new_y r8=new_x
;;
;; Preserves: r4, r5, r6.
;;
;; Returns 1 and new coordinates y, x iff these are not wrapping around the
;; screen, or 0 otherwise.
;;
;; dir:
;;   0 = 0b00 - Y - up
;;   1 = 0b01 - X - left
;;   2 = 0b10 - Y - down
;;   3 = 0b11 - X - right
;;
;; This particular encoding was chosen for several reasons:
;; - Bit 0 indicates on Y axis (0) or X axis (1).
;; - Bit 1 indicates decreasing coordinates (0) or increasing (1).
;; - X and Y directions alternate, so XOR-ing bit 0 of two directions
;;   can be used to check that the new direction is not a reversal.
delta_position:
	mov	r0,r7
; Increase or decrease coordinate?
	bit	r0,1
	skip	z,1
	jr	8
; Decrease - up or left?
	bit	r0,0
	skip	nz,2
; Go up.
	dec	r9
	jr	1
; Go left.
	dec	r8
	skip	c,1
	ret	r0,0
	ret	r0,1
; Increase - right or down?
	bit	r0,0
	skip	nz,4
; Go down.
	inc	r9
	skip	nc,1
	ret	r0,0
	ret	r0,1
; Go right.
	inc	r8
	mov	r0,0x7
	sub	r0,r8
	skip	c,1
	ret	r0,0
	ret	r0,1

;; get_random_position() -> r9=y r8=x
;;
;; Preserves: r4, r5, r6, r7.
;;
;; Returns the y, x coordinates of a random location.
get_random_position:
	; r9 = rand()
	mov	r0,[Random]
	mov	r9,r0
	; r8 = rand() & 0x7
	mov	r0,[Random]
	mov	r8,0x7
	and	r8,r0
	ret	r0,0

;; byte_to_base10(r8:r9=byte) -> r9=hundreds r8=tens r7=units
;;
;; Preserves: r4, r5.
;;
;; Returns base 10 representation of a byte.
byte_to_base10:
	mov	r7,r9
	mov	r6,r8
; Compute hundreds.
	mov	r9,0
; loop:
	mov	r0,low 100
	sub	r7,r0
	mov	r0,mid 100
	sbb	r6,r0
	skip	nc,2
	inc	r9
	jr	-7
	mov	r0,low 100
	add	r7,r0
	mov	r0,mid 100
	adc	r6,r0
; Compute tens.
	mov	r8,0
; loop:
	mov	r0,10
	sub	r7,r0
	skip	c,1
	dec	r6
	skip	nc,2
	inc	r8
	jr	-7
	add	r7,r0
	skip	nc,1
	inc	r6
; Reminder in r7 is units.
	ret	r0,0

;; draw_score_landscape (r8:r9=score)
;;
;; Uses exr.
;;
;; Draws an 8-bit score in landscape mode
draw_score_landscape:
	gosub	byte_to_base10
	exr	3
	mov	r1,r8
	mov	r2,r7
; Display hundreds.
	mov	r8,2
	mov	r7,5
	gosub	draw_digit_landscape
; Display tens.
	mov	r9,r1
	mov	r8,6
	mov	r7,5
	gosub	draw_digit_landscape
; Display units.
	mov	r9,r2
	mov	r8,0xa
	mov	r7,5
	gosub	draw_digit_landscape
	exr	3
	ret	r0,0

;; Global storage for digit drawing functionality.
;; These can be moved to other memory locations if there are conflicts.
digit_buf	EQU	0xd8	; buffer of size 6; must fit within a single page
digit_y		EQU	0xde
digit_x		EQU	0xdf

;; draw_digit_landscape(r9=digit, r8=y)
;;
;; Draws a 8x3 digit starting at the specified y coordinate.
;; The digit is shown in landscape mode (ie. across the width of the screen)
;; Uses digit_buf and digit_y globals.
;; The buffer is drawn across two pages of memory (ie. the whole screen).
draw_digit_landscape:
; Store target coordinates.
	mov	r0,r8
	mov	[digit_y],r0
; The digits are stored in program memory, so setting the jsr pointer to a digit will return a nibble from the digit to r0
; Skip to the correct digit.
	gosub	digit_0
	mov	r7,jsr
	mov	r6,6
	mov	r0,0
	inc	r9 ; loop runs r9 times (but does not run if the digit we are looking for is 0)
	jr	3
; loop:
	add	r7,r6 ; increase program counter with number of nibbles in each digit
	adc	pcm,r0 ; pcm = mid nibble of program counter 
	adc	pch,r0 ; pch = highest nibble of program counter
	dsz	r9
	jr	-5
; Now copy each line to the buffer.
	mov	r9,low digit_buf ; row number  (ex: if digit_buf=0xd8, low digit_buf returns 8)
	mov	r8,mid digit_buf ; page number (ex: if digit_buf=0xd8, mid digit_buf returns d)
	mov	jsr,r7
	mov	[r8:r9],r0 ; copy first nibble of digit
	mov	r6,5 ; loop runs r6 additional times
; loop:
	inc	r9
	mov	r0,0
	inc	r7
	adc	pcm,r0
	adc	pch,r0
	mov	jsr,r7
	mov	[r8:r9],r0 ; copy second to last nibble of digit
	dsz	r6
	jr	-9
; Finally draw each line.
; Draw top half of digit
	; draw_digit_line(digit_buf, digit_y++, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,2
	mov	r9,r0
	mov	r0,[digit_buf]
	mov [r9:r8],r0
	; draw_digit_line(digit_buf + 1, digit_y++, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,2
	mov	r9,r0
	mov	r0,[digit_buf+1]
	mov [r9:r8],r0
	; draw_digit_line(digit_buf + 2, digit_y++, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,2
	mov	r9,r0
	mov	r0,[digit_buf+2]
	mov [r9:r8],r0

; Draw bottom half of digit

	; reset digit y to initial position
	mov	r0,[digit_y]
	dec	r0
	dec	r0
	dec	r0
	mov	[digit_y],r0

	; draw_digit_line(digit_buf + 3, digit_y++, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,3
	mov	r9,r0
	mov	r0,[digit_buf+3]
	mov [r9:r8],r0
	; draw_digit_line(digit_buf + 4, digit_y, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,3
	mov	r9,r0
	mov	r0,[digit_buf+4]
	mov [r9:r8],r0
	; draw_digit_line(digit_buf + 5, digit_y, digit_x)
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,3
	mov	r9,r0
	mov	r0,[digit_buf+5]
	mov [r9:r8],r0
	ret	r0,0

;; draw_triplet(r9=pattern, r8=y, r7=x)
;;
;; Draws a 3 pixel pattern at y, x (lowest three bits are used).
draw_digit_line:
	mov	r4,r9
	mov	r5,r8
	mov	r6,r7
	; pattern <<= 1
	add	r4,r4
	; pattern <<= 1; put_pixel(y, x++, carry)
	add	r4,r4
	mov	r9,r5
	mov	r8,r6
	mov	r7,0
	adc	r7,r7
	gosub	put_pixel
	inc	r6
	; pattern <<= 1; put_pixel(y, x++, carry)
	add	r4,r4
	mov	r9,r5
	mov	r8,r6
	mov	r7,0
	adc	r7,r7
	gosub	put_pixel
	inc	r6
	; pattern <<= 1; put_pixel(y, x++, carry)
	add	r4,r4
	mov	r9,r5
	mov	r8,r6
	mov	r7,0
	adc	r7,r7
	gosub	put_pixel
	ret	r0,0

; Digits are drawn "sideways" (landscape mode)
; the first three nibbles of each digit are the top half of the drawing
digit_0:
; Top half of digit (drawn on page)
nibble 0b1100 
nibble 0b0100
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0111
nibble 0b0100
nibble 0b0111

digit_1:
; Top half of digit (drawn on page)
nibble 0b0000
nibble 0b0000
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0000
nibble 0b0000
nibble 0b0111

digit_2:
; Top half of digit (drawn on page)
nibble 0b0100
nibble 0b0100
nibble 0b1000
; bottom half of digit (drawn on page+1):
nibble 0b0110
nibble 0b0101
nibble 0b0100

digit_3:
; Top half of digit (drawn on page)
nibble 0b0100
nibble 0b0100
nibble 0b1000
; bottom half of digit (drawn on page+1):
nibble 0b0100
nibble 0b0101
nibble 0b0010

digit_4:
; Top half of digit (drawn on page)
nibble 0b0000
nibble 0b1000
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0011
nibble 0b0010
nibble 0b0111

digit_5:
; Top half of digit (drawn on page)
nibble 0b1100
nibble 0b0100
nibble 0b0100
; bottom half of digit (drawn on page+1):
nibble 0b0101
nibble 0b0101
nibble 0b0111

digit_6:
; Top half of digit (drawn on page)
nibble 0b1100
nibble 0b0100
nibble 0b0100
; bottom half of digit (drawn on page+1):
nibble 0b0111
nibble 0b0101
nibble 0b0111

digit_7:
; Top half of digit (drawn on page)
nibble 0b0100
nibble 0b0100
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0000
nibble 0b0111
nibble 0b0000

digit_8:
; Top half of digit (drawn on page)
nibble 0b1100
nibble 0b0100
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0111
nibble 0b0101
nibble 0b0111

digit_9:
; Top half of digit (drawn on page)
nibble 0b1100
nibble 0b0100
nibble 0b1100
; bottom half of digit (drawn on page+1):
nibble 0b0101
nibble 0b0101
nibble 0b0111

;; clear_screen
;;
;; Preserves: r4, r5.
clear_screen:
	; ptr (r8:r9) = Page:0
	; page_cnt (r7) = 2
	; addr_cnd (r7) = 0 ; will loop 16 iterations
	; pattern (r0)
	mov	r0,[Page]
	mov	r8,r0
	mov	r0,0
	mov	r9,0
	mov	r7,2
; loop_pages:
	mov	r6,0
; loop_addrs:
	; *ptr++ = pattern
	mov	[r8:r9],r0
	inc	r9
	dsz	r6
	jr	-4
; Advance to the next page.
	inc	r8
	dsz	r7
	jr	-8
	ret	r0,0

;; put_pixel(r9=y, r8=c, r7=c)
;;
;; Preserves: r4, r5, r6.
put_pixel:
	and	r7,r7
	skip	z,2
	goto	set_pixel
	; fall through to clear_pixel

;; clear_pixel(r9=y, r8=x)
;;
;; Preserves: r4, r5, r6.
clear_pixel:
	gosub	get_screen_addr
	; mem[r8:r9] &= ~r7
	mov	r0,0xf
	xor	r7,r0
	mov	r0,[r8:r9]
	and	r0,r7
	mov	[r8:r9],r0
	ret	r0,0

;; set_pixel(r9=y, r8=x)
;;
;; Preserves: r4, r5, r6.
set_pixel:
	gosub	get_screen_addr
	; mem[r8:r9] |= r7
	mov	r0,[r8:r9]
	or	r0,r7
	mov	[r8:r9],r0
	ret	r0,0

;; get_pixel(r9=y, r8=x) -> r0
;;
;; Preserves: r4, r5, r6.
get_pixel:
	gosub	get_screen_addr
	; return (mem[r8:r9] & r7) ? 1 : 0
	mov	r0,[r8:r9]
	and	r0,r7
	skip	z,1
	ret	r0,1
	ret	r0,0

;; get_screen_addr(r9=y, r8=x) -> r8:r9=addr r7=mask
;;
;; Preserves: r4, r5, r6.
;;
;; Checks that x,y are valid coordinates and returns the memory address and
;; a mask for the requested pixel.
;;
;; Converting from x,y to a memory address is done as follows:
;;
;; 1. Memory addresses increase from left to right on the badge matrix.
;;    To achieve a coordinate system with 0,0 in the top-right corner, compute:
;;    x = 7 - x
;;
;; 2. Looking at the bit representations, the return values are as follows:
;;    0xxx yyyy
;;     |\| \__|
;;     | \    \_ row_offset
;;     |  \_____ bit_shift
;;     \________ page_offset
;;    mask = 1 << bit_offset
;;    addr_low = row_offset
;;    addr_high = Page + page_offset
;;
;; 3. After adding logic to extract the bits from x and y, here is the formula
;;    for each output register:
;;    addr_low = y
;;    addr_high = Page + (((7 - x) & 4) != 0)
;;    mask = 1 << ((7 - x) & 3)
get_screen_addr:
; Validate x coordinate (must be less than or equal to 7).
	; r7 = 0x7 - x
	mov	r7,0x7
	sub	r7,r8
	skip	c,2	; gosub is two instructions
	gosub	oob_err
	; r8 = Page + ((r7 & 0x4) != 0)
	mov	r0,r7
	and	r0,0x4	; used only for side effect on zero flag
	mov	r0,[Page]
	mov	r8,r0
	skip	z,1
	inc	r8
	; r0 = r7 & 0x3
	mov	r0,r7
	and	r0,0x3
	; r7 = 1 << r0
	mov	r7,1
	and	r0,r0	; loop only if r1 non-zero
	skip	z,3
; loop:
	add	r7,r7	; shift left
	dsz	r0
	jr	-3
; ret:
	ret	r0,0
oob_err:
	gosub	oob_err	; Trigger stack overflow.
