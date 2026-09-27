;; ============================================================================
;; Galaga CPC - HUD & Score Display
;; ============================================================================

InitHUD:
    ;; "1UP" in Red (Pen 2) at column 2, row 1
    ld h, 2
    ld l, 1
    call #BB75              ; TXT SET CURSOR
    ld a, 2
    call #BB90              ; TXT SET PEN
    ld hl, txt_1up
    call PrintString

    ;; "HIGH" in Red (Pen 2) at column 12, row 1
    ld h, 12
    ld l, 1
    call #BB75
    ld hl, txt_high
    call PrintString

    ;; High Score at column 12, row 2
    call PrintHighScore

    ;; Initial Player Score "00000"
    call PrintScore
    call DrawStageHUD
    ret

PrintString:
.p_loop:
    ld a, (hl)
    or a
    ret z
    call #BB5A              ; TXT OUTPUT
    inc hl
    jr .p_loop

PrintScore:
    ld h, 2
    ld l, 2
    call #BB75
    ld a, 15                ; White
    call #BB90
    ld hl, (player_score)
    jr PrintHL5Digits

PrintHighScore:
    ld h, 12
    ld l, 2
    call #BB75
    ld a, 15                ; White
    call #BB90
    ld hl, (high_score)

PrintHL5Digits:
    ld bc, -10000
    call .digit
    ld bc, -1000
    call .digit
    ld bc, -100
    call .digit
    ld bc, -10
    call .digit
    ld a, l
    add a, '0'
    call #BB5A
    ret

.digit:
    ld a, '0' - 1
.digit_loop:
    inc a
    add hl, bc
    jr c, .digit_loop
    sbc hl, bc
    call #BB5A
    ret

DrawLivesHUD:
    ;; Mini ships at bottom scanline 190 (#FF80)
    ;; Clear previous badges
    xor a
    ld (#FF82), a
    ld (#FF86), a
    ld (#FF8A), a
    ld (#FF8E), a

    ld a, (player_lives)
    cp 2
    ret c                   ; 1 or 0 lives -> no reserve badges

    ld a, #AA               ; Mini white fighter icon
    ld (#FF82), a           ; Life 2
    ld a, (player_lives)
    cp 3
    ret c

    ld a, #AA
    ld (#FF86), a           ; Life 3
    ld a, (player_lives)
    cp 4
    ret c

    ld a, #AA
    ld (#FF8A), a           ; Life 4
    ld a, (player_lives)
    cp 5
    ret c

    ld a, #AA
    ld (#FF8E), a           ; Life 5
    ret

txt_1up:                defb "1UP", 0
txt_high:               defb "HIGH", 0
txt_high_val:           defb "20000", 0
txt_game_over:          defb "GAME  OVER", 0
txt_stage_hud:          defb "ST.", 0
txt_fighter_captured:   defb "FIGHTER CAPTURED", 0
txt_blank_captured:     defb "                ", 0
txt_challenging_stage:  defb "CHALLENGING STAGE", 0
txt_blank_challenging:  defb "                 ", 0
txt_num_hits:           defb "NUMBER OF HITS ", 0
txt_bonus_label:        defb "BONUS  ", 0
txt_perfect_bonus:      defb "SPECIAL BONUS 10000 PTS", 0
txt_pts_suffix:         defb "00 PTS", 0

DrawStageHUD:
    ;; Column 14, Row 25 (Bottom-right)
    ld h, 14
    ld l, 25
    call #BB75              ; TXT SET CURSOR
    ld a, 4                 ; Cyan
    call #BB90
    ld hl, txt_stage_hud
    call PrintString
    ld a, (current_stage)
    cp 10
    jr c, .single_digit
    ;; Two digits
    ld c, a
    ld a, '0'
.tens_loop:
    inc a
    dec c
    dec c
    dec c
    dec c
    dec c
    dec c
    dec c
    dec c
    dec c
    dec c
    ld b, a
    ld a, c
    cp 10
    ld a, b
    jr nc, .tens_loop
    call #BB5A
    ld a, c
    add a, '0'
    call #BB5A
    ret
.single_digit:
    add a, '0'
    call #BB5A
    ret


