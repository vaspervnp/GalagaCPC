;; ============================================================================
;; Galaga CPC - Title Screen & Attract Mode
;; Features: Official Galaga Logo, Point Values Table, Revive9bit Footer
;; ============================================================================

    include "title_logo.asm"

ShowTitleScreen:
    ;; 1. Set title screen flag and reset timers/controls
    ld a, 1
    ld (is_title_screen), a
    xor a
    ld (title_timer), a
    ld (ctl_now), a
    ld (ctl_last), a
    ld (ctl_pressed), a
    ;; Restart the menu melody from its first note
    ld (drone_step), a
    ld (drone_timer), a

    ;; 2. Clear entire 32KB overscan screen to Black
    call ClearScreenOverscan

    ;; 3. Draw Top HUD headers (1UP in Red, HIGH SCORE in Red, and High Score value)
    call InitHUD

    ;; 4. Draw Official Arcade Galaga Logo at X=30, Y=36 (36 bytes x 32 lines)
    ld b, 30
    ld c, 36
    ld d, TITLE_LOGO_W         ; 36 bytes wide
    ld e, TITLE_LOGO_H         ; 32 scanlines high
    ld hl, title_logo_data
    call DrawBitmapRect

    xor a
    ld (title_display_mode), a
    ld (title_mode_timer), a

    ;; 5. Draw initial mode: Point Values Demonstration
    call DrawTitlePointValues

    ;; 6. Draw Bottom Signature in Lower Border:
    ;; "REVIVE8BIT - 2026 - VASPER" at X=9, Y=244
    ld b, 9
    ld c, 244
    ld hl, str_revive8bit_footer
    call DrawGlyphString

    call DrawTitleDifficulty

TitleLoop:
    call WaitVSync

    ;; Starfield moves in the background (protected on sides)
    call UpdateStars

    ;; Sound driver tick
    call SoundUpdate

    ;; Blink "PUSH FIRE BUTTON" at X=24, Y=82
    ld a, (title_timer)
    inc a
    ld (title_timer), a
    and 32                      ; Toggle visibility every 32 frames (~0.64s)
    jr z, .hide_prompt

    ld b, 24
    ld c, 82
    ld hl, str_title_prompt
    call DrawGlyphString
    jr .check_cycle_mode

.hide_prompt:
    ld b, 24
    ld c, 82
    ld d, 48                    ; 16 chars * 3 bytes
    call ClearTextRect

.check_cycle_mode:
    ;; Cycle between Point Values and Hall of Fame every 250 frames (~5 seconds)
    ld a, (title_mode_timer)
    inc a
    ld (title_mode_timer), a
    cp 250
    jr c, .no_cycle_mode

    xor a
    ld (title_mode_timer), a
    ld a, (title_display_mode)
    xor 1
    ld (title_display_mode), a
    call ClearTitleMiddle

    ld a, (title_display_mode)
    or a
    jr nz, .cycle_to_hof
    call DrawTitlePointValues
    jr .no_cycle_mode

.cycle_to_hof:
    call DrawTitleHallOfFame

.no_cycle_mode:
    call read_controls
    ld a, (ctl_pressed)
    bit CTL_LEFT, a
    jp nz, .difficulty_left
    bit CTL_RIGHT, a
    jp nz, .difficulty_right
    jr .check_start

.difficulty_left:
    ld a, (difficulty_level)
    or a
    jr nz, .difficulty_decrement
    ld a, 4
.difficulty_decrement:
    dec a
    ld (difficulty_level), a
    call DrawTitleDifficulty
    jr .check_start

.difficulty_right:
    ld a, (difficulty_level)
    inc a
    cp 4
    jr c, .store_difficulty
    xor a
.store_difficulty:
    ld (difficulty_level), a
    call DrawTitleDifficulty

.check_start:
    ld a, (ctl_pressed)
    bit CTL_FIRE, a
    jp z, TitleLoop

    ;; *** FIRE PRESSED! START GAME! ***
    xor a
    ld (is_title_screen), a
    call RestartGame            ; Fresh game initialization (plays game start tune)
    jp GameLoop

;; ----------------------------------------------------------------------------
;; DrawTitleDifficulty: Show the current menu selection
;; ----------------------------------------------------------------------------
DrawTitleDifficulty:
    ld b, 21
    ld c, 94
    ld d, 54
    call ClearTextRect

    ld a, (difficulty_level)
    or a
    jr z, .easy
    cp 1
    jr z, .medium
    cp 2
    jr z, .hard
    ld hl, str_title_difficulty_hardest
    jr .draw
.hard:
    ld hl, str_title_difficulty_hard
    jr .draw
.medium:
    ld hl, str_title_difficulty_medium
    jr .draw
.easy:
    ld hl, str_title_difficulty_easy
.draw:
    ld b, 21
    ld c, 94
    jp DrawGlyphString

;; ----------------------------------------------------------------------------
;; DrawTitlePointValues: Render enemy point values demonstration
;; ----------------------------------------------------------------------------
DrawTitlePointValues:
    ;; 1. Draw "- POINT VALUES -" at X=24, Y=106 in Bright Cyan
    ld b, 24
    ld c, 106
    ld hl, str_title_points_hdr
    call DrawGlyphString

    ;; 2. Row 1: Zako Bee at X=22, Y=126
    ld b, 22
    ld c, 126
    ld hl, zako_bee_1
    call DrawSprite16x16
    ld b, 34
    ld c, 130
    ld hl, str_pts_50_100
    call DrawGlyphString

    ;; 3. Row 2: Goei Butterfly at X=22, Y=148
    ld b, 22
    ld c, 148
    ld hl, goei_butterfly_1
    call DrawSprite16x16
    ld b, 34
    ld c, 152
    ld hl, str_pts_80_160
    call DrawGlyphString

    ;; 4. Row 3: Boss Galaga at X=22, Y=170
    ld b, 22
    ld c, 170
    ld hl, boss_galaga_1
    call DrawSprite16x16
    ld b, 34
    ld c, 174
    ld hl, str_pts_150_400
    call DrawGlyphString
    ret
