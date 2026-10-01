;; ===========================================================================
;; keys.asm - Hardware Keyboard and Joystick Matrix Reader
;; Direct PPI 8255 / PSG AY-3-8912 matrix scanning (from LoukoumasCPC)
;; ===========================================================================

CTL_FIRE        EQU 0
CTL_LEFT        EQU 1
CTL_RIGHT       EQU 2
CTL_UP          EQU 3
CTL_DOWN        EQU 4
CTL_PAUSE       EQU 5
CTL_START1      EQU 6
CTL_START2      EQU 7

key_rows:       defs 10, #FF
ctl_now:        defb 0
ctl_last:       defb 0
ctl_pressed:    defb 0

;; ---------------------------------------------------------------------------
;; read_keyboard - Cache all ten matrix lines in key_rows
;; Destroys AF, BC, HL, E
;; ---------------------------------------------------------------------------
read_keyboard:
    ld bc, #F40E                ; PPI port A = PSG register 14 (the matrix)
    out (c), c
    ld bc, #F6C0                ; Port C: function 11 (select register)
    out (c), c
    ld bc, #F600                ; Port C: inactive
    out (c), c
    ld bc, #F792                ; PPI control: turn Port A to input
    out (c), c

    ld hl, key_rows
    ld e, #40                   ; Port C: function 01 (read), matrix line 0
.read_loop:
    ld bc, #F600
    out (c), e
    ld b, #F4
    in a, (c)                   ; Read 8 keys (0 = pressed)
    ld (hl), a
    inc hl
    inc e
    ld a, e
    cp #4A                      ; 10 lines (#40..#49)
    jr nz, .read_loop

    ld bc, #F782                ; PPI control: Port A back to output
    out (c), c
    ret

;; ---------------------------------------------------------------------------
;; Control Mapping: [matrix_line, bit_mask, 1 << CTL_BIT]
;; ---------------------------------------------------------------------------
ctl_map:
    defb 5, #80, 1 << CTL_FIRE  ; Spacebar
    defb 9, #10, 1 << CTL_FIRE  ; Joystick Fire 1
    defb 1, #01, 1 << CTL_LEFT  ; Cursor Left
    defb 4, #04, 1 << CTL_LEFT  ; 'O' key (Line 4, Bit 2)
    defb 9, #04, 1 << CTL_LEFT  ; Joystick Left
    defb 0, #02, 1 << CTL_RIGHT ; Cursor Right
    defb 3, #08, 1 << CTL_RIGHT ; 'P' key (Line 3, Bit 3)
    defb 9, #08, 1 << CTL_RIGHT ; Joystick Right
    defb 0, #01, 1 << CTL_UP    ; Cursor Up
    defb 9, #01, 1 << CTL_UP    ; Joystick Up
    defb 0, #04, 1 << CTL_DOWN  ; Cursor Down
    defb 9, #02, 1 << CTL_DOWN  ; Joystick Down
    defb 5, #10, 1 << CTL_PAUSE ; 'H' key (Pause / Halt: Line 5, Bit 4)
    defb 8, #01, 1 << CTL_START1 ; '1' key: 1-player game
    defb 8, #02, 1 << CTL_START2 ; '2' key: 2-player game
    defb #FF

;; ---------------------------------------------------------------------------
;; read_controls - Updates ctl_now (held) and ctl_pressed (just pressed)
;; Destroys AF, BC, DE, HL
;; ---------------------------------------------------------------------------
read_controls:
    call read_keyboard
    xor a
    ld (ctl_now), a
    ld hl, ctl_map
.map_loop:
    ld a, (hl)
    inc a
    jr z, .map_done
    dec a
    push hl
    ld e, a
    ld d, 0
    ld hl, key_rows
    add hl, de
    ld a, (hl)                  ; Key line state
    pop hl
    inc hl
    and (hl)                    ; Bit test: 0 = pressed
    inc hl
    jr nz, .map_next
    ld a, (ctl_now)
    or (hl)
    ld (ctl_now), a
.map_next:
    inc hl
    jr .map_loop

.map_done:
    ld a, (ctl_now)
    ld b, a
    ld a, (ctl_last)
    cpl
    and b                       ; High if down this frame and up last frame
    ld (ctl_pressed), a
    ld a, b
    ld (ctl_last), a
    ret
