;; ============================================================================
;; Galaga CPC - Challenging Stages (Stages 3, 7, 11, ...)
;; Amstrad CPC 464 / 6128
;; Reference: StrategyWiki Walkthrough - Section 3 "Challenging Stage"
;; ============================================================================

StartChallengingStage:
    ld a, 1
    ld (is_challenging_stage), a
    ld (challenging_active), a
    ld a, 1
    ld (challenging_wave), a
    xor a
    ld (challenging_hits), a
    ld (challenging_spawn_cnt), a
    ld a, 15
    ld (challenging_timer), a

    ;; Clear all enemies from formation
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.clear_ch_enemies:
    ld (ix+0), 0            ; alive = 0
    ld de, ENEMY_SIZE
    add ix, de
    djnz .clear_ch_enemies

    ;; Clean up any leftover captured fighter sprite if any
    ld a, (captured_fighter_active)
    cp 3
    jr nz, .no_ch_rescue_dock
    call ClearCapturedFighterSprite
    xor a
    ld (captured_fighter_active), a
    ld a, 1
    ld (is_dual_fighter), a
.no_ch_rescue_dock:
    call ClearCapturedFighterSprite
    call StopMusic
    ld a, 1
    ld (drone_active), a
    ld a, 15
    ld (drone_step), a
    ld a, 1
    ld (drone_timer), a
    ret

UpdateChallengingStage:
    ld a, (is_challenging_stage)
    or a
    ret z

    ld a, (challenging_active)
    or a
    ret z

    ;; Check if in results tally sequence
    cp 2
    jp z, .update_results_sequence

    ;; --- Normal wave gameplay ---
    ;; 1. Check timer between spawns / waves
    ld a, (challenging_timer)
    or a
    jr z, .spawn_or_move
    dec a
    ld (challenging_timer), a
    jr .move_wave_enemies

.spawn_or_move:
    ;; Check if we still have enemies to spawn in this wave (8 enemies per wave)
    ld a, (challenging_spawn_cnt)
    cp 8
    jr nc, .check_wave_cleared

    or a
    jr nz, .no_wave_start_sfx
    ;; First enemy in wave: Play Flying Enemy attack sound!
    call PlaySoundDive
.no_wave_start_sfx:

    ;; Spawn 1 enemy in first available slot
    call SpawnChallengingEnemy
    ld a, (challenging_spawn_cnt)
    inc a
    ld (challenging_spawn_cnt), a
    ld a, 4                 ; 4 updates between spawns
    ld (challenging_timer), a

.move_wave_enemies:
    ;; 2. Move all alive challenging enemies
    call MoveChallengingEnemies
    ret

.check_wave_cleared:
    ;; All 8 enemies spawned. Check if any are still alive
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.chk_alive_loop:
    ld a, (ix+0)
    or a
    jr nz, .move_wave_enemies
    ld de, ENEMY_SIZE
    add ix, de
    djnz .chk_alive_loop

    ;; All 8 enemies in this wave either destroyed or exited!
    ;; Advance to next wave!
    xor a
    ld (challenging_spawn_cnt), a
    ld a, 20                ; 20 updates pause before next wave
    ld (challenging_timer), a

    ld a, (challenging_wave)
    inc a
    ld (challenging_wave), a
    cp 6                    ; All 5 waves done?
    ret c

    ;; *** ALL 5 WAVES COMPLETED (40 ENEMIES)! ***
    ;; Switch to Results Screen sequence
    call StopChallengingMusic
    ld a, 2
    ld (challenging_active), a
    ld a, 20                ; ~0.8 second pause after music finishes
    ld (challenging_timer), a

    ;; Check if 40 hits (PERFECT!)
    ld a, (challenging_hits)
    cp 40
    jr nz, .award_partial

    ;; Perfect 40 hits! Play authentic Perfect Victory Fanfare!
    call PlayMusicChallengingPerfect
    call AddPoints10000
    jr .first_draw_results

.award_partial:
    ;; Imperfect hits: Play authentic Results Theme!
    call PlayMusicChallengingResults

    ld a, (challenging_hits)
    or a
    jr z, .first_draw_results
    ld b, a
.add_bonus_loop:
    push bc
    call AddPoints100
    pop bc
    djnz .add_bonus_loop

.first_draw_results:
    call DrawChallengingResults
    ret

.update_results_sequence:
    ;; Wait until music finishes playing before counting down timer!
    ld a, (music_playing)
    or a
    ret nz

    ld a, (challenging_timer)
    dec a
    ld (challenging_timer), a
    ret nz

    ;; Results display finished! Clear screen text and advance stage!
    ld b, CH_RESULTS_X : ld c, CH_RESULTS_Y1 : ld d, 56 : call ClearTextRect
    ld b, CH_RESULTS_X : ld c, CH_RESULTS_Y2 : ld d, 56 : call ClearTextRect

    xor a
    ld (is_challenging_stage), a
    ld (challenging_active), a

    ;; Advance to next stage (supports 255 stages continuous loop)
    ld a, (current_stage)
    inc a
    or a
    jr nz, .ch_st_no_wrap
    inc a               ; 255 wraps to 1
