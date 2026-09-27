;; ============================================================================
;; Galaga CPC - Stages & Wave Progression Management
;; ============================================================================

current_stage:          defb 1
stage_clear_active:     defb 0
stage_clear_timer:      defb 0
attack_threshold:       defb 130        ; Decreases as stages advance

txt_stage_label:        defb "STAGE ", 0
txt_blank_stage:        defb "        ", 0

;; ----------------------------------------------------------------------------
;; UpdateStageProgression: Check if wave is cleared and advance stage
;; ----------------------------------------------------------------------------
UpdateStageProgression:
    ld a, (game_over)
    or a
    ret nz

    ;; If in challenging stage, wave progression is handled by challenging.asm
    ld a, (is_challenging_stage)
    or a
    ret nz

    ld a, (stage_clear_active)
    or a
    jr nz, .in_clear_sequence

    ;; Check if any enemy is still alive
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.count_alive:
    ld a, (ix+0)
    or a
    ret nz                  ; At least one enemy alive -> return
    ld de, ENEMY_SIZE
    add ix, de
    djnz .count_alive

    ;; *** ALL ENEMIES DESTROYED! WAVE CLEARED! ***
    ld a, 1
    ld (stage_clear_active), a
    ld a, 90                ; ~1.8 seconds transition
    ld (stage_clear_timer), a

    ;; Award 1000 Stage Clear bonus points
    call AddPoints1000
    ret

.in_clear_sequence:
    ld a, (stage_clear_timer)
    dec a
    ld (stage_clear_timer), a
    cp 50
    jr z, .show_stage_banner
    cp 1
    jr z, .advance_stage
    ret

.show_stage_banner:
    ;; Check if next stage is Challenging Stage ((stage + 1) & 3 == 3)
    ld a, (current_stage)
    inc a
    and 3
    cp 3
    jr z, .show_challenging_banner

    ;; Display "STAGE X" in Cyan at center
    call DrawStageBanner
    ret

.show_challenging_banner:
    ;; Display "CHALLENGING STAGE" in Cyan at center
    call DrawChallengingBanner
    ret

.advance_stage:
    ;; Advance stage counter
    ld a, (current_stage)
    inc a
    ld (current_stage), a

    ;; Check if this is a Challenging Stage
    and 3
    cp 3
    jr z, .start_challenging

    ;; Clear "STAGE X" banner
    call ClearStageBanner

    ;; Increase difficulty: Faster attacks (down to min 50 frames)
    ld a, (attack_threshold)
    sub 15
    cp 50
    jr nc, .attack_speed_ok
    ld a, 50
.attack_speed_ok:
    ld (attack_threshold), a

    ;; Update HUD with new stage number at bottom right
    call DrawStageHUD

    ;; Respawn authentic formation
    call InitEnemies

    ;; Finish clear sequence
    xor a
    ld (stage_clear_active), a
    ret

.start_challenging:
    ;; Clear "CHALLENGING STAGE" banner
    call ClearChallengingBanner

    ;; Update HUD with new stage number at bottom right
    call DrawStageHUD

    ;; Start authentic Challenging Stage!
    call StartChallengingStage

    ;; Finish clear sequence
    xor a
    ld (stage_clear_active), a
    ret

