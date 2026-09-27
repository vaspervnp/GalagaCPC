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
    ld a, 30
    ld (challenging_timer), a

    ;; Clear all enemies from formation
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.clear_ch_enemies:
    ld (ix+0), 0            ; alive = 0
    ld de, ENEMY_SIZE
    add ix, de
    djnz .clear_ch_enemies
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

    ;; Spawn 1 enemy in first available slot
    call SpawnChallengingEnemy
    ld a, (challenging_spawn_cnt)
    inc a
    ld (challenging_spawn_cnt), a
    ld a, 8                 ; 8 frames between spawns
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
    ld a, 40                ; 40 frames pause before next wave
    ld (challenging_timer), a

    ld a, (challenging_wave)
    inc a
    ld (challenging_wave), a
    cp 6                    ; All 5 waves done?
    ret c

    ;; *** ALL 5 WAVES COMPLETED (40 ENEMIES)! ***
    ;; Switch to Results Screen sequence
    ld a, 2
    ld (challenging_active), a
    ld a, 140               ; ~2.8 seconds results display
    ld (challenging_timer), a

    ;; Display "HITS  XX" in Cyan/White at X=36, Y=100
    ld b, 36 : ld c, 100 : ld hl, f_c_H : call DrawGlyph
    ld b, 39 : ld c, 100 : ld hl, f_c_I : call DrawGlyph
    ld b, 42 : ld c, 100 : ld hl, f_c_T : call DrawGlyph
    ld b, 45 : ld c, 100 : ld hl, f_c_S : call DrawGlyph
    ld b, 48 : ld c, 100 : ld hl, f_c_SPACE : call DrawGlyph
    ld a, (challenging_hits)
    ld b, 51 : ld c, 100
    call Draw2DigitsWhite

    ;; Display Bonus line at Y=116
    ld a, (challenging_hits)
    cp 40
    jr nz, .partial_bonus

    ;; Perfect 40 hits: "PERFECT" in Cyan at X=36, Y=116
    ld b, 36 : ld c, 116 : ld hl, f_c_P : call DrawGlyph
    ld b, 39 : ld c, 116 : ld hl, f_c_E : call DrawGlyph
    ld b, 42 : ld c, 116 : ld hl, f_c_R : call DrawGlyph
    ld b, 45 : ld c, 116 : ld hl, f_c_F : call DrawGlyph
    ld b, 48 : ld c, 116 : ld hl, f_c_E : call DrawGlyph
    ld b, 51 : ld c, 116 : ld hl, f_c_C : call DrawGlyph
    ld b, 54 : ld c, 116 : ld hl, f_c_T : call DrawGlyph
    call AddPoints10000
    ret

.partial_bonus:
    ;; Partial hits: "BONUS " + XX + "00" in Cyan at X=32, Y=116
    ld b, 32 : ld c, 116 : ld hl, f_c_B : call DrawGlyph
    ld b, 35 : ld c, 116 : ld hl, f_c_O : call DrawGlyph
    ld b, 38 : ld c, 116 : ld hl, f_c_N : call DrawGlyph
    ld b, 41 : ld c, 116 : ld hl, f_c_U : call DrawGlyph
    ld b, 44 : ld c, 116 : ld hl, f_c_S : call DrawGlyph
    ld b, 47 : ld c, 116 : ld hl, f_c_SPACE : call DrawGlyph
    ld a, (challenging_hits)
    ld b, 50 : ld c, 116
    call Draw2DigitsWhite
    ld b, 56 : ld c, 116 : ld hl, f_w_0 : call DrawGlyph
    ld b, 59 : ld c, 116 : ld hl, f_w_0 : call DrawGlyph

    ;; Award hits * 100 points
    ld a, (challenging_hits)
    or a
    ret z
    ld b, a
.add_bonus_loop:
    push bc
    call AddPoints100
    pop bc
    djnz .add_bonus_loop
    ret

