;; ===========================================================================
;; crtc.asm - CRTC 6845 and Gate Array Programming for Overscan
;; Based on LoukoumasCPC architecture
;; ===========================================================================

;; ---------------------------------------------------------------------------
;; setup_crtc - Program CRTC registers for 96-byte x 272-scanline Overscan
;; Destroys AF, BC, HL
;; ---------------------------------------------------------------------------
setup_crtc:
    ld hl, crtc_data
.loop:
    ld a, (hl)
    inc hl
    cp #FF
    ret z
    ld c, a
    ld b, #BC               ; Select CRTC register
    out (c), c
    ld c, (hl)
    inc hl
    ld b, #BD               ; Write CRTC register value
    out (c), c
    jr .loop

crtc_data:
    defb 0,  CRTC_R0        ; Horizontal total (64)
    defb 1,  CRTC_R1        ; Horizontal displayed (48 chars = 96 bytes)
    defb 2,  CRTC_R2        ; HSYNC position (50)
    defb 3,  CRTC_R3        ; Sync widths (#8E)
    defb 4,  CRTC_R4        ; Vertical total (38 rows = 39 total)
    defb 5,  CRTC_R5        ; Vertical adjust (0)
    defb 6,  CRTC_R6        ; Vertical displayed (34 rows = 272 lines)
    defb 7,  CRTC_R7        ; VSYNC position (34)
    defb 8,  CRTC_R8        ; Non-interlaced (0)
    defb 9,  CRTC_R9        ; 8 scanlines per row (7)
    defb 12, CRTC_R12       ; Start address high (#2C -> #8020 base)
    defb 13, CRTC_R13       ; Start address low (#10)
    defb #FF

;; ---------------------------------------------------------------------------
;; set_pal - Write palette table to Gate Array port #7Fxx
;; HL = Table of [pen_number, #40 + hw_color], ending with #FF
;; Destroys AF, BC, HL
;; ---------------------------------------------------------------------------
set_pal:
    ld bc, #7F00
.pal_loop:
    ld a, (hl)
    inc hl
    cp #FF
    ret z
    out (c), a              ; Select Pen (0..15) or Border (#10)
    ld a, (hl)
    inc hl
    out (c), a              ; Set hardware color (#40 + color)
    jr .pal_loop

;; ---------------------------------------------------------------------------
;; WaitVSync - Hardware vertical sync wait via PPI Port B (#F500 bit 0)
;; Returns right as VSYNC starts (identical to LoukoumasCPC wait_vsync)
;; Destroys AF, BC
;; ---------------------------------------------------------------------------
WaitVSync:
    ld bc, #F500
.w_off:
    in a, (c)
    rra
    jr c, .w_off            ; If inside a VSYNC already, wait for it to end
.w_on:
    in a, (c)
    rra
    jr nc, .w_on            ; Wait for leading edge of VSYNC
    ret

;; ---------------------------------------------------------------------------
;; Authentic Galaga Mode 0 Palette Table (Gate Array Hardware Color values):
;; Note: CPC Gate Array values are (#40 + HW_COLOR_INDEX), NOT firmware inks!
;;   HW 20 = Black, HW 21 = Bright Blue, HW 12 = Bright Red,
;;   HW 10 = Bright Yellow, HW 19 = Bright Cyan, HW 13 = Bright Magenta,
;;   HW 18 = Bright Green, HW 11 = Bright White
;; ---------------------------------------------------------------------------
pal_play:
    defb 0,  #40 + 20       ; Pen 0: Black (#54)
    defb 1,  #40 + 21       ; Pen 1: Bright Blue (#55)
    defb 2,  #40 + 12       ; Pen 2: Bright Red (#4C)
    defb 3,  #40 + 10       ; Pen 3: Bright Yellow (#4A)
    defb 4,  #40 + 19       ; Pen 4: Bright Cyan (#53)
    defb 5,  #40 + 13       ; Pen 5: Bright Magenta (#4D)
    defb 6,  #40 + 18       ; Pen 6: Bright Green (#52)
    defb 7,  #40 + 20       ; Pen 7: Dark / Black (#54)
    defb 8,  #40 + 20       ; Pen 8: Black (#54)
    defb 9,  #40 + 21       ; Pen 9: Bright Blue (#55)
    defb 10, #40 + 12       ; Pen 10: Bright Red (#4C)
    defb 11, #40 + 10       ; Pen 11: Bright Yellow (#4A)
    defb 12, #40 + 19       ; Pen 12: Bright Cyan (#53)
    defb 13, #40 + 13       ; Pen 13: Bright Magenta (#4D)
    defb 14, #40 + 18       ; Pen 14: Bright Green (#52)
    defb 15, #40 + 11       ; Pen 15: Bright White (#4B)
    defb #10, #40 + 20      ; Border: Black (#54)
    defb #FF
