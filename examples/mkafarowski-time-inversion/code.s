; R1:R2 vram address
; R3: pixel bitmask
; R4: height
; R5: inverter
; R6: pixel x
; R7: pixel y
; R8: loop counter
; R9: loop counter

MOV R0,0x2
MOV [0xF1],R0   ; set clock to slower speed

MOV R0,0x8
MOV [0xF3],R0   ; disable leds

GOSUB ShowDisplay

MOV r5,0        ; set invert register

loop:
    MOV R0,[0xC1]           ; Check if the top layers are full (or empty, depending on the inverter register) 
    XOR R0,0xF
    XOR R0,R5
        SKIP Z, 2
        GOTO PrepareSand
        MOV R0,[0xD1]
        XOR R0,0xF
        XOR R0,R5
            SKIP Z, 2
            GOTO PrepareSand
            MOV R0, R5
            XOR R0,0xF
            MOV R5, R0
    
    PrepareSand:
    MOV R0,[0xFF]   ; randomly get an x location
    AND R0,0xF      ; clear carry
    RRC R0
    MOV R6,R0

    MOV R4,0        ; set pixel to top
    MOV R7,0

    DropSand:
        MOV R0,R4
        CP R0,0             ; If the height isn't zero, erase the previous so a line doesn't form
            SKIP NZ,2
            GOTO DrawSand  
            MOV R9,0x1      
            SUB R0,R9
            MOV R7,R0
            GOSUB TogglePixel
        
        DrawSand:           ; Draw the main dot
        MOV R7,R4
        GOSUB TogglePixel

        MOV R0,R5           ; "Fixes" artifacts at the top because this has already taken long enough LOL
        MOV [0xC0],R0
        MOV [0xD0],R0
        
        INC R7              ; Check if pixel below is occupied
        GOSUB GetPixel
        GOSUB GetBitmask
        MOV R0,[R1:R2]
        XOR R0,R5
        AND R0,R3
            SKIP Z,2
            GOTO loop

        INC R4
        SKIP C,2
        GOTO DropSand


    GOTO loop

ret R0,0

; Given R6 as X and R7 and Y, turn on the requested pixels leaving others intact
TogglePixel:
    GOSUB GetPixel
    GOSUB GetBitmask
    MOV R0,[R1:R2]  
    XOR R0,R3
    MOV [R1:R2],R0  ; Push Bitmask to display
    ret R0,0


; Given R6 as X and R7 and Y, get the address (but not bitmask of pixel) and place in R1:R2
GetPixel:
    MOV R1,0xC  ; R1 is MSB of VRAM Address (page n+1 or n)
    MOV R2,R7   ; R2 is LSB of VRAM Address (height)
    MOV R0,R6
    MOV R9,0x4
    SUB R0,R9
    SKIP C,1
    MOV R1,0xD  ; Set to page n+1 if greater than 3
    ret R0,0

; Given R6 as X, get the bitmask and place in R3
GetBitmask:
    MOV R3,0x8  ; R3 is bitmask
    MOV R0,R6
    AND R0,0x3 
    MOV R9,R0

    shift:          ; interesting note, this causes the LSB drops to fall slower because more shifts are required
    MOV R0,R9
    CP R0,0
        SKIP NZ,1
        ret R0,0 ; return if counter is zero

    AND R0,0xF  ; clear carry
    RRC R3
    DEC R9
    GOTO shift

ShowDisplay:
    MOV R0,0xC      ; Set page to VRAM
    MOV [0xF0],R0
    ret R0,0

ClearScreen:
    MOV R9,0
    loopa:
        MOV R8,0xC
        MOV R0,0
        MOV [R8:R9],R0
        MOV R8,0xD
        MOV [R8:R9],R0
        INC R9
            SKIP C,2
            GOTO loopa
    
    ret R0,0              
            
    
