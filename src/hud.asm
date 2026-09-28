;; ============================================================================
;; Galaga CPC - HUD, Upper Border Scoring, Lower Border Lives & Badges
;; Amstrad CPC 464 / 6128 Overscan Mode
;; ============================================================================

;; ----------------------------------------------------------------------------
;; InitHUD - Draw Upper Border HUD headers and initial scores
;; ----------------------------------------------------------------------------
InitHUD:
    ;; 1. Draw '1UP' in Red at X=16, Y=6
    ld b, 16
    ld c, 6
    ld hl, f_r_1
    call DrawGlyph
    ld b, 19
    ld c, 6
    ld hl, f_r_U
    call DrawGlyph
    ld b, 22
    ld c, 6
    ld hl, f_r_P
    call DrawGlyph

    ;; 2. Draw 'HIGH SCORE' in Red at X=46, Y=6
    ld b, 46
    ld c, 6
    ld hl, f_r_H : call DrawGlyph : ld b, 49 : ld c, 6
    ld hl, f_r_I : call DrawGlyph : ld b, 52 : ld c, 6
    ld hl, f_r_G : call DrawGlyph : ld b, 55 : ld c, 6
    ld hl, f_r_H : call DrawGlyph : ld b, 58 : ld c, 6
    ld hl, f_r_SPACE : call DrawGlyph : ld b, 61 : ld c, 6
    ld hl, f_r_S : call DrawGlyph : ld b, 64 : ld c, 6
    ld hl, f_r_C : call DrawGlyph : ld b, 67 : ld c, 6
    ld hl, f_r_O : call DrawGlyph : ld b, 70 : ld c, 6
    ld hl, f_r_R : call DrawGlyph : ld b, 73 : ld c, 6
    ld hl, f_r_E : call DrawGlyph

    ;; 3. Initial Scores in White at Y=16
    call PrintScore
    call PrintHighScore
    ret

;; ----------------------------------------------------------------------------
;; PrintScore - Print player_score at X=16, Y=16 in White
;; ----------------------------------------------------------------------------
PrintScore:
    ld hl, (player_score)
    ld b, 16
    ld c, 16
    jp Print5Digits

;; ----------------------------------------------------------------------------
;; PrintHighScore - Print high_score at X=52, Y=16 in White
;; ----------------------------------------------------------------------------
PrintHighScore:
    ld hl, (high_score)
    ld b, 52
    ld c, 16
    jp Print5Digits

;; ----------------------------------------------------------------------------
;; Print5Digits - Format 16-bit HL into 5 decimal digits at (B=X, C=Y)
;; ----------------------------------------------------------------------------
Print5Digits:
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
;; DrawGameOverText - Display "GAME OVER" in Cyan at X=35, Y=110
;; ----------------------------------------------------------------------------
DrawGameOverText:
    ld b, 35 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 38 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 41 : ld c, 110 : ld hl, f_c_M : call DrawGlyph
    ld b, 44 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 47 : ld c, 110 : ld hl, f_c_SPACE : call DrawGlyph
    ld b, 50 : ld c, 110 : ld hl, f_c_O : call DrawGlyph
    ld b, 53 : ld c, 110 : ld hl, f_c_V : call DrawGlyph
    ld b, 56 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 59 : ld c, 110 : ld hl, f_c_R : call DrawGlyph
    ret

ClearGameOverText:
    ld b, 35
    ld c, 110
    ld d, 27
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; DrawStageBanner - Display "STAGE " + current_stage in Cyan at X=38, Y=110
;; ----------------------------------------------------------------------------
DrawStageBanner:
    ld b, 38 : ld c, 110 : ld hl, f_c_S : call DrawGlyph
    ld b, 41 : ld c, 110 : ld hl, f_c_T : call DrawGlyph
    ld b, 44 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 47 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 50 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 53 : ld c, 110 : ld hl, f_c_SPACE : call DrawGlyph
    ld a, (current_stage)
    cp 10
    jr nc, .dsb_2digits
    ld b, 56 : ld c, 110
    jp DrawWhiteDigit