.update_results_sequence:
    ld a, (challenging_timer)
    dec a
    ld (challenging_timer), a
    ret nz

    ;; Results display finished! Clear screen text and advance stage!
    ld b, 32 : ld c, 100 : ld d, 32 : call ClearTextRect
    ld b, 32 : ld c, 116 : ld d, 32 : call ClearTextRect

    xor a
    ld (is_challenging_stage), a
    ld (challenging_active), a

    ;; Advance to next stage (Stage 4)
    ld a, (current_stage)
    inc a
    ld (current_stage), a
    call DrawStageHUD
    call InitEnemies
    ret

AddPoints10000:
    ld bc, 10000
    jp apply_points

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

    ;; Wave 5: Enterprise (type 5) from right center swooping left
    ld (ix+1), 5            ; type 5 = Enterprise
    ld a, 68
    ld (ix+2), a
    ld (ix+4), a
    ld a, 36
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 1           ; step direction: moving left
    jr .spawn_draw

.spawn_w1:
    ;; Wave 1: Bees (type 0) from top center
    ld (ix+1), 0            ; type 0 = Bee
    ld a, (challenging_spawn_cnt)
    and 1
    jr nz, .w1_right
    ld a, 32
    jr .w1_set_x
.w1_right:
    ld a, 40
.w1_set_x:
    ld (ix+2), a
    ld (ix+4), a
    ld a, 24
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 0           ; direction flag
    jr .spawn_draw

.spawn_w2:
    ;; Wave 2: Butterflies (type 1) from upper left
    ld (ix+1), 1
    ld a, 4
    ld (ix+2), a
    ld (ix+4), a
    ld a, 28
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 0
    jr .spawn_draw

.spawn_w3:
    ;; Wave 3: Butterflies (type 1) from upper right
    ld (ix+1), 1
    ld a, 68
    ld (ix+2), a
    ld (ix+4), a
    ld a, 28
    ld (ix+3), a
    ld (ix+5), a
    ld (ix+10), 1
    jr .spawn_draw

.spawn_w4:
    ;; Wave 4: Tonbo Dragonflies (type 3) from left center
    ld (ix+1), 3
    ld a, 4
    ld (ix+2), a
    ld (ix+4), a
    ld a, 40
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

    ;; 1. Erase old sprite
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call GetScreenAddr
    ex de, hl
    call ClearSprite16x16
    pop bc

    ;; 2. Move Y down by 2 scanlines
    ld a, (ix+3)
    add a, 2
    cp 175
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
    jr z, .move_w4
    ;; Wave 5: sweep left
    ld a, (ix+2)
    dec a
    cp 2
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w1:
    ;; Wave 1: loop curve
    ld a, (ix+3)
    cp 60
    jr c, .w1_down
    cp 110
    jr nc, .w1_down
    ;; Arc outward
    ld a, (ix+10)
    or a
    jr nz, .w1_arc_r
    ld a, (ix+2)
    dec a
    cp 2
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now
.w1_arc_r:
    ld a, (ix+2)
    inc a
    cp 71
    jp nc, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now
.w1_down:
    jr .ch_draw_now

.move_w2:
    ;; Wave 2: sweep right diagonally
    ld a, (ix+2)
    inc a
    cp 71
    jp nc, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w3:
    ;; Wave 3: sweep left diagonally
    ld a, (ix+2)
    dec a
    cp 2
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now

.move_w4:
    ;; Wave 4: sinusoidal weave
    ld a, (ix+3)
    and 16
    jr nz, .w4_r
    ld a, (ix+2)
    dec a
    cp 2
    jp c, .kill_ch_enemy
    ld (ix+2), a
    jr .ch_draw_now
.w4_r:
    ld a, (ix+2)
    inc a
    cp 71
    jp nc, .kill_ch_enemy
    ld (ix+2), a


.ch_draw_now:
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a

    push bc
    call DrawEnemyIX
    pop bc
    jr .next_ch_m

.kill_ch_enemy:
    ld (ix+0), 0

.next_ch_m:
    ld de, ENEMY_SIZE
    add ix, de
    dec b
    jp nz, .ch_move_loop
    ret
