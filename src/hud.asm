;; ============================================================================
;; Galaga CPC - HUD: right-hand column during play, top rows on title screens
;; Amstrad CPC 464 / 6128 Overscan Mode
;; ============================================================================

;; ----------------------------------------------------------------------------
;; InitHUD - Draw the in-game HUD column headers and initial scores
;; ----------------------------------------------------------------------------
InitHUD:
    ld a, 1
    ld (hud_in_column), a
    call DrawHudDivider

    ld b, HUD_TEXT_X
    ld c, HUD_1UP_Y
    ld hl, str_1up_hdr
    call DrawGlyphString

    ld a, (two_player)
    or a
    jr z, .one_player
    ld b, HUD_TEXT_X
    ld c, HUD_2UP_Y
    ld hl, str_2up_hdr
    call DrawGlyphString
    call PrintOtherScore
.one_player:

    ld b, HUD_TEXT_X
    ld c, HUD_HIGH_Y
    ld hl, str_high_hdr
    call DrawGlyphString
    ld b, HUD_TEXT_X
    ld c, HUD_HIGH2_Y
    ld hl, str_score_hdr
    call DrawGlyphString
    ld b, HUD_TEXT_X
    ld c, HUD_STAGE_Y
    ld hl, str_stage_hdr
    call DrawGlyphString

    call PrintScore
    call PrintHighScore
    ret

;; DrawHudDivider - Thin vertical line between the playfield and the HUD column
DrawHudDivider:
    ld ix, line_tab
    ld de, DISPLAY_LINES
.line:
    ld l, (ix+0)
    ld h, (ix+1)
    ld bc, HUD_DIVIDER_X
    add hl, bc
    ld (hl), HUD_DIVIDER_BYTE
    inc ix
    inc ix
    dec de
    ld a, d
    or e
    jr nz, .line
    ret