.dsb_2digits:
    ld b, 56 : ld c, 110
    jp Draw2DigitsWhite

ClearStageBanner:
    ld b, 38
    ld c, 110
    ld d, 24
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; DrawPlayerBanner - Display "PLAYER 1" in Cyan at X=36, Y=110
;; ----------------------------------------------------------------------------
DrawPlayerBanner:
    ld b, 36 : ld c, 110 : ld hl, f_c_P : call DrawGlyph
    ld b, 39 : ld c, 110 : ld hl, f_c_L : call DrawGlyph
    ld b, 42 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 45 : ld c, 110 : ld hl, f_c_Y : call DrawGlyph
    ld b, 48 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 51 : ld c, 110 : ld hl, f_c_R : call DrawGlyph
    ld b, 54 : ld c, 110 : ld hl, f_c_SPACE : call DrawGlyph
    ld b, 57 : ld c, 110
    ld a, 1
    jp DrawWhiteDigit

ClearPlayerBanner:
    ld b, 36
    ld c, 110
    ld d, 24
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; DrawChallengingBanner - Display "CHALLENGING STAGE" in Cyan at X=23, Y=110
;; ----------------------------------------------------------------------------
DrawChallengingBanner:
    ld b, 23 : ld c, 110 : ld hl, f_c_C : call DrawGlyph
    ld b, 26 : ld c, 110 : ld hl, f_c_H : call DrawGlyph
    ld b, 29 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 32 : ld c, 110 : ld hl, f_c_L : call DrawGlyph
    ld b, 35 : ld c, 110 : ld hl, f_c_L : call DrawGlyph
    ld b, 38 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 41 : ld c, 110 : ld hl, f_c_N : call DrawGlyph
    ld b, 44 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 47 : ld c, 110 : ld hl, f_c_I : call DrawGlyph
    ld b, 50 : ld c, 110 : ld hl, f_c_N : call DrawGlyph
    ld b, 53 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 56 : ld c, 110 : ld hl, f_c_SPACE : call DrawGlyph
    ld b, 59 : ld c, 110 : ld hl, f_c_S : call DrawGlyph
    ld b, 62 : ld c, 110 : ld hl, f_c_T : call DrawGlyph
    ld b, 65 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 68 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 71 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ret

ClearChallengingBanner:
    ld b, 23
    ld c, 110
    ld d, 51
    jp ClearTextRect

;; ----------------------------------------------------------------------------
;; DrawFighterCapturedBanner - Display "FIGHTER CAPTURED" in Cyan at X=24, Y=110
;; ----------------------------------------------------------------------------
DrawFighterCapturedBanner:
    ld b, 24 : ld c, 110 : ld hl, f_c_F : call DrawGlyph
    ld b, 27 : ld c, 110 : ld hl, f_c_I : call DrawGlyph
    ld b, 30 : ld c, 110 : ld hl, f_c_G : call DrawGlyph
    ld b, 33 : ld c, 110 : ld hl, f_c_H : call DrawGlyph
    ld b, 36 : ld c, 110 : ld hl, f_c_T : call DrawGlyph
    ld b, 39 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 42 : ld c, 110 : ld hl, f_c_R : call DrawGlyph
    ld b, 45 : ld c, 110 : ld hl, f_c_SPACE : call DrawGlyph
    ld b, 48 : ld c, 110 : ld hl, f_c_C : call DrawGlyph
    ld b, 51 : ld c, 110 : ld hl, f_c_A : call DrawGlyph
    ld b, 54 : ld c, 110 : ld hl, f_c_P : call DrawGlyph
    ld b, 57 : ld c, 110 : ld hl, f_c_T : call DrawGlyph
    ld b, 60 : ld c, 110 : ld hl, f_c_U : call DrawGlyph
    ld b, 63 : ld c, 110 : ld hl, f_c_R : call DrawGlyph
    ld b, 66 : ld c, 110 : ld hl, f_c_E : call DrawGlyph
    ld b, 69 : ld c, 110 : ld hl, f_c_D : call DrawGlyph
    ret

