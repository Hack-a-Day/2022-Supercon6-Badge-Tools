;; snake.asm - Implementation of Snake for Voja's 4-bit processor.
;;
;; Copyright (c) 2022 Octavian Voicu
;;
;; For some functions that may be easily reusable in other projects, see the
;; "General Purpose Library" section.

; Constants/parameters.
screen_page	EQU	0x2	; memory page for the screen
start_x		EQU	3	; initial position of the last tail element
start_y		EQU	10
start_len	EQU	3	; initial length (head plus tail)
start_dir	EQU	0	; initial direction is up (see delta_position)
start_sync	EQU	11	; sync period for easiest difficulty
max_difficulty	EQU	8	; highest difficulty level
max_score	EQU	128 - start_len	; screen has 16*8=128 pixels

; Global variables.
; These point to memory addresses where data is stored.
food_y		EQU	0x47	; food position
food_x		EQU	0x48
dir		EQU	0x49	; current direction
new_dir		EQU	0x4a	; new direction
difficulty	EQU	0x4b	; current difficulty
score		EQU	0x4c	; size 2; score
snake_buf	EQU	0x50	; aligned to 4; buffer for snake data structure

;;;;
;;;; Game loop.
;;;;

main:
	mov	r0,screen_page
	mov	[Page],r0
	mov	r0,1		; Clock = 100 KHz
	mov	[Clock],r0

new_game:
	mov	r0,start_dir
	mov	[dir],r0
	mov	[new_dir],r0
	mov	r0,0
	mov	[difficulty],r0
	mov	[score],r0
	mov	[score+1],r0
	gosub	update_speed
	mov	r9,0
	gosub	clear_screen
	gosub	init_snake
	gosub	spawn_food

game_loop:
	gosub	process_input

	gosub	advance_to_new_pos
	cp	r0,1
	skip	z,2
	goto	game_over

	gosub	wait_for_sync
	goto	game_loop

game_over:
	gosub	die_animation
	gosub	wait_key_press
	goto	new_game

;;;;
;;;; Complex functions that operate on globals.
;;;; These call other functions and use exr, so care must be taken if calling
;;;; from another function that uses exr.
;;;;

;; init_snake()
;;
;; Uses exr.
;;
;; Initializes and draws the snake in the starting configuration.
init_snake:
	exr	4
	; r1, r2, r3 = start_y, start_x, start_len - 1
	mov	r1,start_y
	mov	r2,start_x
	mov	r3,start_len - 1	; Subtract one to account for the head.
	; snake_init(snake_buf, r1, r2)
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	mov	r7,r1
	mov	r6,r2
	gosub	snake_init
	; set_pixel(r1, r2)
	mov	r9,r1
	mov	r8,r2
	gosub	set_pixel
; loop:
	; r1, r2 = delta_position(r1, r2, start_dir)
	mov	r9,r1
	mov	r8,r2
	mov	r7,start_dir
	gosub	delta_position
	mov	r1,r9
	mov	r2,r8
	; snake_add_head(snake_buf, r1, r2)
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	mov	r7,r1
	mov	r6,r2
	gosub	snake_add_head
	; set_pixel(r1, r2)
	mov	r9,r1
	mov	r8,r2
	gosub	set_pixel
	dsz	r3
	jr	-19
	exr	4
	ret	r0,0

;; spawn_food()
;;
;; Uses exr.
;;
;; Finds an empty location and places the food there.
spawn_food:
	exr	3
; loop:
	; get_random_position() -> y, x
	gosub	get_random_position
	mov	r1,r9
	mov	r2,r8
        ; snake_find(snake_buf, y, x)
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	mov	r7,r1
	mov	r6,r2
	gosub	snake_find
	cp	r0,1
	skip	nz,1
	jr	-13
; Found empty location.
	; food_y, food_x = y, x
	mov	r0,r1
	mov	[food_y],r0
	mov	r0,r2
	mov	[food_x],r0
	mov	r9,r1
	mov	r8,r2
	exr	3
	; set_pixel(y, x)
	goto	set_pixel	; tail call

