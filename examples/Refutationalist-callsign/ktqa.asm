mov r0, 7
mov [0xF1], r0 ; clock it up, yo.
mov r0, 2     
mov [0xF0], r0 ; turn the page


; Paste Starts Here
mov r0,0b1110
mov [2:0],r0
mov r0,0b0011
mov [3:0],r0
mov r0,0b1000
mov [2:1],r0
mov r0,0b0110
mov [3:1],r0
mov r0,0b1110
mov [2:2],r0
mov r0,0b0011
mov [3:2],r0
mov r0,0b0000
mov [2:3],r0
mov r0,0b0000
mov [3:3],r0
mov r0,0b1100
mov [2:4],r0
mov r0,0b0011
mov [3:4],r0
mov r0,0b0110
mov [2:5],r0
mov r0,0b0100
mov [3:5],r0
mov r0,0b0010
mov [2:6],r0
mov r0,0b0100
mov [3:6],r0
mov r0,0b1100
mov [2:7],r0
mov r0,0b0011
mov [3:7],r0
mov r0,0b0000
mov [2:8],r0
mov r0,0b0100
mov [3:8],r0
mov r0,0b1110
mov [2:9],r0
mov r0,0b0111
mov [3:9],r0
mov r0,0b0000
mov [2:10],r0
mov r0,0b0100
mov [3:10],r0
mov r0,0b0000
mov [2:11],r0
mov r0,0b0000
mov [3:11],r0
mov r0,0b0110
mov [2:12],r0
mov r0,0b0100
mov [3:12],r0
mov r0,0b1000
mov [2:13],r0
mov r0,0b0010
mov [3:13],r0
mov r0,0b0000
mov [2:14],r0
mov r0,0b0001
mov [3:14],r0
mov r0,0b1110
mov [2:15],r0
mov r0,0b0111
mov [3:15],r0
; Paste Ends Here

mov r2, 3 ; left page
mov r3, 2 ; right page
mov r4, 0 ; register count

; simple xor effect, left side
mov r0,[r2:r4]
xor r0,0b1111
mov [r2:r4],r0

; simple xor effect, right side
mov r0,[r3:r4]
xor r0,0b1111
mov [r3:r4],r0

inc r4    ; increment row
mov r0,r4 ; and move it where we can assay
cp r0,16  ; are we at the end of the regisers?
skip z,1  ; yes?
jr -11    ; then jump to where we set the reg. count to 0
jr -12    ; otherwise jump to the line after that

; but I can't manage a freakin' case switch, so what's my deal?
; sam sam@vis.nu
