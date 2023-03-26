; Conway's Game of Life
; for Hackaday Berlin 2023 / Supercon 2022 badge
;
; by Martin Ling 2023-03-25
; with thanks to Voja Antonic and Mitch Altman for debugging.
;
; The implementation uses two framebuffers, in pages 4+5 and 6+7. One is shown
; while the other is updated, then the buffers are switched for the next update.
;
; Cells at the edges are considered adjacent to those at the opposite edge, so
; moving patterns will wrap around.
;
; To simulate any starting pattern, load it into pages 4+5, set r1 to 4 and r2
; to zero, then jump to 'update'.
;
; The demo pattern included is two lightweight spaceships, which move upwards
; by one cell every generations: https://conwaylife.com/wiki/Spaceship
;
; To change the update speed, hold the ALT button and use the OPERAND X buttons
; to set a clock divider: 3 = slow, 2 = medium, 1 = fast, 0 = very fast.


; Clear WrFlags.InOutPos so we can use r10 (out) without driving the outputs.
mov r0, [0xF3]
bclr r0, 1
mov [0xF3], r0

; Display pages 4+5.
mov r0, 4
mov [0xF0], r0

; Load starting pattern into pages 4+5.
mov r0, 0b0000
mov [0x40], r0
mov [0x43], r0
mov [0x44], r0
mov [0x46], r0
mov [0x47], r0
mov [0x48], r0
mov [0x4E], r0
mov [0x4F], r0
mov [0x50], r0
mov [0x56], r0
mov [0x57], r0
mov [0x58], r0
mov [0x5B], r0
mov [0x5C], r0
mov [0x5E], r0
mov [0x5F], r0
mov r0, 0b0001
mov [0x55], r0
mov [0x59], r0
mov r0, 0b0010
mov [0x52], r0
mov [0x53], r0
mov [0x54], r0
mov [0x5A], r0
mov [0x5D], r0
mov r0, 0b0011
mov [0x51], r0
mov r0, 0b0100
mov [0x42], r0
mov [0x45], r0
mov [0x4A], r0
mov [0x4B], r0
mov [0x4C], r0
mov r0, 0b1000
mov [0x41], r0
mov [0x4D], r0
mov r0, 0b1100
mov [0x49], r0

; Start update loop beginning from page 4.

; r1 = source page
; r2 = current row
mov r1, 4
mov r2, 0

update:

; Retrieve current and surrounding groups of 4 cells as follows:
; r5 r4 r5
; r6 r3 r6
; r7 r8 r7

; r3 = current cells
mov r0, [r1:r2]
mov r3, r0

; r4 = cells above
dec r2 ; decrement to row above, wrapping around
mov r0, [r1:r2]
mov r4, r0

; r5 = cells above to either side
btg r1, 0 ; switch to other page of current framebuffer
mov r0, [r1:r2]
mov r5, r0

; r6 = cells to either side
inc r2 ; increment back to current row
mov r0, [r1:r2]
mov r6, r0

; r7 = cells below to either side
inc r2 ; increment to row below, wrapping around
mov r0, [r1:r2]
mov r7, r0

; r8 = cells below
btg r1, 0 ; switch back to original page of current framebuffer
mov r0, [r1:r2]
mov r8, r0
dec r2 ; restore original row

; r9 = neighbour count for rightmost cell (0b0001)
mov r9, 0
mov r0, r4
and r0, 0b0010 ; is upper left neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0001 ; is upper neighbour alive?
skip z, 1
inc r9
mov r0, r5
and r0, 0b1000 ; is upper right neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b0010 ; is left neighbour alive?
skip z, 1
inc r9
mov r0, r6
and r0, 0b1000 ; is right neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0010 ; is lower left neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0001 ; is lower neighbour alive?
skip z, 1
inc r9
mov r0, r7
and r0, 0b1000 ; is lower right neighbour alive?
skip z, 1
inc r9

; update rightmost cell
mov out, 0b0001
gosub update_cell

; r9 = neighbour count for mid-right cell (0b0010)
mov r9, 0
mov r0, r4
and r0, 0b0100 ; is upper left neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0010 ; is upper neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0001 ; is upper right neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b0100 ; is left neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b0001 ; is right neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0100 ; is lower left neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0010 ; is lower neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0001 ; is lower right neighbour alive?
skip z, 1
inc r9

; update mid-right cell
mov out, 0b0010
gosub update_cell

; r9 = neighbour count for mid-left cell (0b0100)
mov r9, 0
mov r0, r4
and r0, 0b1000 ; is upper left neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0100 ; is upper neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0010 ; is upper right neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b1000 ; is left neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b0010 ; is right neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b1000 ; is lower left neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0100 ; is lower neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0010 ; is lower right neighbour alive?
skip z, 1
inc r9

; update mid-left cell
mov out, 0b0100
gosub update_cell

; r9 = neighbour count for leftmost cell (0b1000)
mov r9, 0
mov r0, r5
and r0, 0b0001 ; is upper left neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b1000 ; is upper neighbour alive?
skip z, 1
inc r9
mov r0, r4
and r0, 0b0100 ; is upper right neighbour alive?
skip z, 1
inc r9
mov r0, r6
and r0, 0b0001 ; is left neighbour alive?
skip z, 1
inc r9
mov r0, r3
and r0, 0b0100 ; is right neighbour alive?
skip z, 1
inc r9
mov r0, r7
and r0, 0b0001 ; is lower left neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b1000 ; is lower neighbour alive?
skip z, 1
inc r9
mov r0, r8
and r0, 0b0100 ; is lower right neighbour alive?
skip z, 1
inc r9

; update leftmost cell
mov out, 0b1000
gosub update_cell

; row complete, increment row
inc r2

; is page complete?
mov r0, r2
cp r0, 0
skip eq, 2  ; goto is 2 instructions
goto update ; no, update next row

; page complete, increment page
inc r1

; is framebuffer complete?
bit r1, 0
skip z, 2  ; goto is 2 instructions
goto update ; no, update next page

; buffer complete, wrap back to first framebuffer if necessary
mov r0, r1 
cp r0, 8
skip lt, 1
mov r0, 4

; display new framebuffer
mov [0xF0], r0
mov r1, r0
goto update


update_cell:
; r1 = page
; r2 = row
; r3 = current states
; r9 = neighbour count
; out = bitmask of cell
mov r0, out
and r0, r3 ; is cell alive?
skip z, 2  ; goto is 2 instructions
goto currently_alive ; yes

currently_dead:
; is neighbour count equal to 3?
mov r0, r9
cp r0, 3
skip eq, 2         ; goto is 2 instructions
goto becomes_dead  ; no: stays dead
goto becomes_alive ; yes: becomes alive

currently_alive:
; is neighbour count >= 2 ?
mov r0, r9
cp r0, 2
skip gte, 2        ; goto is 2 instructions
goto becomes_dead  ; no: becomes dead
; is neighbour count < 4 ?
cp r0, 4
skip lt, 2         ; goto is 2 instructions
goto becomes_dead  ; no: becomes dead

becomes_alive:
btg r1, 1 ; switch to other framebuffer
mov r0, [r1:r2] ; load destination
or r0, out ; set cell alive
mov [r1:r2], r0 ; update destination
btg r1, 1 ; switch back to original framebuffer
ret r0, 1

becomes_dead:
cpl r0, out ; invert bitmask
mov out, r0
btg r1, 1 ; switch to other framebuffer
mov r0, [r1:r2] ; load destination
and r0, out ; set cell dead
mov [r1:r2], r0 ; update destination
btg r1, 1 ; switch back to original framebuffer
ret r0, 0