;; ----------------------------------------------------------------------------
;; InitTitleHUD - Title and initials screens keep the original top HUD
;; ----------------------------------------------------------------------------
InitTitleHUD:
    xor a
    ld (hud_in_column), a

    ;; 1. Draw '1UP' (or '2UP' for player 2's initials) in Red at X=16
    call ActiveLabelPos
    ld b, 16
    ld c, TITLE_HUD_Y0
    call DrawGlyphString

    ;; 2. Draw 'HIGH SCORE' in Red at X=46
    ld b, 46
    ld c, TITLE_HUD_Y0
    ld hl, str_high_score_hdr
    call DrawGlyphString

    ;; 3. Initial Scores in White
    call PrintScore
    call PrintHighScore
    ret

str_1up_hdr:
    defw f_r_1, f_r_U, f_r_P, 0

str_2up_hdr:
    defw f_r_2, f_r_U, f_r_P, 0

str_high_score_hdr:
    defw f_r_H, f_r_I, f_r_G, f_r_H, f_r_SPACE
str_score_hdr:
    defw f_r_S, f_r_C, f_r_O, f_r_R, f_r_E, 0

str_high_hdr:
    defw f_r_H, f_r_I, f_r_G, f_r_H, 0

str_stage_hdr:
    defw f_r_S, f_r_T, f_r_A, f_r_G, f_r_E, 0

;; ----------------------------------------------------------------------------
;; PrintScore - Print player_score (6 digits, White) in the active HUD layout,
;; on the active player's row of the HUD column.
;; ----------------------------------------------------------------------------
PrintScore:
    ld hl, (player_score)
    ld a, (player_score_hi)
    ld de, (14 << 8) | TITLE_HUD_Y1
    push af
    ld a, (active_player)
    or a
    ld bc, (HUD_TEXT_X << 8) | HUD_SCORE_Y
    jr z, .player1
    ld c, HUD_SCORE2_Y
.player1:
    pop af
    jr PrintScoreAt

;; PrintOtherScore - Print the inactive player's score in the HUD column
PrintOtherScore:
    ld hl, (player_score + OTHER_PLAYER)
    ld a, (active_player)
    or a
    ld bc, (HUD_TEXT_X << 8) | HUD_SCORE2_Y
    jr z, .player2
    ld c, HUD_SCORE_Y
.player2:
    ld a, (player_score_hi + OTHER_PLAYER)
    jp Print6Digits

;; ----------------------------------------------------------------------------
;; BlinkActiveLabel - Blink the active player's "1UP" / "2UP" label
;; ----------------------------------------------------------------------------
BlinkActiveLabel:
    ld a, (hud_blink)
    inc a
    ld (hud_blink), a
    and 7
    ret nz
    ld a, (hud_blink)
    and 8
    jr z, ClearActiveLabel
DrawActiveLabel:
    call ActiveLabelPos
    jp DrawGlyphString
ClearActiveLabel:
    call ActiveLabelPos
    ld d, 9
    jp ClearTextRect

;; ActiveLabelPos - B,C = HUD column position and HL = label of active player
ActiveLabelPos:
    ld b, HUD_TEXT_X
    ld a, (active_player)
    or a
    ld c, HUD_1UP_Y
    ld hl, str_1up_hdr
    ret z
    ld c, HUD_2UP_Y
    ld hl, str_2up_hdr
    ret

;; ----------------------------------------------------------------------------
;; PrintHighScore - Print high_score (6 digits, White) in the active HUD layout
;; ----------------------------------------------------------------------------
PrintHighScore:
    ld hl, (high_score)
    ld a, (high_score_hi)
    ld bc, (HUD_TEXT_X << 8) | HUD_HISCORE_Y
    ld de, (50 << 8) | TITLE_HUD_Y1

;; Print A:HL at BC in the HUD column, or at DE on the title screens.
PrintScoreAt:
    push af
    ld a, (hud_in_column)
    or a
    jr nz, .column
    ld b, d
    ld c, e
.column:
    pop af
    jp Print6Digits

;; ----------------------------------------------------------------------------
;; Print6Digits - Format 24-bit (A:HL) into 6 decimal digits at (B=X, C=Y)
;; ----------------------------------------------------------------------------
Print6Digits:
    push ix
    push bc
    ld (digit_buf_temp_a), a

    ;; Digit 0: 100,000s (sub 100,000: HL - 34464, A - 1 - borrow)
    ld c, 0
.div_100k:
    ld a, (digit_buf_temp_a)
    ld de, 34464
    or a
    sbc hl, de
    sbc a, 1
    jr c, .done_100k
    ld (digit_buf_temp_a), a
    inc c
    jr .div_100k
.done_100k:
    add hl, de          ; Restore HL (remainder)
    ld a, c
    ld (digit_buf+0), a

    ;; Digit 1: 10,000s (sub 10,000: HL - 10000, A - 0 - borrow)
    ld c, 0
.div_10k:
    ld a, (digit_buf_temp_a)
    ld de, 10000
    or a
    sbc hl, de
    sbc a, 0
    jr c, .done_10k
    ld (digit_buf_temp_a), a
    inc c
    jr .div_10k
.done_10k:
    add hl, de          ; Restore HL (remainder < 10,000)
    ld a, c
    ld (digit_buf+1), a

    ;; Digits 2..5: 16-bit remainder in HL
    ld de, 1000  : call .div_digit_6 : ld (digit_buf+2), a
    ld de, 100   : call .div_digit_6 : ld (digit_buf+3), a
    ld de, 10    : call .div_digit_6 : ld (digit_buf+4), a
    ld a, l                          : ld (digit_buf+5), a

    ;; Suppress leading zeros for first 4 digits (indices 0..3)
    ld ix, digit_buf
    ld b, 4
.blank_loop:
    ld a, (ix+0)
    or a
    jr nz, .blank_done
    ld (ix+0), 10       ; 10 = space
    inc ix
    djnz .blank_loop
.blank_done:
    pop bc

    ;; Draw 6 digits from digit_buf
    ld ix, digit_buf
    ld d, 6
.draw_d6_loop:
    ld a, (ix+0)
    inc ix
    push bc
    push de
    call DrawWhiteDigit
    pop de
    pop bc
    ld a, b
    add a, 3            ; 2 bytes digit width + 1 byte space
    ld b, a
    dec d
    jr nz, .draw_d6_loop
    pop ix
    ret

.div_digit_6:
    ld a, '0' - 1
.sub_loop_6:
    inc a
    or a
    sbc hl, de
    jr nc, .sub_loop_6
    add hl, de
    sub '0'
    ret

;; ----------------------------------------------------------------------------
;; Print5Digits - Format 16-bit HL into 5 decimal digits at (B=X, C=Y)
;; ----------------------------------------------------------------------------
Print5Digits:
    push ix
    push bc
    ld de, 10000 : call .div_digit : ld (digit_buf+0), a
    ld de, 1000  : call .div_digit : ld (digit_buf+1), a
    ld de, 100   : call .div_digit : ld (digit_buf+2), a
    ld de, 10    : call .div_digit : ld (digit_buf+3), a
    ld a, l                        : ld (digit_buf+4), a
    pop bc

    ;; Draw 5 digits from digit_buf
    ld ix, digit_buf
    ld d, 5
.draw_d_loop:
    ld a, (ix+0)
    inc ix
    push bc
    push de
    call DrawWhiteDigit
    pop de
    pop bc
    ld a, b
    add a, 3            ; 2 bytes digit width + 1 byte space
    ld b, a
    dec d
    jr nz, .draw_d_loop
    pop ix
    ret

.div_digit:
    ld a, '0' - 1
.sub_loop:
    inc a
    or a
    sbc hl, de
    jr nc, .sub_loop
    add hl, de
    sub '0'
    ret

;; ----------------------------------------------------------------------------
;; DrawGameOverText - "GAME OVER" in Cyan, centred in the playfield
;; ----------------------------------------------------------------------------
GAME_OVER_X     equ PF_X_CENTER - 13        ; 9 characters = 27 bytes

DrawGameOverText:
    ld b, GAME_OVER_X
    ld c, PF_TEXT_Y
    ld hl, str_game_over_banner
    jp DrawGlyphString

ClearGameOverText:
    ld b, GAME_OVER_X
    ld c, PF_TEXT_Y
    ld d, 27
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; Messages are centred in the playfield. STAGE, PLAYER and FIGHTER CAPTURED
;; share the GAME OVER line (never shown together); PAUSE sits below it.
;; ----------------------------------------------------------------------------
STAGE_BANNER_X  equ PF_X_CENTER - 11        ; "STAGE nn" (8 characters)
PLAYER_BANNER_X equ PF_X_CENTER - 12        ; "PLAYER n" (8 characters)
CAPTURED_BANNER_X equ PF_X_CENTER - 24      ; "FIGHTER CAPTURED" (16 characters)
PAUSE_BANNER_X  equ PF_X_CENTER - 7         ; "PAUSE" (5 characters)
PAUSE_BANNER_Y  equ PF_TEXT_Y + 16

;; DrawPauseBanner - "PAUSE" in Cyan
DrawPauseBanner:
    ld b, PAUSE_BANNER_X
    ld c, PAUSE_BANNER_Y
    ld hl, str_pause_banner
    jp DrawGlyphString

ClearPauseBanner:
    ld b, PAUSE_BANNER_X
    ld c, PAUSE_BANNER_Y
    ld d, 15
    jp ClearTextRect

;; DrawStageBanner - "STAGE " + current_stage
DrawStageBanner:
    ld b, STAGE_BANNER_X
    ld c, PF_TEXT_Y
    ld hl, str_stage_banner
    call DrawGlyphString        ; B advances past "STAGE "
    ld a, (current_stage)
    cp 10
    jp c, DrawWhiteDigit
    jp Draw2DigitsWhite

ClearStageBanner:
    ld b, STAGE_BANNER_X
    ld c, PF_TEXT_Y
    ld d, 27                    ; Room for 3 digits
    jp ClearTextRect

;; DrawPlayerBanner - "PLAYER 1" / "PLAYER 2"
DrawPlayerBanner:
    ld b, PLAYER_BANNER_X
    ld c, PF_TEXT_Y
    ld hl, str_player_banner
    call DrawGlyphString        ; B advances past "PLAYER "
    ld a, (active_player)
    inc a
    jp DrawWhiteDigit

ClearPlayerBanner:
    ld b, PLAYER_BANNER_X
    ld c, PF_TEXT_Y
    ld d, 24
    jp ClearTextRect

;; DrawChallengingBanner - "CHALLENGING STAGE"
CHALLENGING_BANNER_X equ PF_X_CENTER - 25   ; 17 characters = 51 bytes

DrawChallengingBanner:
    ld b, CHALLENGING_BANNER_X
    ld c, PF_TEXT_Y
    ld hl, str_challenging_banner
    jp DrawGlyphString

ClearChallengingBanner:
    ld b, CHALLENGING_BANNER_X
    ld c, PF_TEXT_Y
    ld d, 51
    jp ClearTextRect

;; DrawFighterCapturedBanner - "FIGHTER CAPTURED"
DrawFighterCapturedBanner:
    ld b, CAPTURED_BANNER_X
    ld c, PF_TEXT_Y
    ld hl, str_fighter_captured_banner
    jp DrawGlyphString

ClearFighterCapturedBanner:
    ld b, CAPTURED_BANNER_X
    ld c, PF_TEXT_Y
    ld d, 48
    jp ClearTextRect

str_game_over_banner:
    defw f_c_G, f_c_A, f_c_M, f_c_E, f_c_SPACE, f_c_O, f_c_V, f_c_E, f_c_R, 0

str_pause_banner:
    defw f_c_P, f_c_A, f_c_U, f_c_S, f_c_E, 0

str_stage_banner:
    defw f_c_S, f_c_T, f_c_A, f_c_G, f_c_E, f_c_SPACE, 0

str_player_banner:
    defw f_c_P, f_c_L, f_c_A, f_c_Y, f_c_E, f_c_R, f_c_SPACE, 0

str_challenging_banner:
    defw f_c_C, f_c_H, f_c_A, f_c_L, f_c_L, f_c_E, f_c_N, f_c_G, f_c_I, f_c_N, f_c_G, f_c_SPACE, f_c_S, f_c_T, f_c_A, f_c_G, f_c_E, 0

str_fighter_captured_banner:
    defw f_c_F, f_c_I, f_c_G, f_c_H, f_c_T, f_c_E, f_c_R, f_c_SPACE
    defw f_c_C, f_c_A, f_c_P, f_c_T, f_c_U, f_c_R, f_c_E, f_c_D, 0

;; ----------------------------------------------------------------------------
;; ClearTextRect - Erase D bytes wide x 8 scanlines high starting at (B=X, C=Y)
;; ----------------------------------------------------------------------------
ClearTextRect:
    ld a, 8
.ctr_row:
    push af
    push bc
    push de
    call GetScreenAddr
    pop de
    ld b, d
    xor a
.ctr_col:
    ld (hl), a
    inc hl
    djnz .ctr_col
    pop bc
    pop af
    inc c
    dec a
    jr nz, .ctr_row
    ret

;; ----------------------------------------------------------------------------
;; SetPriorityText - Register custom text to display with priority over sprites
;; Input:  B = X, C = Y, HL = null-terminated glyph pointer string
;; ----------------------------------------------------------------------------
SetPriorityText:
    ld a, b : ld (priority_text_x), a
    ld a, c : ld (priority_text_y), a
    ld (priority_text_ptr), hl
    ld a, 1
    ld (priority_text_active), a
    jp DrawGlyphString

;; ----------------------------------------------------------------------------
;; ClearPriorityText - Clear custom priority text from screen
;; Input:  B = X, C = Y, D = width in bytes
;; ----------------------------------------------------------------------------
ClearPriorityText:
    xor a
    ld (priority_text_active), a
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; RefreshPriorityText - Redraw any active text/banners on top of all sprites
;; Ensures text always has priority ("Τα γράμματα έχουν πάντα προτεραιότητα")
;; ----------------------------------------------------------------------------
RefreshPriorityText:
    ;; Check if game is paused
    ld a, (pause_active)
    or a
    jr z, .rpt_not_paused
    call DrawPauseBanner
    ret

.rpt_not_paused:
    ;; 0. Check Stage Intro State (Level 1 Intro)
    ld a, (stage_intro_state)
    or a
    jr z, .rpt_check_custom
    cp 1
    jr nz, .rpt_intro_2
    call DrawStageBanner
    jr .rpt_check_custom
.rpt_intro_2:
    cp 2
    jr nz, .rpt_check_custom
    call DrawPlayerBanner

.rpt_check_custom:
    ;; 1. Check custom registered priority text
    ld a, (priority_text_active)
    or a
    jr z, .rpt_check_game_over
    push bc
    ld a, (priority_text_x)
    ld b, a
    ld a, (priority_text_y)
    ld c, a
    ld hl, (priority_text_ptr)
    call DrawGlyphString
    pop bc

.rpt_check_game_over:
    ;; One player out in a 2-player game: "GAME OVER" until the hand-over
    ld a, (player_out)
    or a
    call nz, DrawGameOverText

    ;; 2. Check Game Over banner (Phase 0) or Results Screen (Phase 1)
    ld a, (game_over)
    or a
    jr z, .rpt_check_stage_clear
    ld a, (game_over_phase)
    or a
    jr nz, .rpt_check_results
    call DrawGameOverText
    ret
.rpt_check_results:
    cp 1
    jr nz, .rpt_check_stage_clear
    call DrawResultsScreen
    ret

.rpt_check_stage_clear:
    ;; 3. Check Stage Clear / Stage Banner ("STAGE X" or "CHALLENGING STAGE")
    ld a, (stage_clear_active)
    or a
    jr z, .rpt_check_capture
    ld a, (stage_clear_timer)
    cp 26
    jr nc, .rpt_check_capture   ; Not yet showing banner (timer > 25)
    cp 2
    jr c, .rpt_check_capture    ; Banner is being cleared (timer < 2)

    ;; Check if current stage is Challenging Stage (already advanced at timer=50)
    ld a, (current_stage)
    and 3
    cp 3
    jr z, .rpt_draw_ch_banner
    call DrawStageBanner
    jr .rpt_check_capture

.rpt_draw_ch_banner:
    call DrawChallengingBanner

.rpt_check_capture:
    ;; 4. Check Fighter Captured Banner
    ld a, (capture_delay)
    or a
    jr z, .rpt_check_challenging_results
    call DrawFighterCapturedBanner

.rpt_check_challenging_results:
    ;; 5. Check Challenging Stage Results text
    ld a, (is_challenging_stage)
    or a
    ret z
    ld a, (challenging_active)
    cp 2
    ret nz
    jp DrawChallengingResults

;; ----------------------------------------------------------------------------
;; Draw2DigitsWhite - Format 2-digit number in A (0..99) at (B=X, C=Y)
;; ----------------------------------------------------------------------------
Draw2DigitsWhite:
    push bc
    ld d, 0
.d2_tens:
    cp 10
    jr c, .d2_done
    sub 10
    inc d
    jr .d2_tens
.d2_done:
    ld e, a             ; E = ones, D = tens
    ld a, d
    push de
    call DrawWhiteDigit
    pop de
    pop bc
    ld a, b
    add a, 3
    ld b, a
    ld a, e
    jp DrawWhiteDigit

;; PrintStageNumber - Current stage (1..255) in the HUD column, right-aligned
;; with the scores and without leading zeros
PrintStageNumber:
    ld b, HUD_TEXT_X + 9
    ld c, HUD_STAGE_NUM_Y
    ld a, (current_stage)
    ld e, 10                ; Hundreds digit: 10 draws a blank
    cp 100
    jr c, .digits
    ld e, 0
.hundreds:
    inc e
    sub 100
    cp 100
    jr nc, .hundreds
.digits:
    push af                 ; A = stage mod 100
    ld a, e
    push af
    call DrawWhiteDigit
    inc b : inc b : inc b
    pop de                  ; D = hundreds digit
    pop af
    cp 10
    jp nc, Draw2DigitsWhite
    ld e, a
    ld a, d
    cp 10
    ld a, e
    jp c, Draw2DigitsWhite  ; 1xx / 2xx: keep the zero in the tens
    push af
    ld a, 10
    call DrawWhiteDigit     ; Blank tens
    inc b : inc b : inc b
    pop af
    jp DrawWhiteDigit

digit_buf:          defs 6, 0
digit_buf_temp_a:   defb 0

;; ----------------------------------------------------------------------------
;; DrawWhiteDigit - Draw single digit A (0..9) at (B=X, C=Y) in White.
;; If A >= 10, draws space (f_w_SPACE).
;; ----------------------------------------------------------------------------
DrawWhiteDigit:
    push bc
    cp 10
    jr c, .is_digit
    ld hl, f_w_SPACE
    pop bc
    jp DrawGlyph
.is_digit:
    ld l, a
    ld h, 0
    add hl, hl          ; *2
    add hl, hl          ; *4
    add hl, hl          ; *8
    add hl, hl          ; *16 (16 bytes per glyph)
    ld de, f_w_0
    add hl, de
    pop bc
    jp DrawGlyph

;; ----------------------------------------------------------------------------
;; DrawGlyph - Transfer 4x8 glyph (2 bytes x 8 lines) to screen at B=X, C=Y
;; Input:  B = X (0..93), C = Y (0..255), HL = glyph pointer (16 bytes)
;; Preserves: BC, IX, IY
;; ----------------------------------------------------------------------------
DrawGlyph:
    ;; Y on a character row boundary: the 8 lines are #800 apart, so one
    ;; table lookup serves the whole glyph (text redrawn every frame uses this)
    ld a, c
    and 7
    jr nz, .any_y
    push bc
    push hl
    ld l, c
    ld h, 0
    add hl, hl
    ld de, line_tab
    add hl, de
    ld a, (hl)
    inc hl
    ld h, (hl)
    add a, b
    ld l, a
    jr nc, .row_nc
    inc h
.row_nc:
    ex de, hl                   ; DE = screen
    pop hl                      ; HL = glyph
    ld bc, #08FF                ; B = lines; C keeps LDI off B
.row_line:
    ldi
    ldi
    xor a
    ld (de), a                  ; Black gap byte masks sprites underneath
    dec de
    dec de
    ld a, d
    add a, 8                    ; Next scanline of the character row
    ld d, a
    djnz .row_line
    pop bc
    ret

.any_y:
    push ix
    push bc
    push hl
    ld e, c
    ld d, 0
    sla e
    rl d                ; DE = Y * 2 (16-bit safe for Y up to 271)
    ld ix, line_tab
    add ix, de          ; IX = line_tab pointer
    pop hl              ; HL = glyph data
    ld c, 8             ; 8 lines
.g_line:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .g_nc
    inc d
.g_nc:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    xor a
    ld (de), a          ; Ensure 3rd gap byte is black, masking underlying sprites
    dec c
    jr nz, .g_line
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; DrawLivesHUD - Draw reserve fighter ships as a 2 x 2 grid in the HUD column
;; ----------------------------------------------------------------------------
DrawLivesHUD:
    ld b, LIVES_X : ld c, LIVES_Y : ld d, 16 : ld e, 34 : call ClearBitmapRect

    ld a, (player_lives)
    cp 2
    ret c               ; 1 or 0 lives: no reserve ships shown

    ;; Reserve Ship 1
    ld b, LIVES_X
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 3
    ret c

    ;; Reserve Ship 2
    ld b, LIVES_X + 8
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 4
    ret c

    ;; Reserve Ship 3
    ld b, LIVES_X
    ld c, LIVES_Y + 18
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 5
    ret c

    ;; Reserve Ship 4
    ld b, LIVES_X + 8
    ld c, LIVES_Y + 18
    ld hl, player_sprite
    call DrawSprite16x16
    ret

;; ----------------------------------------------------------------------------
;; DrawStageHUD - Draw stage ribbons in three rows below the reserve ships
;; ----------------------------------------------------------------------------
DrawStageHUD:
    call PrintStageNumber
    ld b, HUD_X : ld c, BADGES_Y : ld d, HUD_W : ld e, BADGES_Y3 + 16 - BADGES_Y
    call ClearBitmapRect
    ld a, BADGES_Y
    ld (badge_draw_y), a

    ;; Decompose the stage into the six badge values, largest first.
    ld a, (current_stage)
    ld b, 0
.count_50:
    cp 50
    jr c, .store_50
    sub 50
    inc b
    jr .count_50
.store_50:
    push af
    ld a, b
    ld (stage_badge_50_count), a
    pop af
    ld b, 0
.count_30:
    cp 30
    jr c, .store_30
    sub 30
    inc b
    jr .count_30
.store_30:
    push af
    ld a, b
    ld (stage_badge_30_count), a
    pop af
    ld b, 0
.count_20:
    cp 20
    jr c, .store_20
    sub 20
    inc b
    jr .count_20
.store_20:
    push af
    ld a, b
    ld (stage_badge_20_count), a
    pop af
    ld b, 0
.count_10:
    cp 10
    jr c, .store_10
    sub 10
    inc b
    jr .count_10
.store_10:
    push af
    ld a, b
    ld (stage_badge_10_count), a
    pop af
    ld b, 0
.count_5:
    cp 5
    jr c, .store_5
    sub 5
    inc b
    jr .count_5
.store_5:
    push af
    ld a, b
    ld (stage_badge_5_count), a
    pop af
    ld (stage_badge_1_count), a

    ;; Place the largest badges at the right; smaller badges follow to the left.
    ld a, BYTES_PER_LINE - 9
    ld (badge_draw_x), a
    ld a, (stage_badge_50_count)
    ld hl, badge_stage_50
    ld d, badge_stage_50_width
    ld e, badge_stage_50_height
    call DrawStageBadgeGroup
    ld a, (stage_badge_30_count)
    ld hl, badge_stage_30
    ld d, badge_stage_30_width
    ld e, badge_stage_30_height
    call DrawStageBadgeGroup
    ld a, (stage_badge_20_count)
    ld hl, badge_stage_20
    ld d, badge_stage_20_width
    ld e, badge_stage_20_height
    call DrawStageBadgeGroup
    ld a, (stage_badge_10_count)
    ld hl, badge_stage_10
    ld d, badge_stage_10_width
    ld e, badge_stage_10_height
    call DrawStageBadgeGroup
    ld a, (stage_badge_5_count)
    ld hl, badge_stage_5
    ld d, badge_stage_5_width
    ld e, badge_stage_5_height
    call DrawStageBadgeGroup
    ld a, (stage_badge_1_count)
    ld hl, badge_stage_1
    ld d, badge_stage_1_width
    ld e, badge_stage_1_height
    call DrawStageBadgeGroup
    ret

;; Draw a group of identical badges from right to left, continuing on the
;; second row when the first is full.
;; Input: A=count, HL=sprite data, D=byte width, E=height.
DrawStageBadgeGroup:
    ld (badge_group_count), a
    ld (badge_group_sprite), hl
    ld a, d
    ld (badge_group_width), a
    ld a, e
    ld (badge_group_height), a
.next_badge:
    ld a, (badge_group_count)
    or a
    ret z
    ld a, (badge_draw_x)
    cp HUD_X
    jr nc, .badge_fits
    ;; Row full: continue on the next row, or stop after the third.
    ld a, (badge_draw_y)
    cp BADGES_Y3
    ret z
    add a, BADGES_ROW_H
    ld (badge_draw_y), a
    ld a, BYTES_PER_LINE - 9
    ld (badge_draw_x), a
.badge_fits:
    ld b, a
    ld a, (badge_draw_y)
    ld c, a
    ld a, (badge_group_width)
    ld d, a
    ld a, (badge_group_height)
    ld e, a
    ld hl, (badge_group_sprite)
    call DrawBitmapRect

    ld a, (badge_draw_x)
    ld b, a
    ld a, (badge_group_width)
    inc a
    ld c, a
    ld a, b
    sub c
    ld (badge_draw_x), a
    ld hl, badge_group_count
    dec (hl)
    jr .next_badge

badge_draw_x:        defb 0
badge_draw_y:        defb 0
badge_group_count:   defb 0
badge_group_width:   defb 0
badge_group_height:  defb 0
badge_group_sprite:  defw 0
stage_badge_50_count: defb 0
stage_badge_30_count: defb 0
stage_badge_20_count: defb 0
stage_badge_10_count: defb 0
stage_badge_5_count:  defb 0
stage_badge_1_count:  defb 0

;; --- White Font (Pen 15) ---
f_w_0:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_1:
    defb #00, #AA
    defb #55, #AA
    defb #00, #AA
    defb #00, #AA
    defb #00, #AA
    defb #00, #AA
    defb #55, #FF
    defb #00, #00
f_w_2:
    defb #55, #AA
    defb #AA, #55
    defb #00, #55
    defb #00, #AA
    defb #55, #00
    defb #AA, #00
    defb #FF, #FF
    defb #00, #00
f_w_3:
    defb #FF, #AA
    defb #00, #55
    defb #00, #55
    defb #55, #AA
    defb #00, #55
    defb #00, #55
    defb #FF, #AA
    defb #00, #00
f_w_4:
    defb #00, #AA
    defb #55, #AA
    defb #AA, #AA
    defb #FF, #FF
    defb #00, #AA
    defb #00, #AA
    defb #00, #AA
    defb #00, #00
f_w_5:
    defb #FF, #FF
    defb #AA, #00
    defb #FF, #AA
    defb #00, #55
    defb #00, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_6:
    defb #55, #AA
    defb #AA, #00
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_7:
    defb #FF, #FF
    defb #00, #55
    defb #00, #AA
    defb #00, #AA
    defb #55, #00
    defb #55, #00
    defb #55, #00
    defb #00, #00
f_w_8:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_9:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #55, #FF
    defb #00, #55
    defb #00, #55
    defb #55, #AA
    defb #00, #00
font_alpha_white:
f_w_A:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #FF, #FF
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_B:
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #FF, #AA
    defb #00, #00
f_w_C:
    defb #55, #FF
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #55, #FF
    defb #00, #00
f_w_D:
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #FF, #AA
    defb #00, #00
f_w_E:
    defb #FF, #FF
    defb #AA, #00
    defb #AA, #00
    defb #FF, #AA
    defb #AA, #00
    defb #AA, #00
    defb #FF, #FF
    defb #00, #00
f_w_F:
    defb #FF, #FF
    defb #AA, #00
    defb #AA, #00
    defb #FF, #AA
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #00, #00
f_w_G:
    defb #55, #FF
    defb #AA, #00
    defb #AA, #00
    defb #AA, #FF
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_H:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #FF, #FF
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_I:
    defb #FF, #FF
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #FF, #FF
    defb #00, #00
f_w_J:
    defb #00, #55
    defb #00, #55
    defb #00, #55
    defb #00, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_K:
    defb #AA, #55
    defb #AA, #AA
    defb #FF, #00
    defb #FF, #00
    defb #AA, #AA
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_L:
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #FF, #FF
    defb #00, #00
f_w_M:
    defb #AA, #55
    defb #FF, #FF
    defb #FF, #FF
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_N:
    defb #AA, #55
    defb #FF, #55
    defb #AA, #FF
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_O:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_P:
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #FF, #AA
    defb #AA, #00
    defb #AA, #00
    defb #AA, #00
    defb #00, #00
f_w_Q:
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #55
    defb #00, #00
f_w_R:
    defb #FF, #AA
    defb #AA, #55
    defb #AA, #55
    defb #FF, #AA
    defb #AA, #AA
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_S:
    defb #55, #FF
    defb #AA, #00
    defb #AA, #00
    defb #55, #AA
    defb #00, #55
    defb #00, #55
    defb #FF, #AA
    defb #00, #00
f_w_T:
    defb #FF, #FF
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #00, #00
f_w_U:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #00, #00
f_w_V:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #55, #AA
    defb #00, #00
f_w_W:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #FF, #FF
    defb #FF, #FF
    defb #AA, #55
    defb #00, #00
f_w_X:
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #AA, #55
    defb #AA, #55
    defb #00, #00
f_w_Y:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #00, #00
f_w_Z:
    defb #FF, #FF
    defb #00, #55
    defb #00, #AA
    defb #55, #AA
    defb #55, #00
    defb #AA, #00
    defb #FF, #FF
    defb #00, #00
f_w_SPACE:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_w_DOT:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #55, #AA
    defb #55, #AA
    defb #00, #00
f_w_DASH:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #FF, #FF
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_w_EXCL:
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #55, #AA
    defb #00, #00
    defb #55, #AA
    defb #55, #AA
    defb #00, #00

;; --- Red Font (Pen 2 - essential HUD headers) ---
f_r_1:
    defb #00, #08
    defb #04, #08
    defb #00, #08
    defb #00, #08
    defb #00, #08
    defb #00, #08
    defb #04, #0C
    defb #00, #00
f_r_2:
    defb #04, #08
    defb #08, #04
    defb #00, #04
    defb #00, #08
    defb #04, #00
    defb #08, #00
    defb #0C, #0C
    defb #00, #00
f_r_C:
    defb #04, #0C
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #04, #0C
    defb #00, #00
f_r_E:
    defb #0C, #0C
    defb #08, #00
    defb #08, #00
    defb #0C, #08
    defb #08, #00
    defb #08, #00
    defb #0C, #0C
    defb #00, #00
f_r_G:
    defb #04, #0C
    defb #08, #00
    defb #08, #00
    defb #08, #0C
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_H:
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #0C, #0C
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #00, #00
f_r_I:
    defb #0C, #0C
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #0C, #0C
    defb #00, #00
f_r_O:
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_P:
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #0C, #08
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #00, #00
f_r_R:
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #0C, #08
    defb #08, #08
    defb #08, #04
    defb #08, #04
    defb #00, #00
f_r_S:
    defb #04, #0C
    defb #08, #00
    defb #08, #00
    defb #04, #08
    defb #00, #04
    defb #00, #04
    defb #0C, #08
    defb #00, #00
f_r_U:
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_A:
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #0C, #0C
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #00, #00
f_r_T:
    defb #0C, #0C
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #00, #00
f_r_SPACE:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00

;; ----------------------------------------------------------------------------
;; DrawCharWhite: Draw character in A ('A'..'Z', '0'..'9', ' ', '.') in White
;; Input:  A = ASCII char, B = X, C = Y
;; Destroys: AF, HL, DE
;; ----------------------------------------------------------------------------
DrawCharWhite:
    cp 'A'
    jr c, .dcw_not_upper
    cp 'Z' + 1
    jr nc, .dcw_not_upper
    sub 'A'
    ld l, a
    ld h, 0
    add hl, hl          ; *2
    add hl, hl          ; *4
    add hl, hl          ; *8
    add hl, hl          ; *16
    ld de, font_alpha_white
    add hl, de
    jp DrawGlyph

.dcw_not_upper:
    cp '0'
    jr c, .dcw_not_digit
    cp '9' + 1
    jr nc, .dcw_not_digit
    sub '0'
    jp DrawWhiteDigit

.dcw_not_digit:
    cp '.'
    jr nz, .dcw_not_dot
    ld hl, f_w_DOT
    jp DrawGlyph
.dcw_not_dot:
    cp '-'
    jr nz, .dcw_not_dash
    ld hl, f_w_DASH
    jp DrawGlyph
.dcw_not_dash:
    cp '!'
    jr nz, .dcw_space
    ld hl, f_w_EXCL
    jp DrawGlyph
.dcw_space:
    ld hl, f_w_SPACE
    jp DrawGlyph

;; ----------------------------------------------------------------------------
;; DrawStringWhite: Draw null-terminated ASCII string at B=X, C=Y in White
;; Input:  HL = string ptr, B = X, C = Y
;; Destroys: AF, HL, DE, BC
;; ----------------------------------------------------------------------------
DrawStringWhite:
.dsw_loop:
    ld a, (hl)
    or a
    ret z
    inc hl
    push hl
    call DrawCharWhite
    pop hl
    ld a, b
    add a, 3            ; X advance (2 bytes + 1 space)
    ld b, a
    jr .dsw_loop

;; --- Cyan Font (Pen 4) ---
f_c_0:
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_2:
    defb #10, #20
    defb #20, #10
    defb #00, #10
    defb #00, #20
    defb #10, #00
    defb #20, #00
    defb #30, #30
    defb #00, #00
f_c_5:
    defb #30, #30
    defb #20, #00
    defb #30, #20
    defb #00, #10
    defb #00, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_6:
    defb #10, #20
    defb #20, #00
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_8:
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_A:
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #30, #30
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #00, #00
f_c_B:
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #30, #20
    defb #00, #00
f_c_C:
    defb #10, #30
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #10, #30
    defb #00, #00
f_c_D:
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #30, #20
    defb #00, #00
f_c_E:
    defb #30, #30
    defb #20, #00
    defb #20, #00
    defb #30, #20
    defb #20, #00
    defb #20, #00
    defb #30, #30
    defb #00, #00
f_c_F:
    defb #30, #30
    defb #20, #00
    defb #20, #00
    defb #30, #20
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #00, #00
f_c_G:
    defb #10, #30
    defb #20, #00
    defb #20, #00
    defb #20, #30
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_H:
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #30, #30
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #00, #00
f_c_I:
    defb #30, #30
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #30, #30
    defb #00, #00
f_c_L:
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #30, #30
    defb #00, #00
f_c_M:
    defb #20, #10
    defb #30, #30
    defb #30, #30
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #00, #00
f_c_N:
    defb #20, #10
    defb #30, #10
    defb #20, #30
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #00, #00
f_c_O:
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_P:
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #30, #20
    defb #20, #00
    defb #20, #00
    defb #20, #00
    defb #00, #00
f_c_U:
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #00, #00
f_c_R:
    defb #30, #20
    defb #20, #10
    defb #20, #10
    defb #30, #20
    defb #20, #20
    defb #20, #10
    defb #20, #10
    defb #00, #00
f_c_S:
    defb #10, #30
    defb #20, #00
    defb #20, #00
    defb #10, #20
    defb #00, #10
    defb #00, #10
    defb #30, #20
    defb #00, #00
f_c_T:
    defb #30, #30
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #00, #00
f_c_V:
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #10, #20
    defb #00, #00
f_c_Y:
    defb #20, #10
    defb #20, #10
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #10, #20
    defb #00, #00
f_c_SPACE:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_c_DOT:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #10, #20
    defb #10, #20
    defb #00, #00
f_c_DASH:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #30, #30
    defb #30, #30
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_w_PERCENT:
    defb #AA, #55               ; X..X
    defb #00, #55               ; ...X
    defb #00, #AA               ; ..X.
    defb #55, #00               ; .X..
    defb #AA, #00               ; X...
    defb #AA, #55               ; X..X
    defb #00, #00
    defb #00, #00

;; ----------------------------------------------------------------------------
;; DrawGlyphString - Draw null-terminated list of glyph pointers at (B=X, C=Y)
;; ----------------------------------------------------------------------------
DrawGlyphString:
.dgs_loop:
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld a, d
    or e
    ret z
    push hl
    push de
    pop hl              ; HL = glyph address
    call DrawGlyph
    pop hl
    ld a, b
    add a, 3            ; X advance
    ld b, a
    jr .dgs_loop

;; ----------------------------------------------------------------------------
;; DrawResultsScreen - Display authentic Galaga end-of-game statistics
;; ----------------------------------------------------------------------------
;; 1-player layout: labels are 14 characters (42 bytes), values to the right
RES1_LABEL_X    equ 2
RES1_VALUE_X    equ 52                  ; 5 digits = 15 bytes
RES1_HDR_Y      equ 90
RES1_SHOTS_Y    equ 116
RES1_HITS_Y     equ 136
RES1_RATIO_Y    equ 156
RES1_FOOTER_Y   equ 184

DrawResultsScreen:
    ;; Drawn once on a cleared playfield: enemies and bullets are frozen
    ;; and the stars stop while it shows.
    ld a, (results_drawn)
    or a
    ret nz
    inc a
    ld (results_drawn), a
    ld b, PF_X0 : ld c, PF_Y_TOP : ld d, PF_W - 1 : ld e, SPRITE_Y_LIMIT - PF_Y_TOP
    call ClearBitmapRect

    ld a, (two_player)
    or a
    jp nz, DrawTwoPlayerResults

    ld b, PF_X_CENTER - 16 : ld c, RES1_HDR_Y
    ld hl, str_results_header
    call DrawGlyphString

    ld b, RES1_LABEL_X : ld c, RES1_SHOTS_Y
    ld hl, str_shots_fired
    call DrawGlyphString
    ld hl, (shots_fired)
    ld b, RES1_VALUE_X : ld c, RES1_SHOTS_Y
    call Print5Digits

    ld b, RES1_LABEL_X : ld c, RES1_HITS_Y
    ld hl, str_number_of_hits
    call DrawGlyphString
    ld hl, (shots_hit)
    ld b, RES1_VALUE_X : ld c, RES1_HITS_Y
    call Print5Digits

    ld b, RES1_LABEL_X : ld c, RES1_RATIO_Y
    ld hl, str_hit_miss_ratio
    call DrawGlyphString
    call CalcHitMissRatio
    ld b, RES1_VALUE_X + 6 : ld c, RES1_RATIO_Y
    call Draw2DigitsWhite
    ld b, RES1_VALUE_X + 12 : ld c, RES1_RATIO_Y
    ld hl, f_w_PERCENT
    call DrawGlyph

    ld b, PF_X_CENTER - 22 : ld c, RES1_FOOTER_Y
    ld hl, str_revive8bit_copyright
    jp DrawGlyphString

;; ----------------------------------------------------------------------------
;; DrawTwoPlayerResults - Both players' statistics side by side and the winner.
;; Called from DrawResultsScreen after the playfield is cleared.
;; ----------------------------------------------------------------------------
RES2_COL1       equ 24                  ; 6-digit score columns (18 bytes)
RES2_COL2       equ 48
RES2_HDR_Y      equ 76
RES2_COLS_Y     equ 96
RES2_SCORE_Y    equ 112
RES2_SHOTS_Y    equ 126
RES2_HITS_Y     equ 140
RES2_RATIO_Y    equ 154
RES2_WINNER_Y   equ 178

DrawTwoPlayerResults:
    ld b, PF_X_CENTER - 16 : ld c, RES2_HDR_Y
    ld hl, str_results_header
    call DrawGlyphString
    ld b, RES2_COL1 + 5 : ld c, RES2_COLS_Y
    ld hl, str_1up_hdr
    call DrawGlyphString
    ld b, RES2_COL2 + 5 : ld c, RES2_COLS_Y
    ld hl, str_2up_hdr
    call DrawGlyphString

    ld hl, res2_labels
    ld c, RES2_SCORE_Y
.label:
    ld b, 2
    call DrawGlyphString        ; HL ends past the terminator
    ld a, c
    add a, RES2_SHOTS_Y - RES2_SCORE_Y
    ld c, a
    ld a, (hl)
    inc hl
    or (hl)
    dec hl
    jr nz, .label

    ;; Each player's column, then the winner by score
    call DrawResultsColumn
    call SwapPlayerState
    call DrawResultsColumn
    call SwapPlayerState

    ld a, (player_score_hi)
    ld hl, player_score_hi + OTHER_PLAYER
    cp (hl)
    jr nz, .decided
    ld hl, (player_score)
    ld de, (player_score + OTHER_PLAYER)
    or a
    sbc hl, de
    jr z, .draw
.decided:
    ld a, (active_player)       ; Carry: the inactive player scored more
    jr nc, .winner
    xor 1
.winner:
    add a, '1'
    ld (str_player_wins + 7), a
    ld hl, str_player_wins
    ld b, PF_X_CENTER - 19
    jr .winner_text
.draw:
    ld hl, str_draw
    ld b, PF_X_CENTER - 6
.winner_text:
    ld c, RES2_WINNER_Y
    jp DrawStringWhite

;; DrawResultsColumn - Active player's score, shots, hits and ratio
DrawResultsColumn:
    ld a, (active_player)
    or a
    ld a, RES2_COL1
    jr z, .col
    ld a, RES2_COL2
.col:
    ld (results_col), a

    ld hl, (player_score)
    ld a, (player_score_hi)
    ld bc, (results_col - 1)    ; B = column
    ld c, RES2_SCORE_Y
    call Print6Digits

    ld hl, (shots_fired)
    ld bc, (results_col - 1)
    inc b : inc b : inc b
    ld c, RES2_SHOTS_Y
    call Print5Digits

    ld hl, (shots_hit)
    ld bc, (results_col - 1)
    inc b : inc b : inc b
    ld c, RES2_HITS_Y
    call Print5Digits

    call CalcHitMissRatio
    ld bc, (results_col - 1)
    ld c, a
    ld a, b
    add a, 9
    ld b, a
    ld a, c
    ld c, RES2_RATIO_Y
    call Draw2DigitsWhite
    ld bc, (results_col - 1)
    ld a, b
    add a, 15
    ld b, a
    ld c, RES2_RATIO_Y
    ld hl, f_w_PERCENT
    jp DrawGlyph

results_col:        defb 0

res2_labels:
    defw f_c_S, f_c_C, f_c_O, f_c_R, f_c_E, 0
    defw f_c_S, f_c_H, f_c_O, f_c_T, f_c_S, 0
    defw f_c_H, f_c_I, f_c_T, f_c_S, 0
    defw f_c_R, f_c_A, f_c_T, f_c_I, f_c_O, 0
    defw 0

str_player_wins:
    defb "PLAYER 1 WINS", 0
str_draw:
    defb "DRAW", 0

CalcHitMissRatio:
    ld hl, (shots_fired)
    ld a, h
    or l
    ret z                   ; if shots_fired == 0 -> return A=0

    ld bc, (shots_hit)
    ld a, c
    or b
    ret z                   ; if shots_hit == 0 -> return A=0

    ;; HL = shots_hit * 100
    ld hl, 0
    ld d, b
    ld e, c
    ld b, 100
.chmr_mloop:
    add hl, de
    djnz .chmr_mloop

    ;; Divide HL by DE (shots_fired) to get percentage (0..100)
    ld de, (shots_fired)
    ld c, 0
.chmr_dloop:
    or a
    sbc hl, de
    jr c, .chmr_done
    inc c
    ld a, c
    cp 100
    jr c, .chmr_dloop
    ld c, 100
.chmr_done:
    ld a, c
    ret

;; String Tables for Galaga Authentic Screens
str_results_header:
    defw f_c_DASH, f_c_SPACE, f_c_R, f_c_E, f_c_S, f_c_U, f_c_L, f_c_T, f_c_S, f_c_SPACE, f_c_DASH, 0

str_shots_fired:
    defw f_c_S, f_c_H, f_c_O, f_c_T, f_c_S, f_c_SPACE, f_c_F, f_c_I, f_c_R, f_c_E, f_c_D, 0

str_number_of_hits:
    defw f_c_N, f_c_U, f_c_M, f_c_B, f_c_E, f_c_R, f_c_SPACE, f_c_O, f_c_F, f_c_SPACE, f_c_H, f_c_I, f_c_T, f_c_S, 0

str_hit_miss_ratio:
    defw f_c_H, f_c_I, f_c_T, f_c_DASH, f_c_M, f_c_I, f_c_S, f_c_S, f_c_SPACE, f_c_R, f_c_A, f_c_T, f_c_I, f_c_O, 0

str_special_10000:
    defw f_c_S, f_c_P, f_c_E, f_c_C, f_c_I, f_c_A, f_c_L, f_c_SPACE, f_w_1, f_w_0, f_w_0, f_w_0, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, 0

str_bonus_label:
    defw f_c_B, f_c_O, f_c_N, f_c_U, f_c_S, f_c_SPACE, 0

str_pts_label:
    defw f_c_SPACE, f_c_P, f_c_T, f_c_S, 0

str_revive8bit_copyright:
    defw f_c_2, f_c_0, f_c_2, f_c_6, f_c_SPACE
    defw f_c_R, f_c_E, f_c_V, f_c_I, f_c_V, f_c_E, f_c_8, f_c_B, f_c_I, f_c_T, 0

;; Title Screen Strings
str_title_prompt:
    defw f_c_P, f_c_R, f_c_E, f_c_S, f_c_S, f_c_SPACE, f_w_1, f_c_SPACE, f_c_O, f_c_R, f_c_SPACE, f_w_2
    defw f_c_SPACE, f_c_P, f_c_L, f_c_A, f_c_Y, f_c_E, f_c_R, f_c_S, 0

str_title_difficulty_easy:
    defw f_c_D, f_c_I, f_c_F, f_c_F, f_c_I, f_c_C, f_c_U, f_c_L, f_c_T, f_c_Y, f_c_SPACE
    defw f_c_E, f_c_A, f_c_S, f_c_Y, 0

str_title_difficulty_medium:
    defw f_c_D, f_c_I, f_c_F, f_c_F, f_c_I, f_c_C, f_c_U, f_c_L, f_c_T, f_c_Y, f_c_SPACE
    defw f_c_M, f_c_E, f_c_D, f_c_I, f_c_U, f_c_M, 0

str_title_difficulty_hard:
    defw f_c_D, f_c_I, f_c_F, f_c_F, f_c_I, f_c_C, f_c_U, f_c_L, f_c_T, f_c_Y, f_c_SPACE
    defw f_c_H, f_c_A, f_c_R, f_c_D, 0

str_title_difficulty_hardest:
    defw f_c_D, f_c_I, f_c_F, f_c_F, f_c_I, f_c_C, f_c_U, f_c_L, f_c_T, f_c_Y, f_c_SPACE
    defw f_c_H, f_c_A, f_c_R, f_c_D, f_c_E, f_c_S, f_c_T, 0

str_title_points_hdr:
    defw f_c_DASH, f_c_SPACE, f_c_P, f_c_O, f_c_I, f_c_N, f_c_T, f_c_SPACE, f_c_V, f_c_A, f_c_L, f_c_U, f_c_E, f_c_S, f_c_SPACE, f_c_DASH, 0

str_pts_50_100:
    defw f_w_5, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, f_c_SPACE, f_c_SPACE, f_c_SPACE, f_w_1, f_w_0, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, 0

str_pts_80_160:
    defw f_w_8, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, f_c_SPACE, f_c_SPACE, f_c_SPACE, f_w_1, f_w_6, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, 0

str_pts_150_400:
    defw f_w_1, f_w_5, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, f_c_SPACE, f_c_SPACE, f_w_4, f_w_0, f_w_0, f_c_SPACE, f_c_P, f_c_T, f_c_S, 0

str_revive8bit_footer:
    defw f_c_R, f_c_E, f_c_V, f_c_I, f_c_V, f_c_E, f_c_8, f_c_B, f_c_I, f_c_T
    defw f_c_SPACE, f_c_DASH, f_c_SPACE
    defw f_c_2, f_c_0, f_c_2, f_c_6
    defw f_c_SPACE, f_c_DASH, f_c_SPACE
    defw f_c_V, f_c_A, f_c_S, f_c_P, f_c_E, f_c_R
    defw 0
