; A health points counter for playing MTG. Called Life Points.
; Health or Life Points starts at 20.
; I read a lot of what Tom Nardi did in his example of rolling a die
; to better understand how to use graphics in a data area and send them
; into the matrix. Thank you Tom.

; Greg Bushta, 11/2022

init:		; Tom Nardi, 2022  <---

mov r0, 2	; Set matrix page
mov [0xF0], r0

mov r0, 1 	; Set CPU speed. I had it at 8 for debugging.
mov [0xF1], r0 ; If the speed is set to 0 things get glitchy.

; The display pages are 2 on the right and 3 on the left.
; Storage for the numbers is on page 4. Nibbles 0, 1 and 2
; will hold ones, tens and hundreds, respectively.
; The game starts with 20 health points, unless it is
; 'commander' which starts at 40. You'll have to change the number
; on line 23 from 1 to 2. 2 would mean 4 in the tens spot on the
; matrix display.

mov r0, 0
mov [0x40], r0 ; ones
mov [0x42], r0 ; hundreds
mov r0, 1
mov [0x41], r0 ; tens

; can't forget when I add the numbers it only goes 0-4,
; and odd or even plays a part.

; r1 holds the current number that needs to be displayed.
; r6 holds if the number is odd or even.
; r5 holds where on the display matrix the number is.
; I'll put an indicator of odd or even on page 4, Nibbles
; 3, 4 and 5 for ones, tens and hundreds.

mov r0, 0
mov [0x43], r0 ; ones
mov [0x44], r0 ; tens
mov [0x45], r0 ; hundreds

gosub display_it ; This could be outside of main: because it is
                 ; part of the initialization of the program.

main:     ; The main loop of the program.
mov r0, [0xfd]  ; a key was pressed
cp r0, 10
skip nz, 2
goto minus
cp r0, 11
skip nz, 2 ; if it is a plus skip one command
goto plus
;mov r0, 0
;mov [0xfd], r0
goto main

minus:
; health is going down
; subtract from the ones spot and borrow from tens if needed
; take into account that the numbers are 0-9

; First check to see if health is 1 if so go to zombi
; :::: if health is 1 number is 0 and odd is 1
; :::: Gotta check this out

mov r0, 0   ; zero out the key press
mov [0xfd], r0

; Check to see if health is zero
mov r0, [0x40]
cp r0, 0
skip z, 1
jr 22
mov r0, [0x43]
cp r0, 1
skip z, 1
jr 18
mov r0, [0x41] ; if equal to 1 check tens is zero then hundreds is zero
cp r0, 0
skip z, 1
jr 14
mov r0, [0x44]
cp r0, 0
skip z, 1
jr 10
mov r0, [0x42] ; check hundred's spot
cp r0, 0
skip z, 1
jr 6
mov r0, [0x45]
cp r0, 0
skip z, 1
jr 2
goto zombi

; well, health was greater than 1 so subtract one from the health
; first check the ones
mov r0, [0x43]
cp r0, 1
skip nz, 3
mov r0, 0   ; if the odd even holder had a 1 subtract it
mov [0x43], r0
jr 39 ; going to minus_out
mov r0, 1  ; if the odd even holder had a 0 make it a 1
mov [0x43], r0
mov r0, [0x40]  ; subtract one from the even number
cp r0, 0
skip z, 3
dec r0
mov [0x40], r0
jr 31 ; going to minus_out
mov r0, 4     ; if the main (even) number was a 0 before
mov [0x40], r0  ; subtraction make it a 4 and take away from tens
; now check the tens
mov r0, [0x44]
cp r0, 1
skip nz, 3
mov r0, 0   ; if the odd even holder had a 1 subtract it
mov [0x44], r0
jr 23 ; going to minus_out
mov r0, 1  ; if the odd even holder had a 0 make it a 1
mov [0x44], r0
mov r0, [0x41]  ; subtract one from the even number
cp r0, 0
skip z, 3
dec r0
mov [0x41], r0
jr 15
mov r0, 4     ; if the main (even) number was a 0 before
mov [0x41], r0  ; subtraction make it a 4 and take away from 100s
; now check the hundreds
mov r0, [0x45]
cp r0, 1
skip nz, 3
mov r0, 0   ; if the odd even holder had a 1 subtract it
mov [0x45], r0
jr 7 ; going to minus_out
mov r0, 1  ; if the odd even holder had a 0 make it a 1
mov [0x45], r0
mov r0, [0x42]  ; subtract one from the even number
cp r0, 0
skip z, 2
dec r0
mov [0x42], r0

; minus_out:
; before I get out of here change the odd or even to the other.

gosub display_it

goto main

plus:
; health is going up
; add one to the ones spot and add to the tens if needed
; take into account that the numbers are 0-9
; My prediction is that this is going to be much easier
; than the subtraction subroutiine.
mov r0, [0x43]
cp r0, 0
skip nz, 4
mov r0, 1
mov [0x43], r0
goto plus_out
mov r0, 0
mov [0x43], r0
mov r0, [0x40]
inc r0
cp r0, 5
skip z, 3
mov [0x40], r0
goto plus_out
mov r0, 0
mov [0x40], r0
mov r0, [0x44]
cp r0, 0
skip nz, 4
mov r0, 1
mov [0x44], r0
goto plus_out
mov r0, 0
mov [0x44], r0
mov r0, [0x41]
inc r0
cp r0, 5
skip z, 3
mov [0x41], r0
goto plus_out
mov r0, 0
mov [0x41], r0
mov r0, [0x45]
cp r0, 0
skip nz, 4
mov r0, 1
mov [0x45], r0
goto plus_out
mov r0, 0
mov [0x45], r0
mov r0, [0x42]
inc r0
cp r0, 5
skip z, 3
mov [0x42], r0
goto plus_out
mov r0, 4
mov [0x40], r0
mov [0x41], r0
mov [0x42], r0
mov r0, 1
mov [0x43], r0
mov [0x44], r0
mov [0x45], r0
;  999 points is as high as I want the program to go

