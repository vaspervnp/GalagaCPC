;; ============================================================================
;; Galaga CPC - Video & Screen Memory Management
;; ============================================================================

;; ----------------------------------------------------------------------------
;; GetScreenAddr: Screen Address Calculator for Amstrad CPC Mode 0
;; Input:  B = X (byte column, 0..79)
;;         C = Y (scanline, 0..199)
;; Output: HL = Screen Memory Address (#C000 - #FFFF)
;; Preserves: IX, IY, BC
;; ----------------------------------------------------------------------------
GetScreenAddr:
    ;; Defensive clamp X: B <= 72 (mode 0 byte column, sprite width is 8 bytes: 72+8=80)
    ld a, b
    cp 73
    jr c, .x_clamp_ok
    ld b, 72
.x_clamp_ok:

    ;; Defensive clamp Y: C <= 184 (screen height 200 scanlines, sprite height 16: 184+16=200)
    ld a, c
    cp 185
    jr c, .y_clamp_ok
    ld c, 184
.y_clamp_ok:

    ;; Calculate base line offset within character row (scanline % 8)
    ld a, c
    and 7
    rlca
    rlca
    rlca
    add a, #C0
    ld h, a
    ld l, 0

    ;; Calculate character line offset (scanline / 8) via row_table
    ld a, c
    rrca
    rrca
    rrca
    and %00011111           ; a = scanline / 8 (0..23)
    add a, a                ; Word offset (0..46)
    ld e, a
    ld d, 0

    ;; Lookup in row_table without clobbering IX or IY
    push hl
    ld hl, row_table
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    pop hl
    add hl, de

    ;; Add horizontal byte offset X
    ld e, b
    ld d, 0
    add hl, de
    ret

;; ----------------------------------------------------------------------------
;; DrawSprite16x16: Draw 16x16 Mode 0 sprite (8 bytes wide x 16 scanlines)
;; Input:  HL = Pointer to sprite data
;;         DE = Screen destination address
;; ----------------------------------------------------------------------------
DrawSprite16x16:
    ld b, 16
.row_loop:
    push bc
    push de
    ld bc, 8
    ldir
    pop de
    call NextScanlineDE
    pop bc
    djnz .row_loop
    ret

;; ----------------------------------------------------------------------------
;; ClearSprite16x16: Erase 16x16 sprite area with black (Pen 0)
;; Input:  DE = Screen destination address
;; ----------------------------------------------------------------------------
ClearSprite16x16:
    ld b, 16
.clear_loop:
    push bc
    push de
    xor a
    ld h, d
    ld l, e
    ld (hl), a
    inc de
    ld bc, 7
    ldir
    pop de
    call NextScanlineDE
    pop bc
    djnz .clear_loop
    ret

;; ----------------------------------------------------------------------------
;; NextScanlineDE: Move DE down by 1 scanline in standard CPC screen memory
;; Input:  DE = Current screen address
;; Output: DE = Screen address of next scanline down
;; ----------------------------------------------------------------------------
NextScanlineDE:
    ld a, d
    add a, 8
    ld d, a
    ret nc
    ld a, d
    add a, #C0
    ld d, a
    ld a, e
    add a, #50
    ld e, a
    ret nc
    inc d
    ret

;; ----------------------------------------------------------------------------
;; Row Table for Scanline / 8 (25 lines of 80 bytes each, padded to 32 entries)
;; ----------------------------------------------------------------------------
row_table:
    defw 0, 80, 160, 240, 320, 400, 480, 560, 640, 720
    defw 800, 880, 960, 1040, 1120, 1200, 1280, 1360, 1440, 1520
    defw 1600, 1680, 1760, 1840, 1920
    ;; Safety padding: 7 entries so any 5-bit index (0..31) never reads out-of-bounds
    defw 1920, 1920, 1920, 1920, 1920, 1920, 1920