.ch_st_no_wrap:
    ld (current_stage), a
    call DrawStageHUD
    call InitEnemies
    ret

;; ----------------------------------------------------------------------------
;; DrawChallengingResults: Display challenging hits and bonus tally
;; Can be called every frame to maintain text priority over player missiles
;; ----------------------------------------------------------------------------
DrawChallengingResults:
    ;; Display "NUMBER OF HITS  XX" in Cyan/White, centred in the playfield
    ld b, CH_RESULTS_X : ld c, CH_RESULTS_Y1
    ld hl, str_number_of_hits
    call DrawGlyphString
    ld a, (challenging_hits)
    ld b, CH_RESULTS_X + 45 : ld c, CH_RESULTS_Y1
    call Draw2DigitsWhite

    ;; Display Bonus line
    ld a, (challenging_hits)
    cp 40
    jr nz, .cr_partial

    ;; Perfect 40 hits: "SPECIAL 10000 PTS"
    ld b, CH_RESULTS_X + 2 : ld c, CH_RESULTS_Y2
    ld hl, str_special_10000
    jp DrawGlyphString

.cr_partial:
    ;; Partial hits: "BONUS " + XX + "00 PTS"
    ld b, CH_RESULTS_X + 5 : ld c, CH_RESULTS_Y2
    ld hl, str_bonus_label
    call DrawGlyphString
    ld a, (challenging_hits)
    ld b, CH_RESULTS_X + 23 : ld c, CH_RESULTS_Y2
    call Draw2DigitsWhite
    ld b, CH_RESULTS_X + 29 : ld c, CH_RESULTS_Y2 : ld hl, f_w_0 : call DrawGlyph
    ld b, CH_RESULTS_X + 32 : ld c, CH_RESULTS_Y2 : ld hl, f_w_0 : call DrawGlyph
    ld b, CH_RESULTS_X + 35 : ld c, CH_RESULTS_Y2
    ld hl, str_pts_label
    jp DrawGlyphString


AddPoints10000:
    ld bc, 10000
    jp apply_points

GetChallengingStageEnemyType:
    ld a, (current_stage)
    sub 3
    srl a
    srl a
    and 7
    ld e, a
    ld d, 0
    ld hl, challenging_stage_types
    add hl, de
    ld a, (hl)
    ret

challenging_stage_types:
    defb 0  ; Stage 3:  Zako & Goei (Bees & Butterflies)
    defb 6  ; Stage 7:  Sasori (Yellow Scorpions)
    defb 4  ; Stage 11: Momiji (Satellites)
    defb 5  ; Stage 15: Enterprise
    defb 3  ; Stage 19: Tonbo (Dragonfly)
    defb 7  ; Stage 23: Midori (Stingray)
    defb 8  ; Stage 27: Galboss (Flagship)
    defb 6  ; Stage 31: Sasori (Cycle repeats)

;; ----------------------------------------------------------------------------
;; SpawnChallengingEnemy: Spawn 1 enemy for current wave pattern
;; ----------------------------------------------------------------------------
SpawnChallengingEnemy:
    ;; Find free slot in enemy_data
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_ch_slot:
    ld a, (ix+0)
    or a
    jr z, .ch_slot_ok
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_ch_slot
    ret

.ch_slot_ok:
    ld (ix+0), 1            ; alive = 1
    ld (ix+8), 1            ; state = 1 (in flight)
    ld (ix+9), 1            ; hp = 1
    ld (ix+6), 0            ; anim frame

    ;; Set signature enemy for current challenging stage
    call GetChallengingStageEnemyType
    ld (ix+1), a

    ;; In Stage 3 (Challenging Stage 1): Waves 1-2 = Bees (0), Waves 3-5 = Butterflies (1)
    ld a, (current_stage)
    cp 3
    jr nz, .not_st3_mix
    ld a, (challenging_wave)
    cp 3
    jr c, .st3_zako
    ld (ix+1), 1            ; Goei Butterfly for Waves 3, 4, 5
    jr .not_st3_mix
.st3_zako:
    ld (ix+1), 0            ; Zako Bee for Waves 1, 2
