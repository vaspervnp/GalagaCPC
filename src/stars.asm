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
    jr z, .check_game_over_stars

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

.check_game_over_stars:
    ;; Check if any banner/text is currently active in the playfield
    ld a, (stage_intro_state)
    or a
    jr nz, .is_text_protected

    ld a, (game_over)
    or a
    jr nz, .is_text_protected


    ld a, (stage_clear_active)
    or a
    jr z, .chk_cap_stars
    ld a, (stage_clear_timer)
    cp 51
    jr nc, .chk_cap_stars
    cp 2
    jr nc, .is_text_protected

.chk_cap_stars:
    ld a, (capture_delay)
    or a
    jr nz, .is_text_protected

    ld a, (is_challenging_stage)
    or a
    jr z, .chk_prio_stars
    ld a, (challenging_active)
    cp 2
    jr z, .is_text_protected

.chk_prio_stars:
    ld a, (priority_text_active)
    or a
    jr z, .normal_star

.is_text_protected:
    ;; If text is active, protect banner rect: Scanlines 96..126, X=20..78
    ld a, (ix+1)            ; Y coordinate
    cp 96
    jr c, .normal_star
    cp 126
    jr nc, .normal_star

    ld a, (ix+0)            ; X coordinate
    cp 20
    jr c, .normal_star
    cp 78
    jr nc, .normal_star

    ;; Star is inside active text box: Advance Y without drawing or erasing
    ld a, (ix+1)
    add a, (ix+3)
    cp 228
    jr c, .prot_y_ok
    sub 194
.prot_y_ok:
    ld (ix+1), a
    jr .next_star


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

