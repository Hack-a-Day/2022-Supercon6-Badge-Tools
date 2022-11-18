; Tertis (not Tetris), by @koppanyh (Tetris Guy)
; Written by hand on paper, manually entered in with the buttons, and tested/debugged on the badge.
; Copied into this file for distribution. No optimizations were made. There may be bugs...


; Init
; Set up the display, clock, and timer. Then jump to main game loop.
; Params: none
; Returns: none
; Registers: R0, PCH, PCM, PCL
; Stored in 0x000 - 0x00f, 8 instructions long
init:
mov r0, 0xC  ; display page 0xC
mov [0xF0], r0
mov r0, 0x0  ; run at max clock
mov [0xF1], r0
mov r0, 0xC  ; use 250ms timer
mov [0xF2], r0
goto main
; Signature: koppanyh (view in hex editor)
mov pc, [0x6:0xB]
mov pc, [0x6:0xF]
mov pc, [0x7:0x0]
mov pc, [0x7:0x0]
mov pc, [0x6:0x1]
mov pc, [0x6:0xE]
mov pc, [0x7:0x9]
mov pc, [0x6:0x8]


; Setpix
; Set the value of a specific pixel in the C&D pages by its x-y coordinate.
; Params: R1 - x, R2 - y, R3 - value
; Returns: none
; Registers: R0, R1, *R2, *R3, R4, R5, PCH, PCM, JSR
; Stored in 0x010 - 0x03F, 28 instructions long
org 0x010
setpix:
mov r4, 12
bit r1, 2
skip z, 1
mov r4, 13
mov r5, 3
and r1, r5
mov r5, 8
add r1, r5
mov pc, [0x0:0x2]
mov jsr, r1
mov r1, r0
mov r0, r3
cp r0, 0
mov r0, [r4:r2]
skip z, 1
jr 5
mov r5, 15
xor r1, r5
and r0, r1
mov [r4:r2], r0
ret r0, 0
or r0, r1
mov [r4:r2], r0
ret r0, 0
; this lookup table has to be at 0x028, other subroutines depend on it too
nibble 0b0001
nibble 0b0010
nibble 0b0100
nibble 0b1000


; Draw
; Draw the 4 x-y coordinate pairs with a specifi value. Coordinates stored starting at 0xB0 onward.
; Params: R3 - value
; Returns: none
; Registers: R0, R1, R2, *R3, PCH, PCM, JSR, <registers from setpix>
; Stored in 0x040 - 0x06f, 25 instructions long
org 0x040
draw:
mov r0, [0xB0]
mov r1, r0
mov r0, [0xB1]
mov r2, r0
gosub setpix
mov r0, [0xB2]
mov r1, r0
mov r0, [0xB3]
mov r2, r0
gosub setpix
mov r0, [0xB4]
mov r1, r0
mov r0, [0xB5]
mov r2, r0
gosub setpix
mov r0, [0xB6]
mov r1, r0
mov r0, [0xB7]
mov r2, r0
gosub setpix
ret r0, 0


; Spawn
; Set the 4 x-y coordinate pairs at 0xB0 with the coordinates for the specified tetromino.
; Params: R1 - tetromino
; Returns: spawned tetromino's number
; Registers: R0, *R1
; Stored in 0x070 - 0x0FF, 123 instructions long
org 0x070
spawn:
; the first coord is always (4, 0) for all tetrominoes. that's their rotation point
mov r0, 4
mov [0xB0], r0
mov r0, 0
mov [0xB1], r0
; tetromino 0, the L
mov r0, r1
cp r0, 0
skip z, 1
jr 13
mov r0, 5
mov [0xB2], r0
mov r0, 0
mov [0xB3], r0
mov r0, 5
mov [0xB4], r0
mov r0, 1
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 0
mov [0xB7], r0
ret r0, 0
; tetromino 1, the J
mov r0, r1
cp r0, 1
skip z, 1
jr 13
mov r0, 5
mov [0xB2], r0
mov r0, 0
mov [0xB3], r0
mov r0, 3
mov [0xB4], r0
mov r0, 0
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 1
mov [0xB7], r0
ret r0, 1
; tetromino 2, the T
mov r0, r1
cp r0, 2
skip z, 1
jr 13
mov r0, 5
mov [0xB2], r0
mov r0, 0
mov [0xB3], r0
mov r0, 4
mov [0xB4], r0
mov r0, 1
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 0
mov [0xB7], r0
ret r0, 2
; tetromino 3, the S
mov r0, r1
cp r0, 3
skip z, 1
jr 13
mov r0, 5
mov [0xB2], r0
mov r0, 1
mov [0xB3], r0
mov r0, 4
mov [0xB4], r0
mov r0, 1
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 0
mov [0xB7], r0
ret r0, 3
; tetromino 4, the Z
mov r0, r1
cp r0, 4
skip z, 1
jr 13
mov r0, 5
mov [0xB2], r0
mov r0, 0
mov [0xB3], r0
mov r0, 4
mov [0xB4], r0
mov r0, 1
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 1
mov [0xB7], r0
ret r0, 4
; tetromino 5, the O
mov r0, r1
cp r0, 5
skip z, 1
jr 13
mov r0, 4
mov [0xB2], r0
mov r0, 1
mov [0xB3], r0
mov r0, 3
mov [0xB4], r0
mov r0, 0
mov [0xB5], r0
mov r0, 3
mov [0xB6], r0
mov r0, 1
mov [0xB7], r0
ret r0, 5
; tetromino 6, the I
mov r0, r1
cp r0, 6
skip z, 1
jr 0  ; points to itself as default
mov r0, 5
mov [0xB2], r0
mov r0, 0
mov [0xB3], r0
mov r0, 3
mov [0xB4], r0
mov r0, 0
mov [0xB5], r0
mov r0, 2
mov [0xB6], r0
mov r0, 0
mov [0xB7], r0
ret r0, 6


