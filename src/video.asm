;; ============================================================================
;; video.asm - Overscan Screen Address Table & Sprite Blitters
;; Mode 0 (96 bytes wide x 272 scanlines)
;; Based on LoukoumasCPC architecture
;; ============================================================================

;; line_tab (DISPLAY_LINES words) is built at boot over the load-image copy
;; of the disk code, which is dead once relocated (see main.asm).

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
;; The scanline addresses are POPped from line_tab, so interrupts are off
;; while the sprite is drawn (about 0.9 ms; the Gate Array keeps the request).
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
DrawSprite16x16:
    push bc
    ld a, b
    ld (.ds_x + 1), a
    ex de, hl                   ; DE = sprite data
    ld l, c
    ld h, 0
    add hl, hl
    ld bc, line_tab
    add hl, bc                  ; HL = &line_tab[Y]
    di
    ld (.ds_sp + 1), sp
    ld sp, hl
    ex de, hl                   ; HL = sprite data
    ld bc, 16 * 8               ; LDI clears P/V when BC reaches 0
.line:
    pop de
    ld a, e
.ds_x:
    add a, 0
    ld e, a
    jr nc, .line_nc
    inc d
.line_nc:
    ldi : ldi : ldi : ldi : ldi : ldi : ldi : ldi
    jp pe, .line
.ds_sp:
    ld sp, 0
    ei
    pop bc
    ret

;; ---------------------------------------------------------------------------
;; ClearSprite16x16: Erase 16x16 sprite area with black (Pen 0 = #00)
;; Input:  B = X (0..88)
;;         C = Y (0..255)
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
ClearSprite16x16:
    ld de, #0810                ; 8 bytes x 16 lines

;; ---------------------------------------------------------------------------
;; ClearSmallRect: Clear D bytes (1..8) x E scanlines (1..16) at (B=X, C=Y).
;; Like DrawSprite16x16 it POPs the scanline addresses with interrupts off.
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
ClearSmallRect:
    push bc
    ld a, d
    add a, a                    ; 2 bytes per store
    ld l, a
    ld h, 0
    push de
    ex de, hl
    ld hl, .csr_end
    or a
    sbc hl, de
    ld (.csr_jump + 1), hl      ; Enter the run D stores before its end
    pop de
    ld a, b
    ld (.csr_x + 1), a
    ld l, c
    ld h, 0
    add hl, hl
    ld bc, line_tab
    add hl, bc                  ; HL = &line_tab[Y]
    ld d, 0                     ; D = black, E = lines
    di
    ld (.csr_sp + 1), sp
    ld sp, hl
.csr_row:
    pop hl
    ld a, l
.csr_x:
    add a, 0
    ld l, a
    jr nc, .csr_nc
    inc h
.csr_nc:
    dec e                       ; Z on the last line (the stores keep Z)
.csr_jump:
    jp 0
    repeat 8
    ld (hl), d
    inc hl
    rend
.csr_end:
    jp nz, .csr_row
.csr_sp:
    ld sp, 0
    ei
    pop bc
    ret

;; ---------------------------------------------------------------------------
;; DrawBitmapRect: Draw bitmap of D bytes wide x E scanlines high from HL to (B=X, C=Y)
;; Input:  B = X (0..95)
;;         C = Y (0..271)
;;         D = Width in bytes (1..DBR_MAX_WIDTH)
;;         E = Height in scanlines (1..255)
;;         HL = Pointer to bitmap data
;; Each row is copied by an unrolled LDI run entered D steps before its end.
;; Preserves: IX, IY, BC
;; ---------------------------------------------------------------------------
DBR_MAX_WIDTH   equ 36                  ; Title logo
DrawBitmapRect:
    push bc
    push hl
    ld a, d
    add a, a                    ; LDI is 2 bytes
    ld l, a
    ld h, 0
    push de
    ex de, hl
    ld hl, .dbr_unrolled_end
    or a
    sbc hl, de
    ld (.dbr_jump + 1), hl
    pop de

    ld a, b                     ; A = X
    ld l, c
    ld h, 0
    add hl, hl
    ld bc, line_tab
    add hl, bc                  ; HL = &line_tab[Y]
    ld c, a                     ; C = X
    ld b, e                     ; B = lines
    push hl
    push bc
    exx
    pop bc                      ; B' = lines, C' = X
    pop hl                      ; HL' = line table pointer
    exx
    pop hl                      ; HL = bitmap data
.dbr_row:
    exx
    ld a, (hl)
    inc hl
    add a, c
    ld e, a
    ld a, (hl)
    inc hl
    adc a, 0
    ld d, a                     ; DE' = scanline + X
    push de
    dec b                       ; Z on the last line (LDI keeps Z)
    exx
    pop de
.dbr_jump:
    jp 0
    repeat DBR_MAX_WIDTH
    ldi
    rend
.dbr_unrolled_end:
    jp nz, .dbr_row
    pop bc
    ret

;; ClearBitmapRect: Clear a rectangle to Pen 0.
;; Input: B=X byte, C=Y scanline, D=width bytes (1..CBR_MAX_WIDTH),
;;        E=height scanlines.
;; Preserves: IX, IY, BC
CBR_MAX_WIDTH   equ PF_W
ClearBitmapRect:
    push bc
    ld a, d
    add a, a
    ld l, a
    ld h, 0
    push de
    ex de, hl
    ld hl, .cbr_unrolled_end
    or a
    sbc hl, de
    ld (.cbr_jump + 1), hl      ; Enter the unrolled run D stores before its end
    pop de

    ld a, b                     ; A = X
    ld l, c
    ld h, 0
    add hl, hl
    ld bc, line_tab
    add hl, bc                  ; HL = &line_tab[Y]
    ld c, a                     ; C = X
    ld b, e                     ; B = lines
    push hl
    push bc
    exx
    pop bc
    pop hl
    exx
.cbr_row:
    exx
    ld a, (hl)
    inc hl
    add a, c
    ld e, a
    ld a, (hl)
    inc hl
    adc a, 0
    ld d, a
    push de
    dec b                       ; Z on the last line
    exx
    pop hl
    ld a, 0                     ; (keeps Z)
.cbr_jump:
    jp 0
    repeat CBR_MAX_WIDTH
    ld (hl), a
    inc hl
    rend
.cbr_unrolled_end:
    jp nz, .cbr_row
    pop bc
    ret