;; advance_to_new_pos() -> r0=success
;;
;; Uses exr.
;;
;; The heart of moving the snake. Computes the new position based on current
;; direction, checks for collisions, moves head to new pos, consumes food if
;; any (and updates score), or erases the tail otherwise. Returns 0 iff
;; there was a collision or the player won (max score), or 0 otherwise.
advance_to_new_pos:
; Get new position.
	; snake_head(snake) -> head_y, head_x
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_head
	; delta_position(head_y, head_x, new_dir)
	mov	r0,[new_dir]
	mov	r7,r0
	gosub	delta_position
; Check out-of-bounds.
	cp	r0,1
	skip	z,2
	ret	r0,0
	exr	3
	; dir = new_dir
	mov	r0,[new_dir]
	mov	[dir],r0
	mov	r1,r9
	mov	r2,r8
; Check self collision.
        ; snake_find()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	mov	r7,r1
	mov	r6,r2
	gosub	snake_find
	cp	r0,0
	skip	z,2
	exr	3
	ret	r0,0
; Advance.
	mov	r9,r1
	mov	r8,r2
	gosub	move_head
	mov	r9,r1
	mov	r8,r2
	exr	3
; Check if new position has food.
	gosub	is_food
	cp	r0,1
	skip	z,3
; No food, erase tail.
	gosub	erase_tail
	ret	r0,1
; Yes food, increment score, check for win condition, and spawn new food.
	gosub	increment_score
	cp	r0,1
	skip	z,1
	ret	r0,0
	gosub	spawn_food
	ret	r0,1

;; die_animation()
;;
;; Uses exr.
;;
;; Fades the snake and food away at the end of the game, and draws the final score.
die_animation:
	gosub	user_sync
	; Clear tail.
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_len
	and	r9,r9
	skip	nz,3
	and	r8,r8
	skip	nz,1
	jr	5
	gosub	blink_tail
	gosub	erase_tail
	jr	-14
	; Clear head.
	gosub	user_sync
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_head
	gosub	clear_pixel
	; Clear food.
	gosub	user_sync
	mov	r0,[food_y]
	mov	r9,r0
	mov	r0,[food_x]
	mov	r8,r0
	gosub	clear_pixel
	mov	r9,5
	; Draw score.
	gosub	user_sync
	dsz	r9
	jr	-4
	mov	r0,[score]
	mov	r9,r0
	mov	r0,[score+1]
	mov	r8,r0
	goto	draw_score	; tail call

;; draw_score(r8:r9=score)
;;
;; Uses exr.
;;
;; Draws the final score. It's drawn on two rows, hundreds on the first row
;; (right justified), and tens and units on the second row.
draw_score:
	gosub	byte_to_base10
	exr	3
	mov	r1,r8
	mov	r2,r7
; Display hundreds.
	mov	r8,2
	mov	r7,5
	gosub	draw_digit
; Display tens.
	mov	r9,r1
	mov	r8,9
	mov	r7,0
	gosub	draw_digit
; Display units.
	mov	r9,r2
	mov	r8,9
	mov	r7,5
	gosub	draw_digit
	exr	3
	ret	r0,0