ClearFighterCapturedBanner:
    ld b, 24
    ld c, 110
    ld d, 48
    jp ClearTextRect

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
    ;; 2. Check Game Over banner (Phase 0)
    ld a, (game_over)
    or a
    jr z, .rpt_check_stage_clear
    ld a, (game_over_phase)
    or a
    jr nz, .rpt_check_stage_clear
    call DrawGameOverText
    ret

.rpt_check_stage_clear:
    ;; 3. Check Stage Clear / Stage Banner ("STAGE X" or "CHALLENGING STAGE")
    ld a, (stage_clear_active)
    or a
    jr z, .rpt_check_capture
    ld a, (stage_clear_timer)
    cp 51
    jr nc, .rpt_check_capture   ; Not yet showing banner (timer > 50)
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

digit_buf:  defs 5, 0

;; ----------------------------------------------------------------------------
;; DrawWhiteDigit - Draw single digit A (0..9) at (B=X, C=Y) in White
;; ----------------------------------------------------------------------------
DrawWhiteDigit:
    push bc
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
;; Input:  B = X (0..93), C = Y (0..263), HL = glyph pointer (16 bytes)
;; Preserves: BC, IX, IY
;; ----------------------------------------------------------------------------
DrawGlyph:
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
;; DrawLivesHUD - Draw reserve fighter ships in Lower Border (Y=244)
;; ----------------------------------------------------------------------------
DrawLivesHUD:
    ;; Erase lives area in Lower Border (X=10..42, Y=244, 32 bytes wide, 16 lines)
    ld b, 10 : ld c, LIVES_Y : call ClearSprite16x16
    ld b, 18 : ld c, LIVES_Y : call ClearSprite16x16
    ld b, 26 : ld c, LIVES_Y : call ClearSprite16x16
    ld b, 34 : ld c, LIVES_Y : call ClearSprite16x16

    ld a, (player_lives)
    cp 2
    ret c               ; 1 or 0 lives: no reserve ships shown

    ;; Reserve Ship 1
    ld b, 10
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 3
    ret c

    ;; Reserve Ship 2
    ld b, 18
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 4
    ret c

    ;; Reserve Ship 3
    ld b, 26
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_lives)
    cp 5
    ret c

    ;; Reserve Ship 4
    ld b, 34
    ld c, LIVES_Y
    ld hl, player_sprite
    call DrawSprite16x16
    ret

;; ----------------------------------------------------------------------------
;; DrawStageHUD - Draw stage badges / flags in Lower Border (Y=244)
;; ----------------------------------------------------------------------------
DrawStageHUD:
    ;; Erase badges area (X=54..86, Y=244, 32 bytes wide, 16 lines)
    ld b, 54 : ld c, BADGES_Y : call ClearSprite16x16
    ld b, 62 : ld c, BADGES_Y : call ClearSprite16x16
    ld b, 70 : ld c, BADGES_Y : call ClearSprite16x16
    ld b, 78 : ld c, BADGES_Y : call ClearSprite16x16

    ;; Calculate number of 10s, 5s, 1s from current_stage
    ld a, (current_stage)
    ld c, 0             ; 10s count
.cnt_10:
    cp 10
    jr c, .done_10
    sub 10
    inc c
    jr .cnt_10
.done_10:
    ld b, 0             ; 5s count
    cp 5
    jr c, .done_5
    sub 5
    inc b
.done_5:
    ld (stage_ones), a
    ld a, b
    ld (stage_fives), a
    ld a, c
    ld (stage_tens), a

    ;; Start drawing flags from right to left: initial X = 80
    ld a, 80
    ld (badge_draw_x), a

    ;; Draw 10-Stage Flags
    ld a, (stage_tens)
    or a
    jr z, .chk_fives