; Rotate
; Rotates the tetromino coordinates around the first x-y coordinate pair in the specified direction.
; Params: R7 - direction
; Returns: none
; Registers: R0, R1, R2, R3, R4, R5, R6, *R7, PCH, PCM, JSR, <registers from normalize>
; Stored in 0x100 - 0x13F, 38 instructions long
org 0x100
rotate:
mov r0, [0xB0]
mov r1, r0
mov r0, [0xB1]
mov r2, r0
mov r3, 0xB
mov r4, 6
mov r0, [r3:r4]
mov r5, r0
inc r4
mov r0, [r3:r4]
mov r6, r0
sub r5, r1
sub r6, r2
mov r0, r7
cp r0, 0
mov r0, 0
skip z, 1
jr 4
sub r0, r5
mov r5, r6
mov r6, r0
jr 3
sub r0, r6
mov r6, r5
mov r5, r0
add r5, r1
add r6, r2
mov r0, r6
mov [r3:r4], r0
dec r4
mov r0, r5
mov [r3:r4], r0
dec r4
dsz r4
jr -29
gosub normalize
ret r0, 0


; Translate
; Translates the tetromino coordinates by the specified x-y values.
; Params: R1 - x, R2 - y
; Returns: none
; Registers: R0, *R1, *R2, R3, R4, PCH, PCM, JSR, <registers from normalize>
; Stored in 0x140 - 0x16F, 17 instructions long
org 0x140
translate:
mov r3, 0xB
mov r4, 0
mov r0, [r3:r4]
add r0, r1
mov [r3:r4], r0
inc r4
mov r0, [r3:r4]
add r0, r2
mov [r3:r4], r0
inc r4
mov r0, r4
cp r0, 8
skip z, 1
jr -12
gosub normalize
ret r0, 0


; Normalize
; Normalizes the x-y coordinates so they wrap around the screen in the event of under/overflow.
; Params: none
; Returns: none
; Registers: R0, R1, R2
; Stored in 0x170 - 0x18F, 12 instructions long
org 0x170
normalize:
ret r0, 0  ; change this line to `mov r1, 0xB` if you want to clip through walls
mov r2, 0
mov r0, [r1:r2]
bclr r0, 3
mov [r1:r2], r0
inc r2
inc r2
mov r0, r2
cp r0, 8
skip z, 1
jr -9
ret r0, 0


; Collision
; Checks if any of the x-y coordinate pairs are colliding with other blocks, the walls, or the floor.
; Params: none
; Returns: 0 for no collision, 1 for floor, 2 for block, 3 for walls
; Registers: R0, R1, R2, R3, R4, R5, R6
; Stored in 0x190 - 0x1CF, 38 instructions long
org 0x190
collision:
mov r1, 0xB
mov r2, 0
mov r0, [r1:r2]
mov r3, r0
inc r2
mov r0, r3
bit r0, 3
skip z, 1
ret r0, 3  ; wall collision detected
mov r0, [r1:r2]
mov r4, r0
inc r2
mov r0, r4
cp r0, 0xF
skip nz, 1
ret r0, 1  ; floor collision detected
mov r5, 0xC
mov r0, r3
bit r0, 2
skip z, 1
mov r5, 0xD
mov r6, 3
and r3, r6
mov r6, 8
add r3, r6
mov pc, [0x0:0x2]
mov jsr, r3
mov r3, r0
mov r0, [r5:r4]
and r0, r3
cp r0, 0
skip z, 1
ret r0, 2  ; block collision detected
mov r0, r2
cp r0, 8
skip z, 1
jr -35
ret r0, 0  ; no collision detected


