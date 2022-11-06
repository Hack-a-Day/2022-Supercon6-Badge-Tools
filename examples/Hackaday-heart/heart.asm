mov r0, 2
mov [0xf0], r0 ; set page
mov r0, 0b0100 ; start writing pixels into ram
mov [48], r0
mov r0, 0b1110
mov [49], r0
mov r0, 0b1111
mov [50], r0
mov r0, 0b0111
mov [51], r0
mov r0, 0b0011
mov [52], r0
mov r0, 0b0001
mov [53], r0
mov r0, 0b1010
mov [54], r0
mov [55], r0
mov [57], r0
mov [58], r0
mov r0, 0b1110
mov [56], r0
mov r0, 0b0001
mov [59], r0
mov r0, 0b0011
mov [61], r0
mov r0, 0b0010
mov [60], r0
mov [62], r0
mov [63], r0 ; end of left side
mov r0, 0b0100 ; beginning of right side
mov [32], r0
mov r0, 0b1110
mov [33], r0
mov [34], r0
mov r0, 0b1100
mov [35], r0
mov r0, 0b1000
mov [36], r0
mov r0, 0b0000
mov [37], r0
mov [43], r0
mov r0, 0b1100
mov [38], r0
mov [42], r0
mov r0, 0b1010
mov [39], r0
mov [40], r0
mov [41], r0
mov r0, 0b1000
mov [44], r0
mov [45], r0
mov [46], r0
mov [47], r0
jr -1 ; loop on this instruction forever so the pc doesn't overflow