.loop_tens:
    ld a, (badge_draw_x)
    cp 54
    jr c, .chk_fives
    push de
    ld b, a
    ld c, BADGES_Y
    ld hl, flag_10
    call DrawSprite16x16
    ld a, (badge_draw_x)
    sub 9               ; flag_10 is 8 bytes + 1 space
    ld (badge_draw_x), a
    pop de
    dec d
    jr nz, .loop_tens

.chk_fives:
    ;; Draw 5-Stage Flags
    ld a, (stage_fives)
    or a
    jr z, .chk_ones
    ld d, a
.loop_fives:
    ld a, (badge_draw_x)
    cp 54
    jr c, .chk_ones
    push de
    ld b, a
    ld c, BADGES_Y + 1
    ld hl, flag_5
    call DrawBadge5
    ld a, (badge_draw_x)
    sub 8               ; flag_5 is 7 bytes + 1 space
    ld (badge_draw_x), a
    pop de
    dec d
    jr nz, .loop_fives

.chk_ones:
    ;; Draw 1-Stage Flags
    ld a, (stage_ones)
    or a
    ret z
    ld d, a
.loop_ones:
    ld a, (badge_draw_x)
    cp 54
    ret c
    push de
    ld b, a
    ld c, BADGES_Y + 1
    ld hl, flag_1
    call DrawBadge1
    ld a, (badge_draw_x)
    sub 5               ; flag_1 is 4 bytes + 1 space
    ld (badge_draw_x), a
    pop de
    dec d
    jr nz, .loop_ones
    ret

stage_tens:     defb 0
stage_fives:    defb 0
stage_ones:     defb 0
badge_draw_x:   defb 0

;; ----------------------------------------------------------------------------
;; DrawBadge5 - Draw 7x14 flag_5 at B=X, C=Y
;; ----------------------------------------------------------------------------
DrawBadge5:
    push ix
    push bc
    push hl
    ld e, c
    ld d, 0
    sla e
    rl d                ; DE = Y * 2 (16-bit safe for Y up to 271)
    ld ix, line_tab
    add ix, de
    pop hl
    ld c, 14            ; 14 lines
.b5_row:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .b5_nc
    inc d
.b5_nc:
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl
    dec c
    jr nz, .b5_row
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; DrawBadge1 - Draw 4x14 flag_1 at B=X, C=Y
;; ----------------------------------------------------------------------------
DrawBadge1:
    push ix
    push bc
    push hl
    ld e, c
    ld d, 0
    sla e
    rl d                ; DE = Y * 2 (16-bit safe for Y up to 271)
    ld ix, line_tab
    add ix, de
    pop hl
    ld c, 14            ; 14 lines
.b1_row:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .b1_nc
    inc d
.b1_nc:
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl
    dec c
    jr nz, .b1_row
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; Authentic Galaga Stage Flags
;; ----------------------------------------------------------------------------
;; Badge Flag: flag_10 (16x16)
flag_10:
    defb #F0, #F0, #F0, #F0, #F0, #F0, #F0, #A0
    defb #F0, #F0, #F0, #E4, #F0, #F0, #F0, #A0
    defb #F0, #F0, #F0, #CC, #D8, #F0, #F0, #A0
    defb #F0, #E4, #D8, #E4, #F0, #CC, #F0, #A0
    defb #F0, #CC, #CC, #E4, #E4, #CC, #D8, #A0
    defb #E4, #D8, #E4, #CC, #CC, #F0, #CC, #A0
    defb #E4, #F0, #F0, #CC, #D8, #F0, #E4, #A0
    defb #E4, #D8, #F0, #E4, #F0, #F0, #CC, #A0
    defb #F0, #CC, #F0, #E4, #F0, #E4, #D8, #A0
    defb #50, #E4, #D8, #F0, #F0, #CC, #F0, #00
    defb #00, #F0, #CC, #CC, #CC, #D8, #A0, #00
    defb #00, #50, #E4, #F0, #E4, #F0, #00, #00
    defb #00, #00, #E4, #CC, #CC, #A0, #00, #00
    defb #00, #00, #50, #F0, #F0, #00, #00, #00
    defb #00, #00, #00, #F0, #A0, #00, #00, #00
    defb #00, #00, #00, #50, #00, #00, #00, #00

