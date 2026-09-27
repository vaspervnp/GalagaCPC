;; ============================================================================
;; Galaga CPC - Moving Starfield Background
;; Overscan Geometry (Playfield Y=34..228, Upper Border Y<32, Lower Border Y>232)
;; ============================================================================

UpdateStars:
    ld ix, stars_data
    ld b, NUM_STARS
.star_loop:
    ld a, (game_over)
    or a
    jr z, .normal_star

    ;; If Game Over is active, protect "GAME OVER" text area:
    ;; Banner rect: Scanlines 108..120, Mode 0 bytes 32..64
    ld a, (ix+1)            ; Y coordinate
    cp 108
    jr c, .normal_star
    cp 120
    jr nc, .normal_star

    ld a, (ix+0)            ; X coordinate
    cp 32
    jr c, .normal_star
    cp 64
    jr nc, .normal_star

    ;; Star is inside "GAME OVER" box: Advance Y without drawing or erasing
    ld a, (ix+1)
    add a, (ix+3)
    ld (ix+1), a
    jr .next_star

.normal_star:
    ;; 1. Erase star at current position
    push bc
    ld b, (ix+0)            ; x
    ld c, (ix+1)            ; y
    call GetScreenAddr
    xor a
    ld (hl), a              ; Erase with black
    pop bc

    ;; 2. Advance y by speed
    ld a, (ix+1)
    add a, (ix+3)           ; y + speed
    cp 228
    jr c, .y_ok
    ld a, 34                ; Wrap to top safely below HUD
.y_ok:
    ld (ix+1), a

    ;; 3. Draw star at new position
    push bc
    ld b, (ix+0)
    ld c, (ix+1)
    call GetScreenAddr
    ld a, (ix+2)            ; star color byte
    ld (hl), a
    pop bc

.next_star:
    ld de, 4
    add ix, de
    djnz .star_loop
    ret
