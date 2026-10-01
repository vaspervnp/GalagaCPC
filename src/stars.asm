;; ============================================================================
;; Galaga CPC - Moving Starfield Background
;; Title screen: full width, Y=34..227 (below the title HUD).
;; In play: playfield only (X shifted by STAR_GAME_DX), Y=PF_Y_TOP..STAR_GAME_Y_END-1.
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
    ;; In play the star table's X range (11..81) is moved left by STAR_GAME_DX
    ;; so stars cover the playfield and stay out of the HUD column.
    ld a, (is_title_screen)
    or a
    ld a, (ix+0)
    jr nz, .star_x_ready
    add a, STAR_GAME_DX
.star_x_ready:
    ld (star_draw_x), a

    ;; 1. Erase star at current position (only if pixel matches star color)
    push bc
    ld b, a                 ; x
    ld c, (ix+1)            ; y
    call GetScreenAddr
    ld a, (hl)
    cp (ix+2)
    jr nz, .no_erase_star
    xor a
    ld (hl), a              ; Erase star with black
.no_erase_star:
    pop bc

    ;; 2. Advance y by speed with smooth wrapping (preserving phase). The
    ;; title screen keeps its top HUD clear; in play stars use the full height.
    ld a, (is_title_screen)
    or a
    ld a, (ix+1)
    jr z, .game_star_y
    add a, (ix+3)
    cp 228
    jr c, .y_ok
    sub 194
    jr .y_ok
.game_star_y:
    add a, (ix+3)           ; y + speed
    cp STAR_GAME_Y_END
    jr c, .y_ok
    sub STAR_GAME_Y_END - PF_Y_TOP
.y_ok:
    ld (ix+1), a

    ;; 3. Draw star at new position (only if space is empty black)
    push bc
    ld a, (star_draw_x)
    ld b, a
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
;; Only used during play, so the in-game X offset applies.
RedrawStars:
    push ix
    push bc
    ld ix, stars_data
    ld b, NUM_STARS
.redraw_star_loop:
    push bc
    ld a, (ix+0)
    add a, STAR_GAME_DX
    ld b, a
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
    pop bc
    pop ix
    ret