;; Badge Flag: flag_5 (14x14)
flag_5:
    defb #C0, #C0, #C0, #C0, #C0, #C0, #80
    defb #C0, #C0, #C0, #C8, #C0, #C0, #80
    defb #C0, #C0, #C4, #CC, #C0, #C0, #80
    defb #C4, #CC, #C0, #C8, #C4, #CC, #80
    defb #C0, #C4, #C8, #C8, #CC, #C0, #80
    defb #C0, #CC, #CC, #CC, #CC, #C8, #80
    defb #C0, #C0, #CC, #CC, #C8, #C0, #80
    defb #C0, #C4, #C8, #C8, #CC, #C0, #80
    defb #40, #C0, #C8, #C8, #C8, #C0, #00
    defb #00, #C0, #C8, #C8, #C8, #80, #00
    defb #00, #40, #C0, #C8, #C0, #00, #00
    defb #00, #00, #C0, #C0, #80, #00, #00
    defb #00, #00, #40, #C0, #00, #00, #00
    defb #00, #00, #00, #80, #00, #00, #00

;; Badge Flag: flag_1 (8x14)
flag_1:
    defb #FF, #FF, #FF, #AA
    defb #0C, #0C, #0C, #08
    defb #5D, #FF, #FF, #08
    defb #5D, #AE, #0C, #08
    defb #5D, #FF, #FF, #08
    defb #0C, #0C, #FF, #08
    defb #5D, #FF, #FF, #08
    defb #0C, #0C, #0C, #08
    defb #FF, #FF, #FF, #AA
    defb #FF, #FF, #FF, #AA
    defb #EA, #FF, #EA, #AA
    defb #55, #D5, #D5, #00
    defb #00, #EA, #AA, #00
    defb #00, #55, #00, #00


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
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_w_K:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
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
f_w_U:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
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
f_w_V:
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #AA, #55
    defb #55, #AA
    defb #55, #AA
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

;; --- Red Font (Pen 2) ---
f_r_0:
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
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
f_r_3:
    defb #0C, #08
    defb #00, #04
    defb #00, #04
    defb #04, #08
    defb #00, #04
    defb #00, #04
    defb #0C, #08
    defb #00, #00
f_r_4:
    defb #00, #08
    defb #04, #08
    defb #08, #08
    defb #0C, #0C
    defb #00, #08
    defb #00, #08
    defb #00, #08
    defb #00, #00
f_r_5:
    defb #0C, #0C
    defb #08, #00
    defb #0C, #08
    defb #00, #04
    defb #00, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_6:
    defb #04, #08
    defb #08, #00
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_7:
    defb #0C, #0C
    defb #00, #04
    defb #00, #08
    defb #00, #08
    defb #04, #00
    defb #04, #00
    defb #04, #00
    defb #00, #00
f_r_8:
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #04, #08
    defb #00, #00
f_r_9:
    defb #04, #08
    defb #08, #04
    defb #08, #04
    defb #04, #0C
    defb #00, #04
    defb #00, #04
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
f_r_B:
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #0C, #08
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
f_r_D:
    defb #0C, #08
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #0C, #08
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
f_r_F:
    defb #0C, #0C
    defb #08, #00
    defb #08, #00
    defb #0C, #08
    defb #08, #00
    defb #08, #00
    defb #08, #00
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
f_r_J:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_r_K:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_r_L:
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #08, #00
    defb #0C, #0C
    defb #00, #00
