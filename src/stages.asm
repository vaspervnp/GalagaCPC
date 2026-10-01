;; ============================================================================
;; Galaga CPC - Stages & Wave Progression Management
;; ============================================================================

stage_clear_active:     defb 0
stage_clear_timer:      defb 0
stage_intro_state:      defb 0          ; 0=none, 1=STAGE n, 2=PLAYER n
stage_intro_timer:      defb 0          ; Countdown timer

;; Set the first dive-attack interval for the selected difficulty.
InitAttackThreshold:
    ld a, (difficulty_level)
    or a
    jr z, .easy
    cp 1
    jr z, .medium
    cp 2
    jr z, .hard
    ld a, 55
    jr .store
.hard:
    ld a, 75
    jr .store
.medium:
    ld a, 100
    jr .store
.easy:
    ld a, 130
.store:
    ld (attack_threshold), a
    ret


;; ----------------------------------------------------------------------------
;; StageWatchdog: Safety net for enemies lost outside the playfield. If enemies
;; are alive but none has been inside the visible playfield for
;; STAGE_WATCHDOG_FRAMES, remove them so the stage can be cleared.
;; ----------------------------------------------------------------------------
StageWatchdog:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
    ld c, 0                 ; C = 1 if any enemy is alive
.scan:
    ld a, (ix+0)
    or a
    jr z, .next
    ld c, 1
    ld a, (ix+3)
    cp PF_Y_TOP
    jr c, .next
    cp SPRITE_Y_LIMIT
    jr c, .visible
.next:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .scan

    ld a, c
    or a
    jr z, .visible          ; Nothing alive: the normal clear check handles it.
    ld a, (stage_watchdog)
    inc a
    ld (stage_watchdog), a
    cp STAGE_WATCHDOG_FRAMES
    ret c

    ;; Every remaining enemy is lost off screen: remove them.
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.remove:
    ld (ix+0), 0
    ld de, ENEMY_SIZE
    add ix, de
    djnz .remove
.visible:
    xor a
    ld (stage_watchdog), a
    ret

;; ----------------------------------------------------------------------------
;; UpdateStageIntro: Update Stage 1 Intro sequence
;; State 1: "STAGE 1" for 105 frames (~2.1s)
;; State 2: "PLAYER 1" for 50 frames (~1.0s)
;; ----------------------------------------------------------------------------
UpdateStageIntro:
    ld a, (stage_intro_state)
    cp 1
    jr z, .intro_state_1
    cp 2
    jr z, .intro_state_2
    ret

.intro_state_1:
    ld a, (stage_intro_timer)
    dec a
    ld (stage_intro_timer), a
    ret nz

    ;; Stage 1 banner timer expired! Switch to Player 1 banner
    call ClearStageBanner
    ld a, 2
    ld (stage_intro_state), a
    ld a, 50                    ; 1.0 second (at 50Hz)
    ld (stage_intro_timer), a
    call DrawPlayerBanner
    ret

.intro_state_2:
    ld a, (stage_intro_timer)
    dec a
    ld (stage_intro_timer), a
    ret nz

    ;; Player 1 banner timer expired! Clear banner and start entry swarm
    call ClearPlayerBanner
    xor a
    ld (stage_intro_state), a

    ;; Start entry swarm spawning on next frame
    ld a, 1
    ld (entry_spawn_timer), a
    ret

;; ----------------------------------------------------------------------------
;; UpdateStageProgression: Check if wave is cleared and advance stage
;; ----------------------------------------------------------------------------
UpdateStageProgression:
    ld a, (game_over)
    or a
    ret nz

    ;; If Stage 1 Intro is active, wave cannot be cleared
    ld a, (stage_intro_state)
    or a
    ret nz

    ;; If in challenging stage, wave progression is handled by challenging.asm
    ld a, (is_challenging_stage)
    or a
    ret nz

    ld a, (stage_clear_active)
    or a
    jr nz, .in_clear_sequence

    ;; A wave CANNOT be cleared until all enemies have finished spawning!
    ld a, (entry_spawn_idx)
    ld hl, stage_enemy_total
    cp (hl)
    ret c                   ; Still spawning enemies -> cannot be cleared!

    call StageWatchdog


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

    ;; Even if all enemies are dead, wave CANNOT be cleared if a captured fighter
    ;; is still active or descending to dock with player!
    ld a, (captured_fighter_active)
    or a
    ret nz                  ; Wait until rescued fighter finishes docking!

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
    ;; Advance stage counter (supports 255 stages continuous loop)
    ld a, (current_stage)
    inc a
    or a
    jr nz, .next_st_nowrap
    inc a               ; 255 wraps to 1
.next_st_nowrap:
    ld (current_stage), a

    ;; Update HUD with new stage number at bottom right
    call DrawStageHUD

    ;; Check if next stage is Challenging Stage (Stage 3, 7, 11, 15... every 4 levels)
    ld a, (current_stage)
    and 3
    cp 3
    jr z, .show_challenging_banner

    ;; Display "STAGE X" in Cyan at center
    call DrawStageBanner
    ret

.show_challenging_banner:
    ;; Display "CHALLENGING STAGE" in Cyan at center
    call DrawChallengingBanner
    call PlayMusicChallengingStart
    ret

.advance_stage:
    ;; Check if this was a Challenging Stage (Stage 3, 7, 11, 15...)
    ld a, (current_stage)
    and 3
    cp 3
    jr z, .start_challenging

    ;; Clear "STAGE X" banner
    call ClearStageBanner

    ;; Easy retains its original cadence. Higher tiers accelerate faster and
    ;; can reach a 16-frame minimum attack interval.
    ld a, (difficulty_level)
    or a
    jr z, .easy_attack_speed
    ld b, a
    add a, a
    add a, b
    add a, 15
    ld b, a
    ld a, (attack_threshold)
    sub b
    jr c, .hard_attack_floor
    cp 16
    jr nc, .store_attack_speed
.hard_attack_floor:
    ld a, 16
    jr .store_attack_speed
.easy_attack_speed:
    ld a, (attack_threshold)
    sub 15
    cp 50
    jr nc, .store_attack_speed
    ld a, 50
.store_attack_speed:
    ld (attack_threshold), a

    ;; Respawn authentic formation
    call InitEnemies

    ;; Finish clear sequence
    xor a
    ld (stage_clear_active), a
    ret

.start_challenging:
    ;; Clear "CHALLENGING STAGE" banner
    call ClearChallengingBanner

    ;; Start authentic Challenging Stage!
    call StartChallengingStage

    ;; Finish clear sequence
    xor a
    ld (stage_clear_active), a
    ret