.not_st3_mix:

    ;; Set enemy type and starting coordinates according to wave
    ld a, (challenging_wave)
    cp 1
    jr z, .spawn_w1
    cp 2
    jr z, .spawn_w2
    cp 3
    jr z, .spawn_w3
    cp 4
    jr z, .spawn_w4

    ;; Wave 5: 4 Boss Galagas + 4 signature enemies (arcade authentic)
    ld a, (challenging_spawn_cnt)
    cp 4
    jr nc, .w5_stage_enemy
    ld (ix+1), 2            ; Boss Galaga
.w5_stage_enemy:
    ld a, 74 + PF_OLD_DX
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 1           ; step direction: moving left
    jr .spawn_draw

.spawn_w1:
    ;; Wave 1: Enemies from top center
    ld a, (challenging_spawn_cnt)
    and 1
    jr nz, .w1_right
    ld a, 38 + PF_OLD_DX
    jr .w1_set_x
.w1_right:
    ld a, 48 + PF_OLD_DX
.w1_set_x:
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 0           ; direction flag
    jr .spawn_draw

.spawn_w2:
    ;; Wave 2: Upper left swoop
    ld a, 14 + PF_OLD_DX
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 0
    jr .spawn_draw

.spawn_w3:
    ;; Wave 3: Upper right swoop
    ld a, 74 + PF_OLD_DX
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 1
    jr .spawn_draw

.spawn_w4:
    ;; Wave 4: Entering from left, weaving right
    ld a, 14 + PF_OLD_DX
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 0

.spawn_draw:
    call DrawEnemyIX
    ret

;; ----------------------------------------------------------------------------
;; MoveChallengingEnemies: Move and draw all active challenging enemies
;; ----------------------------------------------------------------------------
MoveChallengingEnemies:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.ch_move_loop:
    ld a, (ix+0)
    or a
    jp z, .next_ch_m

    ;; 1. The old sprite is erased just before drawing at the new position,
    ;; so the enemy is never left blank while the raster passes it.

    ;; 2. Move Y down
    ld a, (ix+3)
    add a, FLIGHT_STEP_Y
    cp SPRITE_Y_LIMIT - 2
    jp nc, .kill_ch_enemy   ; Reached bottom -> exit screen

    ld (ix+3), a

    ;; 3. Move X according to wave pattern
    ld a, (challenging_wave)
    cp 1
    jr z, .move_w1
    cp 2
    jr z, .move_w2
    cp 3
    jr z, .move_w3
    cp 4
    jp z, .move_w4

    ;; --- Wave 5: S-curve weave travelling across to the left ---
    ld a, (ix+3)
    and 16
    jr nz, .w5_slower
    ld a, (ix+2)
    sub 6
    jr .w5_chk_l
.w5_slower:
    call FlightStepX
    ld c, a
    ld a, (ix+2)
    sub c
.w5_chk_l:
    jp c, .kill_ch_enemy
    cp PLAY_X_MIN
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w1:
    ;; Wave 1: loop curve
    ld a, (ix+3)
    cp 60 + PF_OLD_DY
    jr c, .w1_down
    cp 130 + PF_OLD_DY
    jr nc, .w1_down
    ;; Arc outward
    ld a, (ix+10)
    or a
    jr nz, .w1_arc_r
    call FlightStepX
    ld c, a
    ld a, (ix+2)
    sub c
    jp c, .kill_ch_enemy
    cp PLAY_X_MIN
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now
.w1_arc_r:
    call FlightStepX
    add a, (ix+2)
    cp PLAY_X_MAX
    jp nc, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now
.w1_down:
    jr .ch_draw_now

.move_w2:
    ;; Wave 2: sweep right diagonally
    call FlightStepX
    add a, (ix+2)
    cp PLAY_X_MAX
    jp nc, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w3:
    ;; Wave 3: sweep left diagonally
    call FlightStepX
    ld c, a
    ld a, (ix+2)
    sub c
    jp c, .kill_ch_enemy
    cp PLAY_X_MIN
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w4:
    ;; Wave 4: S-curve weave travelling across to the right
    ld a, (ix+3)
    and 16
    jr nz, .w4_slower
    ld a, (ix+2)
    add a, 6
    jr .w4_chk_r
.w4_slower:
    call FlightStepX
    add a, (ix+2)
.w4_chk_r:
    cp PLAY_X_MAX
    jp nc, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.ch_draw_now:
    ;; Animated wing flap / sprite alternation every 16 scanlines of flight
    ld a, (ix+3)
    rlca
    rlca
    rlca
    rlca
    and 1
    ld (ix+6), a

    call EraseEnemyDeltaIX
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a

    push bc
    call DrawEnemyIX
    pop bc
    jr .next_ch_m

.kill_ch_enemy:
    call EraseEnemyOldIX
    ld (ix+0), 0

.next_ch_m:
    ld de, ENEMY_SIZE
    add ix, de
    dec b
    jp nz, .ch_move_loop
    ret