; Key Wait
; Delay to slow down game execution and check for user input. User input will rotate/translate active tetromino here.
; Params: none
; Returns: none
; Registers: R0, R1, R2, R3, R7, <registers from draw, rotate, translate, and collision>
; Stored in 0x1D0 - 0x22F, 65 instructions long
org 0x1D0
keywait:
mov r0, [0xFC]
bit r0, 0
skip nz, 1
jr 55
mov r3, 0
gosub draw
; mode key pressed for rotate
mov r0, [0xFD]
cp r0, 0
skip z, 1
jr 11
mov r7, 0
gosub rotate
gosub collision
cp r0, 0  ; undo if collision detected
skip nz, 1
jr 3
mov r7, 1
gosub rotate
; op-y-2 key pressed for move left
mov r0, [0xFD]
cp r0, 11
skip z, 1
jr 13
mov r1, 1
mov r2, 0
gosub translate
gosub collision
cp r0, 0  ; undo if collision detected
skip nz, 1
jr 4
mov r1, 0xF  ; -1
mov r2, 0
gosub translate
; op-y-1 key pressed for move right
mov r0, [0xFD]
cp r0, 12
skip z, 1
jr 13
mov r1, 0xF  ; -1
mov r2, 0
gosub translate
gosub collision
cp r0, 0  ; undo if collision detected
skip nz, 1
jr 4
mov r1, 1
mov r2, 0
gosub translate
mov r3, 1
gosub draw
mov r0, [0xF4]
bit r0, 0
skip nz, 2
goto keywait
ret r0, 0


; Cleanup
; Delete full rows and shift the blocks down.
; Params: none
; Returns: none
; Registers: R0, R1, R2, R3, R4, R5
; Stored in 0x230 - 0x25F, 27 instructions long
org 0x230
cleanup:
mov r1, 0xE
mov r2, 0xC
mov r3, 0xD
mov r0, [r2:r1]
cp r0, 0xF
skip z, 1
jr 17
mov r0, [r3:r1]
cp r0, 0xF
skip z, 1
jr 13
mov r4, r1
mov r0, r0  ;  change these 2 lines to `gosub counter` for alternate counting, update main
mov r0, r0  ; ^---------------------------------------------------------------------------^
mov r1, r4
mov r5, r4
dec r5
mov r0, [r2:r5]
mov [r2:r4], r0
mov r0, [r3:r5]
mov [r3:r4], r0
dsz r4
jr -8
jr -21
dsz r1
jr -23
ret r0, 0


; Counter
; Increments the score at the bottom of the screen.
; Params: none
; Returns: 1 if you "win" (score of 255), 0 otherwise
; Registers: R0, R1
; Stored in 0x260 - 0x27F, 15 instructions long
org 0x260
counter:
mov r0, [0xCF]
inc r0
mov [0xCF], r0
mov r0, [0xDF]
mov r1, 0
adc r0, r1
mov [0xDF], r0
cp r0, 0xF
skip z, 1
ret r0, 0
mov r0, [0xCF]
cp r0, 0xF
skip z, 1
ret r0, 0
ret r0, 1  ; win!


; Main
; The main game loop that ties everything together to play Tertis.
; Params: none
; Returns: none
; Registers: all of them I guess?
; Stored in 0x280 - 0x2BF, 44 instructions long
org 0x280
main:
mov r0, [0xFF]
bclr r0, 3
mov r1, r0
gosub spawn
gosub collision
cp r0, 0
skip nz, 1
jr 5
mov r3, 1
gosub draw
goto lose
mov r3, 1
gosub draw
gosub keywait
mov r3, 0
gosub draw
mov r1, 0
mov r2, 1
gosub translate
gosub collision
cp r0, 0
skip nz, 1
jr -17
mov r1, 0
mov r2, 0xF  ; -1
gosub translate
mov r3, 1
gosub draw
gosub cleanup
gosub counter  ; comment this line out with 2 `mov r0, r0` lines to enable alternate counter. don't forget to update cleanup routine!
jr -44


; Lose
; A "game over" busy loop that flashes the score at the bottom of the screen.
; Params: none
; Returns: none
; Registers: R0, R1, R2
; Stored in 0x2C0 - 0x2EF, 22 instructions long
org 0x2C0
lose:
mov r0, 0xD
mov [0xF2], r0
mov r0, [0xCF]
mov r1, r0
mov r0, [0xDF]
mov r2, r0
mov r0, 0
mov [0xCF], r0
mov [0xDF], r0
mov r0, [0xF4]
bit r0, 0
skip nz, 1
jr -4
mov r0, r1
mov [0xCF], r0
mov r0, r2
mov [0xDF], r0
mov r0, [0xF4]
bit r0, 0
skip nz, 1
jr -4
jr -16