f_r_M:
    defb #08, #04
    defb #0C, #0C
    defb #0C, #0C
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #00, #00
f_r_N:
    defb #08, #04
    defb #0C, #04
    defb #08, #0C
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
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
f_r_U:
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #04, #08
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
f_r_T:
    defb #0C, #0C
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #04, #08
    defb #00, #00
f_r_V:
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
    defb #08, #04
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
f_r_DOT:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #04, #08
    defb #04, #08
    defb #00, #00

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
f_c_1:
    defb #00, #20
    defb #10, #20
    defb #00, #20
    defb #00, #20
    defb #00, #20
    defb #00, #20
    defb #10, #30
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
f_c_3:
    defb #30, #20
    defb #00, #10
    defb #00, #10
    defb #10, #20
    defb #00, #10
    defb #00, #10
    defb #30, #20
    defb #00, #00
f_c_4:
    defb #00, #20
    defb #10, #20
    defb #20, #20
    defb #30, #30
    defb #00, #20
    defb #00, #20
    defb #00, #20
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
f_c_7:
    defb #30, #30
    defb #00, #10
    defb #00, #20
    defb #00, #20
    defb #10, #00
    defb #10, #00
    defb #10, #00
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
f_c_9:
    defb #10, #20
    defb #20, #10
    defb #20, #10
    defb #10, #30
    defb #00, #10
    defb #00, #10
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
f_c_J:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
f_c_K:
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
    defb #00, #00
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
    defb #AA, #00
    defb #55, #55
    defb #00, #AA
    defb #55, #00
    defb #AA, #55
    defb #00, #AA
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
DrawResultsScreen:
    ;; 1. Header "- RESULTS -" at X=30, Y=70
    ld b, 30 : ld c, 70
    ld hl, str_results_header
    call DrawGlyphString

    ;; 2. "SHOTS FIRED" at X=16, Y=94
    ld b, 16 : ld c, 94
    ld hl, str_shots_fired
    call DrawGlyphString

    ;; Number of shots fired in White at X=55, Y=94
    ld hl, (shots_fired)
    ld b, 55 : ld c, 94
    call Print5Digits

    ;; 3. "NUMBER OF HITS" at X=16, Y=114
    ld b, 16 : ld c, 114
    ld hl, str_number_of_hits
    call DrawGlyphString

    ;; Number of hits in White at X=55, Y=114
    ld hl, (shots_hit)
    ld b, 55 : ld c, 114
    call Print5Digits

    ;; 4. "HIT-MISS RATIO" at X=16, Y=134
    ld b, 16 : ld c, 134
    ld hl, str_hit_miss_ratio
    call DrawGlyphString

    ;; Ratio percentage in White at X=58, Y=134
    call CalcHitMissRatio
    ld b, 58 : ld c, 134
    call Draw2DigitsWhite
    ld b, 64 : ld c, 134
    ld hl, f_w_PERCENT
    call DrawGlyph

    ;; 5. "2026 REVIVE8BIT" at X=25, Y=160
    ld b, 25 : ld c, 160
    ld hl, str_revive8bit_copyright
    call DrawGlyphString
    ret

ClearResultsScreen:
    ld b, 14 : ld c, 70 : ld d, 66 : call ClearTextRect
    ld b, 14 : ld c, 94 : ld d, 66 : call ClearTextRect
    ld b, 14 : ld c, 114 : ld d, 66 : call ClearTextRect
    ld b, 14 : ld c, 134 : ld d, 66 : call ClearTextRect
    ld b, 14 : ld c, 160 : ld d, 66 : call ClearTextRect
    ret

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
    defw f_c_P, f_c_U, f_c_S, f_c_H, f_c_SPACE, f_c_F, f_c_I, f_c_R, f_c_E, f_c_SPACE, f_c_B, f_c_U, f_c_T, f_c_T, f_c_O, f_c_N, 0

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

