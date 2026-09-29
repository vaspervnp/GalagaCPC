;; ============================================================================
;; Galaga CPC - Moving Starfield Background
;; Overscan Geometry (Playfield Y=34..228, Upper Border Y<32, Lower Border Y>232)
;; ============================================================================

UpdateStars:
    ld ix, stars_data
    ld b, NUM_STARS
.star_loop:
    ld a, (is_title_screen)
    or a
    jr z, .normal_star

    ;; Protect Title Screen center content (X=20..84, Y=34..230)
    ld a, (ix+0)            ; X coordinate
    cp 20
    jr c, .normal_star
    cp 84
    jr nc, .normal_star

    ;; Inside title content: advance Y without drawing/erasing to preserve graphics
    ld a, (ix+1)
    add a, (ix+3)
    cp 228
    jr c, .t_y_ok
    sub 194
.t_y_ok:
    ld (ix+1), a
    jp .next_star

.normal_star:
    ;; 1. Erase star at current position (only if pixel matches star color)
    push bc
    ld b, (ix+0)            ; x
    ld c, (ix+1)            ; y
    call GetScreenAddr
    ld a, (hl)
    cp (ix+2)
    jr nz, .no_erase_star
    xor a
    ld (hl), a              ; Erase star with black
.no_erase_star:
    pop bc

    ;; 2. Advance y by speed with smooth wrapping
    ld a, (ix+1)
    add a, (ix+3)           ; y + speed
    cp 228
    jr c, .y_ok
    sub 194                 ; Wrap to top safely below HUD preserving phase
.y_ok:
    ld (ix+1), a

    ;; 3. Draw star at new position (only if space is empty black)
    push bc
    ld b, (ix+0)
    ld c, (ix+1)
    call GetScreenAddr
    ld a, (hl)
    or a
    jr nz, .no_draw_star    ; Occulted by sprite/text in foreground!
    ld a, (ix+2)            ; star color byte
    ld (hl), a
.no_draw_star:
    pop bc

.next_star:
    ld de, 4
    add ix, de
    dec b
    jp nz, .star_loop
    ret

;; Restore any background stars cleared while removing foreground sprites.
RedrawStars:
    ld ix, stars_data
    ld b, NUM_STARS
.redraw_star_loop:
    push bc
    ld b, (ix+0)
    ld c, (ix+1)
    call GetScreenAddr
    ld a, (hl)
    or a
    jr nz, .redraw_star_done
    ld a, (ix+2)
    ld (hl), a
.redraw_star_done:
    pop bc
    ld de, 4
    add ix, de
    djnz .redraw_star_loop
    ret