plus_out:
mov r0, 0
mov [0xfd], r0 ; reset the key press
; before I get out of here change the odd or even to the other.
gosub display_it
goto main  ; go back up to the beginning of the main loop

zombi:
; display DEAD in the matrix
mov pch, 2
mov pcm, 5
mov r3, 2
mov r4, 3
mov r5, 0
;mov r7, 0
mov jsr, 0
mov [r3:r5], r0
inc jsr
mov [r4:r5], r0
;dsz r7
;jr 3 ; Automatically skipped if r7 becomes zero
inc r5
mov r0, r5
cp r0, 15
skip z, 2
inc jsr
jr -9

jr -1  ; Stay here.  User must press Break to end the program.

display_it:
; blank the matrix first for a fresh draw
mov r0, 0
mov r7, 0
mov r5, 0
mov r3, 2
mov r4, 3
mov [r3:r5], r0
mov [r4:r5], r0
inc r5
dsz r7
jr -5

; For giggles, put in the hundred's number
; Since that worked I am going to try to not have a number
; display if it is a zero. No leading zero.
mov r0, [0x42]
mov r1, r0
mov r9, 0
mov r5, 10
mov r0, [0x45]
mov r6, r0
cp r0, 0
skip z, 1
jr 4
mov r0, r1
cp r0, 0   ; if number and odd_even is 0 don't print
skip z, 3
mov r9, 1
gosub drawnum ; put the number in the matrix

; Now attempt to put in the tens spot number
; check if hundred's spot is a zero. If not, don't check ten's spot
; if the hundred's spot is not a zero we must display the ten's
; number, so there is no need to check if it needs to be displayed.
mov r0, [0x42]
cp r0, 0
skip z, 1
jr 12 ; set the tens to print
mov r0, [0x45]
cp r0, 0
skip z, 1
jr 8 ; set the tens to print
      ; check if tens is a zero. If so, no need to print
mov r0, [0x41]
cp r0, 0
skip z, 1
jr 4 ; set the tens to print
mov r0, [0x44]
cp r0, 0
skip nz, 1
jr 7  ; tens was a zero don't send to matrix continue to ones
      ; set the tens to print
mov r0, [0x41]
mov r1, r0
mov r0, [0x44]
mov r6, r0
mov r5, 5
gosub drawnum ; put the number in the matrix

; Number in the ones spot, and it will always be displayed.
; I could check to see if this number is < 1 and display DIED on
; the display matrix.
mov r0, [0x40]
mov r1, r0
mov r0, [0x43]
mov r6, r0
mov r5, 0	; Set initial row
gosub drawnum	; Put the number in the matrix

ret r0, 0	; return to plus or minus from gosub call then they call goto main.

drawnum:
mov pch, 2	; Set high jump coord
mov pcm, r1	; Mid address maps to die face
mov jsr, 0	; Execute jump with lowest nibble, R0 now loaded with 4 bits
mov r2, r0

mov r0, r6  ; This area is for the odd numbers
cp r0, 0    ; can probably use something like mov jsr, 8 if the
skip nz, 1  ; number is an odd number instead of looping.
jr 5
mov r7, 8
inc jsr
mov r2, r0
dsz r7
jr -4

mov r0, r2

mov r7, 0	; Init counter
mov r3, 2	; Set right matrix page
mov r4, 3	; Set left matrix page

mov [r3:r5], r0 ; Draw right-side nibble
inc jsr		; Inc lowest bit reads next nibble
mov [r4:r5], r0	; Draw left-side nibble
inc r7 		; Inc counter
mov r0, r7	; Move counter, can only compare to R0
cp r0, 4	; Check if we've looped 8 times
skip z, 3	; Skip next 3 lines if true
inc r5		; Move to next row
inc jsr		; Read next nibble
jr -10		; Loop around
inc r5
ret r0, 0	; Return from sub

org 0x200
dicegfx:	; Graphics data
; zero
byte 0b01111110
byte 0b10000001
byte 0b10000001
byte 0b01111110

; one
byte 0b00000000
byte 0b11111111
byte 0b00000000
byte 0b00000000

; two
byte 0b01110001
byte 0b10001001
byte 0b10000101
byte 0b01100011

; three
byte 0b01101110
byte 0b10010001
byte 0b10010001
byte 0b01000010

; four
byte 0b11111111
byte 0b00001000
byte 0b00010000
byte 0b11100000

; five
byte 0b10001110
byte 0b10010001
byte 0b10010001
byte 0b11110010

; six
byte 0b01001110
byte 0b10010001
byte 0b10010001
byte 0b01111110

; seven
byte 0b11100000
byte 0b10011000
byte 0b10000111
byte 0b10000000

; eight
byte 0b01101110
byte 0b10010001
byte 0b10010001
byte 0b01101110

; nine
byte 0b01111111
byte 0b10010000
byte 0b10010000
byte 0b01100000

; DEAD
byte 0b01111110
byte 0b10000001
byte 0b11111111
byte 0b00000000
byte 0b01111111
byte 0b10001000
byte 0b01111111
byte 0b00000000
byte 0b10000001
byte 0b10010001
byte 0b11111111
byte 0b00000000
byte 0b01111110
byte 0b10000001
byte 0b11111111
byte 0b00000000

; EOF
