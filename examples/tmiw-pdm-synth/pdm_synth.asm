; PDM Synthesizer: A simple-ish program that generates square and triangle waves.
; Each wave can be one of four frequencies, too!
;
; By Mooneer Salem (@tmiw)
;
; Note: required connections:
;     1. One wire from one of output pins 1-3 (pin 0 is always 1)
;        a) Wire should connect to LPF to convert to analog
;        b) Output from LPF should connect to NJM2113 or equivalent for amplification (see example circuit at https://faculty.weber.edu/fonbrown/ee3710/lab8.pdf)
;     2. G, V to NJM2113 or equivalent. Selected part must be capable of accepting 2-3V.
start:      
            mov R1, 0  ; r = 0
            
            ; Maximum possible clock rate (~250 KHz)
            mov R0, 0
            mov [0xF1], R0
            
repeat_triangle:
            gosub select_wave
            jr -2

; reads: R2 (PCM value), R1 (error)
; writes: addr 0x0A (out GPIO 1), R1 (error), R0 (temp)
; NOTE: R1 should be initialized to 0 before first call!
; NOTE: modify triangle below if this function moves for 
;       any reason!
encode:
            add r1, r2   ; err += pcm
            mov r0, r1   ; compare err with 8
            cp r0, 8
            skip nc, 2   
            mov Out, 1   ; GPIO = 0 if err >= 8
            jr 1
            mov Out, 15  ; GPIO = 1 if err < 8
            sub r1, Out  ; err -= 1 or -1
            ret r0, 0

; Entry point for handling key I/O.
select_wave:
            mov r0, 15     ; show page 15 and 0 (debugging)
            mov [0xf0], r0

            ; Watch for key press
            mov r0, [0xFC] ; read key status
            bit r0, 0      ; read JustPress
            skip z, 2      ; if not pressed, skip next line
            goto select_wave_keypress
            
select_wave_emit:
            ; Determine which wave type to emit
            mov r0, r7
            bit r0, 0      ; if bit 0 = 1, square wave
            skip z, 2
            goto triangle
            ;ret r0, 0
            goto square    ; note, both of these will pop SP on completion

select_wave_keypress:
            mov r0, [0xFD]    ; read key type
            bit r0, 1         ; check Opcode_8/7 keys
            skip nz, 2        ; if Opcode_7 pressed, skip next 2 lines 
            inc r7
            jr 1              ; skip down to select_wave_keypress_end
            inc r8            ; increment sync/clock value
            
select_wave_keypress_end:
            mov r0, r8
            and r0, 3         ; cap sync/clock to 3
            mov r8, r0
            mov [0xF1], R0    ; reset clock to selected value
            mov r0, r7        ; cap mode to 0-1
            and r0, 1
            mov r7, r0
                        
            goto select_wave_emit

; Emits a square wave.
square:
            mov r0, r8
            mov [0xf2], r0    ; reset sync to selected value
            mov r0, [0xF4]
            mov Out, 15
            mov r9, 2
            
square_wait:
            mov r0, [0xF4]
            bit r0, 0
            skip nz, 1
            jr -4
            mov r0, Out
            xor r0, r0
            mov Out, R0
            dsz r9
            jr -9
            
            ret r0, 0
            
; emits triangle wave on GPIO out[0]
; writes: R0, R3, R4
triangle:   
            mov R3, 0  ; i = 0
            mov pc, [0] ; Clear PCH and PCM for JSR optimizations below

triangle_loop1:
            mov R2, R3
            mov JSR, 6 ; optimization for the below as gosub needs 2 instructions
                       ; NOTE: encode must NOT be moved without changing the offset here.
            mov JSR, 6
            mov JSR, 6
            mov JSR, 6
            inc R3      ; i++
            skip z, 1   ; if (i == 0) break
            jr -7       ; continue

triangle_loop1_end:            
            mov R3, 15  ; i = 15
            
triangle_loop2:
            mov R0, R3
            mov JSR, 6 ; optimization for the below as gosub needs 2 instructions
                       ; NOTE: encode must NOT be moved without changing the offset here.
            ;gosub encode ; encode(i) 

            mov JSR, 6
            mov JSR, 6
            mov JSR, 6
            dec R3      ; i--
            skip z, 1   ; if (i == 0) break
            jr -7       ; continue
            
triangle_loop2_end:
            ret r0, 0