;;;;
;;;; Simple functions that operate on globals.
;;;; These call other functions, but have less restrictions on how they can be
;;;; used (e.g. they don't use exr).
;;;;

;; process_input()
;;
;; Checks if any key was pressed and updates the direction iff the new
;; direction is perpendicular to the old one. This ensures that the snake
;; doesn't attempt an 180, which would end the game.
process_input:
; Check for key presses.
	gosub	get_dir_key
	cp	r0,0xf
	skip	nz,1
	ret	r0,0
; Check if new direction is perpendicular to the old one.
	mov	r9,r0
	mov	r0,[dir]
	xor	r0,r9
	bit	r0,0
	skip	z,2
; Store new direction.
	mov	r0,r9
	mov	[new_dir],r0
	ret	r0,0

;; increment_score() -> r0=ok
;;
;; Increments the score. For every 16 points, increases the difficulty.
;; Returns 1 iff the game is not won, or 0 otherwise.
increment_score:
; Get current score.
	mov	r0,[score]
	mov	r9,r0
	mov	r0,[score+1]
	mov	r8,r0
; Increment score.
	inc	r9
	mov	r0,r9
	mov	[score],r0
	skip	nc,4
; Carry from the lowest nibble. Also increase difficulty.
	inc	r8
	mov	r0,r8
	mov	[score+1],r0
	gosub	increase_difficulty
; Check for win condition score == max_score.
	mov	r0,r9
	cp	r0,low max_score
	skip	z,1
	ret	r0,1
	mov	r0,r8
	cp	r0,mid max_score
	skip	z,1
	ret	r0,1
	; PLAYER WON! No empty squares left on the screen.
	ret	r0,0

;; increase_difficulty()
;;
;; Increments the difficulty parameter up to max_difficulty, and updates the
;; game speed.
increase_difficulty:
	mov	r0,[difficulty]
	cp	r0,max_difficulty
	skip	z,4
	inc	r0
	mov	[difficulty],r0
	goto	update_speed		; tail call

;; update_speed()
;;
;; Adjusts the speed of the game depending on the current difficulty.
update_speed:
	mov	r0,[difficulty]
	mov	r9,r0
	mov	r0,start_sync
	sub	r0,r9
	mov	[Sync],r0
	ret	r0,0

;; is_food(r9=y, r8=x) -> r0=is_food
;;
;; Returns true iff coordinates y, x represent the current food location.
is_food:
	mov	r0,[food_y]
	sub	r0,r9
	skip	z,1
	ret	r0,0
	mov	r0,[food_x]
	sub	r0,r8
	skip	z,1
	ret	r0,0
	ret	r0,1

;; move_head(r9=y, r8=x)
;;
;; Moves the head to a new position, shifting the old head to the tail, and
;; draws it.
move_head:
	; snake_add_head()
	mov	r7,r9
	mov	r6,r8
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_add_head
	; snake_head()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_head
	; set_pixel()
	goto	set_pixel		; tail call

;; erase_tail()
;;
;; Removes and rrases the last element of the tail.
erase_tail:
	; snake_tail()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_tail
	; clear_pixel()
	gosub	clear_pixel
	; snake_remove_tail()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	goto	snake_remove_tail	; tail call

;; blink_tail()
;;
;; Erases and redraws the last element of the tail.
blink_tail:
	; snake_tail()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_tail
	; clear_pixel()
	gosub	clear_pixel
	gosub	user_sync
	; snake_tail()
	mov	r9,low snake_buf
	mov	r8,mid snake_buf
	gosub	snake_tail
	; set_pixel()
	gosub	set_pixel
	ret	r0,0

;; wait_for_sync()
;;
;; Flashes food using two syncs.
wait_for_sync:
	mov	r0,[food_y]
	mov	r6,r0
	mov	r0,[food_x]
	mov	r5,r0
; loop:
	; clear_pixel(food_y, food_x)
	mov	r9,r6
	mov	r8,r5
	gosub	clear_pixel
	; user_sync()
	gosub	user_sync
	; set_pixel(food_y, food_x)
	mov	r9,r6
	mov	r8,r5
	gosub	set_pixel
	; user_sync()
	gosub	user_sync
	ret	r0,0

;;;;
;;;; Functions that operate on the the snake data structure passed as a param.
;;;; These don't use globals, don't call other functions, and don't use exr.
;;;;

;; snake_init(r8:r9=snake, r7=head_y, r6=head_x)
;;
;; Initializes the snake data structure.
;; The address of the snake buffer must be a multiple of four. This simplifies
;; accessing the head location and tail length as it guarantees they will always
;; be on the same memory page.
;;
;; Buffer structure:
;;   head_y head_x len_low len_high tail0 tail1 ...
;; Length represents the number of tail elements not including the head.
;; Each tail element is a nibble with two low bits for dy and two high bits for
;; dx encoded as a signed integer in two's complement. This efficient encoding
;; is required to allow a perfect game in which tail has about 16*8 elements
;; (would need 16 pages if using two nibbles per element to hold full position).
snake_init:
	; snake.head_y = head_y
	mov	r0,r7
	mov	[r8:r9],r0
	inc	r9
	; snake.head_x = head_x
	mov	r0,r6
	mov	[r8:r9],r0
	inc	r9
	; snake.len = 0
	mov	r0,0
	mov	[r8:r9],r0
	inc	r9
	mov	[r8:r9],r0
	ret	r0,0

;; snake_len(r8:r9=snake) -> r8:r9=len
;;
;; Returns the length of the tail (excluding the head).
snake_len:
	mov	r7,r9
	mov	r6,r8
	mov	r0,2
	add	r7,r0
	; r8:r9 = snake.len
	mov	r0,[r6:r7]
	mov	r9,r0
	inc	r7
	mov	r0,[r6:r7]
	mov	r8,r0
	ret	r0,0

;; snake_head(r8:r9=snake) -> r9=head_y r8=head_x
;;
;; Returns the coordinates of the head.
snake_head:
	mov	r7,r9
	mov	r6,r8
	; r9 = snake.head_y
	mov	r0,[r6:r7]
	mov	r9,r0
	inc	r7
	; r8 = snake.head_x
	mov	r0,[r6:r7]
	mov	r8,r0
	ret	r0,0

;; snake_tail(r8:r9=snake) -> r9=tail_y r8=tail_x
;;
;; Returns the coordinates of the last element of the tail.
snake_tail:
	; buf (r6:r7) = snake
	mov	r7,r9
	mov	r6,r8
	; tail_y (r9) = snake.head_y
	mov	r0,[r6:r7]
	mov	r9,r0
	inc	r7
	; tail_x (r8) = snake.head_x
	mov	r0,[r6:r7]
	mov	r8,r0
	inc	r7
	; len (r5:r4) = snake.len
	mov	r0,[r6:r7]
	mov	r5,r0
	inc	r7
	mov	r0,[r6:r7]
	mov	r4,r0
	; if (!len) skip loop
	and	r5,r5
	skip	nz,3
	and	r4,r4
	skip	nz,1
	jr	28
	; buf (r6:r7) now points to the memory location before the tail.
; loop:
	; r0 = *++buf
	inc	r7
	skip	nc,1
	inc	r6
	mov	r0,[r6:r7]
; Update tail_y.
	bit	r0,0
	skip	nz,1
	jr	5
; dy_non_zero:
	bit	r0,1
	skip	z,2
; dy_minus_one:
	dec	r9
	jr	1
; dy_plus_one:
	inc	r9
; Update tail_x.
	bit	r0,2
	skip	nz,1
	jr	5
; dx_non_zero:
	bit	r0,3
	skip	z,2
; dx_minus_one:
	dec	r8
	jr	1
; dx_plus_one:
	inc	r8
; If not end of tail, repeat.
	dec	r5
	skip	nz,3
	and	r4,r4
	skip	nz,1
	jr	3
	skip	c,1
	dec	r4
	jr	-28
	ret	r0,0

;; snake_find(r8:r9=snake, r7=y, r6=x) -> r0=found
;;
;; Returns 1 if the given coordinates are part of the head or tail.
snake_find:
	; y (r7) -= snake.head_y
	mov	r0,[r8:r9]
	sub	r0,r7
	mov	r7,r0
	inc	r9
	; x (r6) -= snake.head_x
	mov	r0,[r8:r9]
	sub	r0,r6
	mov	r6,r0
	inc	r9
; Check if it's the head.
	and	r7,r7
	skip	nz,3
	and	r6,r6
	skip	nz,1
	ret	r0,1
	; len (r4:r5) = snake.len
	mov	r0,[r8:r9]
	mov	r5,r0
	inc	r9
	mov	r0,[r8:r9]
	mov	r4,r0
	; if (!len) skip loop
	and	r5,r5
	skip	nz,3
	and	r4,r4
	skip	nz,1
	jr	33
	; buf (r8:r9) now points to the memory location before the tail.
; loop:
	; r0 = *++buf
	inc	r9
	skip	nc,1
	inc	r8
	mov	r0,[r8:r9]
	; Process dy.
	bit	r0,0
	skip	nz,1
	jr	5
; dy_non_zero:
	bit	r0,1
	skip	z,2
; dy_minus_one:
	dec	r7
	jr	1
; dy_plus_one:
	inc	r7
; Process dx.
	bit	r0,2
	skip	nz,1
	jr	5
; dx_non_zero:
	bit	r0,3
	skip	z,2
; dx_minus_one:
	dec	r6
	jr	1
; dx_plus_one:
	inc	r6
; Check if found.
	and	r7,r7
	skip	nz,3
	and	r6,r6
	skip	nz,1
; Found.
	ret	r0,1
; If not end of tail, repeat.
	dec	r5
	skip	nz,3
	and	r4,r4
	skip	nz,1
	jr	3
	skip	c,1
	dec	r4
	jr	-33
; Not found.
	ret	r0,0

;; snake_add_head(r8:r9=snake, r7=y, r6=x)
;;
;; Sets a new head, adding the old one to the tail.
snake_add_head:
	; prev_tail (r5) = (snake.head_y - y) & 0x3
	mov	r0,[r8:r9]
	sub	r0,r7
	and	r0,0x3
	mov	r5,r0
	; snake.head_y = y
	mov	r0,r7
	mov	[r8:r9],r0
	inc	r9
	; prev_tail |= (snake.head_x - x) << 2
	mov	r0,[r8:r9]
	sub	r0,r6
	add	r0,r0
	add	r0,r0
	or	r5,r0
	; snake.head_x = x
	mov	r0,r6
	mov	[r8:r9],r0
	inc	r9
	; len (r6:r7) = snake.len++
	mov	r0,[r8:r9]
	inc	r0
	mov	[r8:r9],r0
	mov	r7,r0
	skip	c,3
	inc	r9
	mov	r0,[r8:r9]
	jr	3
	inc	r9
	mov	r0,[r8:r9]
	inc	r0
	mov	[r8:r9],r0
	mov	r6,r0
	; if (!len) skip loop
	and	r7,r7
	skip	nz,3
	and	r6,r6
	skip	nz,1
	jr	16
	; buf (r8:r9) now points to the memory location before the tail.
; loop:
	; r4 (next_tail) = *++buf
	inc	r9
	skip	nc,1
	inc	r8
	mov	r0,[r8:r9]
	mov	r4,r0
	; *buf = r5
	mov	r0,r5
	mov	[r8:r9],r0
	; r5 = r4
	mov	r5, r4
	; len--
	dec	r7
	skip	nz,3
	and	r6,r6
	skip	nz,1
	jr	3
	skip	c,1
	dec	r6
	jr	-16
; end:
	; *++buf = r5
	inc	r9
	skip	nc,1
	inc	r8
	mov	r0,r5
	mov	[r8:r9],r0
	ret	r0,0

;; snake_remove_tail(r8:r9=snake)
;;
;; Removes the last element from the tail.
snake_remove_tail:
	inc	r9
	inc	r9
	; len (r6:r7) = snake.len
	mov	r0,[r8:r9]
	mov	r7,r0
	inc	r9
	mov	r0,[r8:r9]
	mov	r6,r0
	; len--
	dec	r7
	skip	c,1
	dec	r6
	; snake.len = len
	mov	r0,r6
	mov	[r8:r9],r0
	dec	r9
	mov	r0,r7
	mov	[r8:r9],r0
	ret	r0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;                                                                        ;;;;
;;;;                        General Purpose Library                         ;;;;
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
;;

;; Register definitions.
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
key_left	EQU	9	; operand y 8
key_up		EQU	10	; operand y 4
key_down	EQU	11	; operand y 2
key_right	EQU	12	; operand y 1

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
	cp	r0,key_up
	skip	nz,1
	ret	r0,0	; up
	cp	r0,key_left
	skip	nz,1
	ret	r0,1	; left
	cp	r0,key_down
	skip	nz,1
	ret	r0,2	; down
	cp	r0,key_right
	skip	nz,1
	ret	r0,3	; right
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

;; Global storage for digit drawing functionality.
;; These can be moved to other memory locations if there are conflicts.
digit_buf	EQU	0xd8	; buffer of size 5; must fit within a single page
digit_y		EQU	0xdd
digit_x		EQU	0xde

;; draw_digit(r9=digit, r8=y, r7=x)
;;
;; Draws a 3x5 digit at y, x coordinates.
;; Uses digit_buf, digit_y, and digit_x globals.
;; The buffer must be fully contained within a page.
draw_digit:
; Store target coordinates.
	mov	r0,r8
	mov	[digit_y],r0
	mov	r0,r7
	mov	[digit_x],r0
; Skip to the right digit.
	gosub	digit_0
	mov	r7,jsr
	mov	r6,5
	mov	r0,0
	inc	r9
	jr	3
; loop:
	add	r7,r6
	adc	pcm,r0
	adc	pch,r0
	dsz	r9
	jr	-5
; Now copy each line to the buffer.
	mov	r9,low digit_buf
	mov	r8,mid digit_buf
	mov	jsr,r7
	mov	[r8:r9],r0
	mov	r6,4
; loop:
	inc	r9
	mov	r0,0
	inc	r7
	adc	pcm,r0
	adc	pch,r0
	mov	jsr,r7
	mov	[r8:r9],r0
	dsz	r6
	jr	-9
; Finally draw each line.
	; draw_digit_line(digit_buf, digit_y++, digit_x)
	mov	r0,[digit_buf]
	mov	r9,r0
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,[digit_x]
	mov	r7,r0
	gosub	draw_digit_line
	; draw_digit_line(digit_buf + 1, digit_y++, digit_x)
	mov	r0,[digit_buf+1]
	mov	r9,r0
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,[digit_x]
	mov	r7,r0
	gosub	draw_digit_line
	; draw_digit_line(digit_buf + 2, digit_y++, digit_x)
	mov	r0,[digit_buf+2]
	mov	r9,r0
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,[digit_x]
	mov	r7,r0
	gosub	draw_digit_line
	; draw_digit_line(digit_buf + 3, digit_y++, digit_x)
	mov	r0,[digit_buf+3]
	mov	r9,r0
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,[digit_x]
	mov	r7,r0
	gosub	draw_digit_line
	; draw_digit_line(digit_buf + 4, digit_y, digit_x)
	mov	r0,[digit_buf+4]
	mov	r9,r0
	mov	r0,[digit_y]
	mov	r8,r0
	inc	r0
	mov	[digit_y],r0
	mov	r0,[digit_x]
	mov	r7,r0
	gosub	draw_digit_line
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

digit_0:
nibble 0b0111
nibble 0b0101
nibble 0b0101
nibble 0b0101
nibble 0b0111

digit_1:
nibble 0b0001
nibble 0b0001
nibble 0b0001
nibble 0b0001
nibble 0b0001

digit_2:
nibble 0b0110
nibble 0b0001
nibble 0b0010
nibble 0b0100
nibble 0b0111

digit_3:
nibble 0b0110
nibble 0b0001
nibble 0b0010
nibble 0b0001
nibble 0b0110

digit_4:
nibble 0b0001
nibble 0b0011
nibble 0b0101
nibble 0b0111
nibble 0b0001

digit_5:
nibble 0b0111
nibble 0b0100
nibble 0b0111
nibble 0b0001
nibble 0b0111

digit_6:
nibble 0b0111
nibble 0b0100
nibble 0b0111
nibble 0b0101
nibble 0b0111

digit_7:
nibble 0b0111
nibble 0b0001
nibble 0b0010
nibble 0b0010
nibble 0b0010

digit_8:
nibble 0b0111
nibble 0b0101
nibble 0b0111
nibble 0b0101
nibble 0b0111

digit_9:
nibble 0b0111
nibble 0b0101
nibble 0b0111
nibble 0b0001
nibble 0b0111

;; clear_screen(r9=pattern)
;;
;; Preserves: r4, r5.
clear_screen:
	; ptr (r8:r9) = Page:0
	; page_cnt (r7) = 2
	; addr_cnd (r7) = 0 ; will loop 16 iterations
	; pattern (r0)
	mov	r0,[Page]
	mov	r8,r0
	mov	r0,r9
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
