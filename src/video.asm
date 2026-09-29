;; ============================================================================
;; video.asm - Overscan Screen Address Table & Sprite Blitters
;; Mode 0 (96 bytes wide x 272 scanlines)
;; Based on LoukoumasCPC architecture
;; ============================================================================

line_tab:       defs DISPLAY_LINES * 2, 0

;; ---------------------------------------------------------------------------
;; build_line_tab - Fill line_tab with start address of all 272 scanlines
;; Page 2 (#8020): Rows 0..20 (21 rows = 168 lines)
;; Page 3 (#C000): Rows 21..33 (13 rows = 104 lines)
;; Destroys AF, BC, DE, HL
;; ---------------------------------------------------------------------------
build_line_tab:
    ld hl, line_tab
    ld de, PAGE2_BASE           ; #8020
    ld c, PAGE2_ROWS            ; 21 rows
.p2_loop:
    call .build_row
    dec c
    jr nz, .p2_loop

    ld de, PAGE3_BASE           ; #C000
    ld c, DISPLAY_ROWS - PAGE2_ROWS ; 13 rows
.p3_loop:
    call .build_row
    dec c
    jr nz, .p3_loop
    ret

.build_row:
    push de
    ld b, 8
.raster_loop:
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ld a, d
    add a, 8                    ; +2048 bytes (next raster of same row)
    ld d, a
    djnz .raster_loop
    pop de
    ld a, e
    add a, BYTES_PER_LINE       ; +96 bytes
    ld e, a
    ret nc
    inc d
    ret

;; ---------------------------------------------------------------------------
;; ClearScreenOverscan - Clear all 272 scanlines across 96 bytes to Pen 0 (#00)
;; Destroys AF, BC, DE, HL
;; ---------------------------------------------------------------------------
ClearScreenOverscan:
    ld hl, line_tab
    ld de, DISPLAY_LINES        ; 272 scanlines in 16-bit DE
.clr_loop:
    push de
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    push hl
    ex de, hl                   ; HL = screen scanline start
    xor a
    ld (hl), a
    ld d, h
    ld e, l
    inc de
    ld bc, BYTES_PER_LINE - 1
    ldir
    pop hl
    pop de
    dec de
    ld a, d
    or e
    jr nz, .clr_loop
    ret

;; ---------------------------------------------------------------------------
;; GetScreenAddr - Screen Address Calculator for 96x272 Overscan
;; Input:  B = X (byte column, 0..95)
;;         C = Y (scanline, 0..271)
;; Output: HL = Screen Memory Address
;; Preserves: BC, IX, IY
;; ---------------------------------------------------------------------------
GetScreenAddr:
    push de
    ld l, c
    ld h, 0
    add hl, hl                  ; Y * 2
    ld de, line_tab
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)                  ; DE = scanline base
    ld l, b
    ld h, 0
    add hl, de                  ; HL = base + X
    pop de
    ret

;; ---------------------------------------------------------------------------
;; DrawSprite16x16: Draw 16x16 sprite (8 bytes wide x 16 scanlines)
;; Input:  B = X (0..88)
;;         C = Y (0..255)
;;         HL = Pointer to sprite data (128 bytes)
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
DrawSprite16x16:
    push ix
    push bc
    push hl
    ld e, c
    ld d, 0
    sla e
    rl d                        ; DE = Y * 2 (16-bit safe for Y up to 271)
    ld ix, line_tab
    add ix, de                  ; IX = pointer to line_tab[Y]
    pop hl                      ; HL = sprite data
    ld c, 16                    ; 16 lines
.draw_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b                     ; X byte offset
    add a, e
    ld e, a
    jr nc, .draw_no_c
    inc d
.draw_no_c:
    ;; Transfer 8 bytes from HL (sprite) to DE (screen) without touching BC
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    dec c
    jr nz, .draw_loop
    pop bc
    pop ix
    ret

;; ---------------------------------------------------------------------------
;; ClearSprite16x16: Erase 16x16 sprite area with black (Pen 0 = #00)
;; Input:  B = X (0..88)
;;         C = Y (0..255)
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
ClearSprite16x16:
    push ix
    push bc
    ld e, c
    ld d, 0
    sla e
    rl d                        ; DE = Y * 2 (16-bit safe for Y up to 271)
    ld ix, line_tab
    add ix, de
    ld c, 16
.clr_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .clr_no_c
    inc d
.clr_no_c:
    ex de, hl
    xor a
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a
    dec c
    jr nz, .clr_loop
    pop bc
    pop ix
    ret

;; ---------------------------------------------------------------------------
;; DrawBitmapRect: Draw bitmap of D bytes wide x E scanlines high from HL to (B=X, C=Y)
;; Input:  B = X (0..95)
;;         C = Y (0..271)
;;         D = Width in bytes (1..96)
;;         E = Height in scanlines (1..272)
;;         HL = Pointer to bitmap data
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
DrawBitmapRect:
    push ix
    push bc
    ld a, e
    ld (.dbr_lines), a
    ld a, d
    ld (.dbr_width), a

    ld e, c
    ld d, 0
    sla e
    rl d                        ; DE = Y * 2 (16-bit safe)
    ld ix, line_tab
    add ix, de                  ; IX = pointer to line_tab[Y]

.dbr_row:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .dbr_nc
    inc d
.dbr_nc:
    push bc
    ld a, (.dbr_width)
    ld b, a
.dbr_col:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    djnz .dbr_col
    pop bc

    ld a, (.dbr_lines)
    dec a
    ld (.dbr_lines), a
    jr nz, .dbr_row

    pop bc
    pop ix
    ret

.dbr_lines: defb 0
.dbr_width: defb 0

;; ClearBitmapRect: Clear a rectangle to Pen 0.
;; Input: B=X byte, C=Y scanline, D=width bytes, E=height scanlines.
;; Preserves: IX, BC
ClearBitmapRect:
    push ix
    push bc
    ld a, e
    ld (.cbr_lines), a
    ld a, d
    ld (.cbr_width), a

    ld e, c
    ld d, 0
    sla e
    rl d
    ld ix, line_tab
    add ix, de

.cbr_row:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .cbr_nc
    inc d
.cbr_nc:
    push bc
    ld a, (.cbr_width)
    ld b, a
    xor a
.cbr_col:
    ld (de), a
    inc de
    djnz .cbr_col
    pop bc

    ld a, (.cbr_lines)
    dec a
    ld (.cbr_lines), a
    jr nz, .cbr_row

    pop bc
    pop ix
    ret

.cbr_lines: defb 0
.cbr_width: defb 0
