;; ============================================================================
;; Galaga CPC - Enemies Logic & Formation Management
;; ============================================================================

InitEnemies:
    xor a
    ld (sway_offset), a
    ld (attack_timer), a
    ld (attack_cycle), a
    ld (transform_trigger_cnt), a
    ld (transform_killed), a
    ld (stage_phase), a         ; STAGE_PHASE_ENTRY = 0
    ld (entry_spawn_idx), a
    ld (entry_music_catchup), a
    call SetStageEnemyTotal
    call SelectEntryShooters

    ;; Clear all enemies in enemy_data
    ld hl, enemy_data
    ld de, enemy_data + 1
    ld bc, (ENEMY_SIZE * ENEMY_COUNT) - 1
    ld (hl), 0
    ldir

    ;; Clean up any leftover captured fighter sprite if any
    ld a, (captured_fighter_active)
    cp 3
    jr nz, .no_init_rescue_dock
    call ClearCapturedFighterSprite
    xor a
    ld (captured_fighter_active), a
    ld a, 1
    ld (is_dual_fighter), a
.no_init_rescue_dock:
    call ClearCapturedFighterSprite

    ;; If Stage 1 (new game), wait for stage intro banners before spawning
    ld a, (current_stage)
    cp 1
    jr nz, .not_st1_init
    xor a
    ld (entry_spawn_timer), a   ; Stage 1 intro starts spawn when banners finish
    ret

.not_st1_init:
    ld a, 1
    ld (entry_spawn_timer), a   ; Spawn first enemy on next frame!
    call PlaySoundStageStart
    ret

SetStageEnemyTotal:
    ld a, (current_stage)
    cp 10
    jr nc, .max_enemy_total
    ld b, a
    srl a
    srl a
    ld c, a
    ld a, b
    sub c
    dec a
    add a, a
    add a, 14
    jr .store_enemy_total
.max_enemy_total:
    ld a, 28
.store_enemy_total:
    ld (stage_enemy_total), a
    ret

;; Easy uses stages 10/20/30 for 1/2/3 shooters; higher difficulties
;; shift these thresholds earlier and add one shooter per difficulty tier.
SelectEntryShooters:
    ld hl, entry_shooter_flags
    ld de, entry_shooter_flags + 1
    ld bc, ENEMY_COUNT - 1
    xor a
    ld (hl), a
    ldir

    ld a, (difficulty_level)
    ld b, a
    add a, a
    add a, b
    ld b, a
    ld a, (current_stage)
    add a, b
    jr nc, .effective_stage_ready
    ld a, 255
.effective_stage_ready:
    cp 10
    ret c
    cp 20
    jr c, .one_shooter
    cp 30
    jr c, .two_shooters
    ld a, 3
    jr .store_base_quota
.two_shooters:
    ld a, 2
    jr .store_base_quota
.one_shooter:
    ld a, 1
.store_base_quota:
    ld b, a
    ld a, (difficulty_level)
    add a, b
    cp 5
    jr c, .store_quota
    ld a, 4
.store_quota:
    ld (entry_shooter_quota), a

    xor a
    ld b, 4
    call SelectEntryGroupShooters
    ld a, 4
    ld b, 6
    call SelectEntryGroupShooters
    ld a, 10
    ld b, 6
    call SelectEntryGroupShooters
    ld a, 16
    ld b, 6
    call SelectEntryGroupShooters
    ld a, 22
    ld b, 6
    jp SelectEntryGroupShooters

;; Input: A=first enemy index, B=group size.
SelectEntryGroupShooters:
    ld (entry_shooter_start), a
    ld a, b
    ld (entry_shooter_size), a
    ld a, (entry_shooter_quota)
    ld (entry_shooter_left), a
.choose_next:
    ld a, (entry_shooter_left)
    or a
    ret z
    call GetRandomByte
    ld hl, entry_shooter_size
.reduce_to_group:
    cp (hl)
    jr c, .group_offset_ready
    sub (hl)
    jr .reduce_to_group
.group_offset_ready:
    ld hl, entry_shooter_start
    add a, (hl)
    ld l, a
    ld h, 0
    ld de, entry_shooter_flags
    add hl, de
    ld a, (hl)
    or a
    jr nz, .choose_next
    inc a
    ld (hl), a
    ld hl, entry_shooter_left
    dec (hl)
    jr .choose_next

;; Mix the changing Z80 refresh register into a small non-zero PRNG state.
GetRandomByte:
    ld a, r
    ld hl, random_seed
    xor (hl)
    rlca
    xor #A7
    jr nz, .store_random
    inc a
.store_random:
    ld (hl), a
    ret

DrawEnemyIX:
    ld a, (ix+0)            ; alive?
    or a
    ret z

    ;; Choose sprite based on type, hp, and anim_frame
    ld a, (ix+1)            ; type
    cp 8
    jp z, .draw_galboss
    cp 7
    jp z, .draw_stingray
    cp 6
    jp z, .draw_sasori
    cp 5
    jp z, .draw_enterprise
    cp 4
    jp z, .draw_momiji
    cp 3
    jp z, .draw_tonbo
    cp 2
    jp z, .draw_boss
    cp 1
    jp z, .draw_butterfly

    ;; Type 0: Zako Bee
    ld a, (ix+6)
    or a
    jr nz, .bee_f2
    ld hl, zako_bee_1
    jr .do_draw
.bee_f2:
    ld hl, zako_bee_2
    jr .do_draw

.draw_butterfly:
    ld a, (ix+6)
    or a
    jr nz, .bf_f2
    ld hl, goei_butterfly_1
    jr .do_draw
.bf_f2:
    ld hl, goei_butterfly_2
    jr .do_draw

.draw_boss:
    ;; Boss Galaga
    ld a, (ix+9)            ; hp
    cp 1
    jr z, .boss_damaged
    ;; Full health (Green)
    ld a, (ix+6)
    or a
    jr nz, .boss_f2
    ld hl, boss_galaga_1
    jr .do_draw
.boss_f2:
    ld hl, boss_galaga_2
    jr .do_draw
.boss_damaged:
    ld a, (ix+6)
    or a
    jr nz, .boss_dmg_f2
    ld hl, boss_galaga_damaged
    jr .do_draw
.boss_dmg_f2:
    ld hl, boss_galaga_damaged_2
    jr .do_draw

.draw_tonbo:
    ld hl, tonbo_dragonfly
    jr .do_draw

.draw_momiji:
    ld hl, momiji_satellite
    jr .do_draw

.draw_enterprise:
    ld hl, enterprise_bonus
    jr .do_draw

.draw_sasori:
    ld hl, sasori_scorpion
    jr .do_draw

.draw_stingray:
    ld a, (ix+6)
    or a
    jr nz, .sting_f2
    ld hl, midori_stingray_1
    jr .do_draw
.sting_f2:
    ld hl, midori_stingray_2
    jr .do_draw

.draw_galboss:
    ld a, (ix+6)
    or a
    jr nz, .gb_f2
    ld hl, galboss_flagship_1
    jr .do_draw
.gb_f2:
    ld hl, galboss_flagship_2
    jr .do_draw


.do_draw:
    ld b, (ix+2)
    ld c, (ix+3)
    call DrawSprite16x16
    ret

;; Helper to draw enemy pointed to by IY while safely preserving IX
DrawEnemyIY:
    push ix
    push iy
    pop ix
    call DrawEnemyIX
    pop ix
    ret

UpdateEnemies:
    ;; Check if Results Screen is active during Game Over
    ld a, (game_over)
    or a
    jr z, .not_results_freeze
    ld a, (game_over_phase)
    cp 1
    ret z       ; Freeze all enemy updates during Results Screen!
.not_results_freeze:

    ;; Check if Stage Intro is running (Level 1 Intro)
    ld a, (stage_intro_state)
    or a
    jr z, .not_stage_intro
    call UpdateStageIntro
    ret
.not_stage_intro:

    ld a, (is_challenging_stage)
    or a
    jp nz, UpdateChallengingStage

    ;; Decrement enemy firing freeze timer (diving Boss Galaga kill effect)
    ld a, (enemy_fire_freeze)
    or a
    jr z, .no_freeze_dec
    dec a
    ld (enemy_fire_freeze), a
.no_freeze_dec:

    ;; Check if in Entry Phase (stage_phase == STAGE_PHASE_ENTRY)
    ld a, (stage_phase)
    or a
    jp z, UpdateEntryPhase

    ;; --- Attack Phase ---

    ;; --- 1. Check Wing Flap Timer ---
    ld a, (flap_timer)
    inc a

    ld (flap_timer), a
    cp 18
    jr c, .check_sway

    xor a
    ld (flap_timer), a
    ld a, (global_anim)
    xor 1
    ld (global_anim), a

    ;; Redraw all alive enemies in formation with new wing frame
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.flap_loop:
    ld a, (ix+0)
    or a
    jr z, .next_flap
    ld a, (ix+8)            ; only if in formation (state==0)
    or a
    jr nz, .next_flap
    ld a, (global_anim)
    ld (ix+6), a
    push bc
    call DrawEnemyIX
    pop bc
.next_flap:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .flap_loop

.check_sway:
    ;; --- 2. Check Formation Sway Timer ---
    ld a, (sway_timer)
    inc a
    ld (sway_timer), a
    cp 10
    jr c, .check_dive_trigger

    xor a
    ld (sway_timer), a

    ;; Update sway_offset (-2 to +2)
    ld a, (sway_dir)
    ld b, a
    ld a, (sway_offset)
    add a, b
    ld (sway_offset), a

    cp 2
    jr nz, .chk_left
    ld a, -1
    ld (sway_dir), a
    jr .apply_sway

.chk_left:
    cp -2
    jr nz, .apply_sway
    ld a, 1
    ld (sway_dir), a

.apply_sway:
    ;; Apply sway_offset to alive enemies in formation
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.sway_loop:
    ld a, (ix+0)
    or a
    jr z, .next_sway
    ld a, (ix+8)            ; state == 0?
    or a
    jr nz, .next_sway

    ld a, (ix+7)            ; base_x
    ld c, a
    ld a, (sway_offset)
    add a, c
    ld c, a                 ; C = new X

    ld a, (ix+2)
    cp c
    jr z, .next_sway

    ;; Erase the complete old sprite to prevent stale pixels.
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc

    ld (ix+2), c
    ld (ix+4), c

    push bc
    call DrawEnemyIX
    pop bc

.next_sway:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .sway_loop

.check_dive_trigger:
    ;; --- 3. Dive-bombing attack trigger ---
    ld a, (attack_timer)
    inc a
    ld (attack_timer), a
    ld hl, attack_threshold
    cp (hl)                 ; Dynamic threshold based on stage and difficulty
    jp c, .update_diving

    xor a
    ld (attack_timer), a

    ;; Check if Boss Galaga should initiate tractor beam
    call CheckTractorTrigger
    jp c, .update_diving

    ;; Advance attack cycle (0=Bee/Transform, 1=Butterfly, 2=Boss, 3=Bee/Transform)
    ld a, (attack_cycle)
    inc a
    and 3
    ld (attack_cycle), a

    cp 1
    jr z, .try_butterfly_attack
    cp 2
    jr z, .try_boss_attack

.try_bee_attack:
    ;; Check if stage >= 4 for Transform Trio
    ld a, (current_stage)
    cp 4
    jr c, .regular_bee_dive

    ;; Check if another transform is currently active
    call CheckAnyTransformActive
    jr nz, .regular_bee_dive

    ;; Increment transform trigger counter
    ld a, (transform_trigger_cnt)
    inc a
    ld (transform_trigger_cnt), a
    cp 2
    jr c, .regular_bee_dive

    ;; Check if at least 3 bees in formation
    call CountBeesInFormation
    cp 3
    jr c, .regular_bee_dive

    ;; *** START TRANSFORM TRIO! ***
    xor a
    ld (transform_trigger_cnt), a
    call StartTransformTrio
    jp .update_diving

.regular_bee_dive:
    ;; Pick an alive Bee in formation (Type 0, State 0)
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_bee_diver:
    ld a, (ix+0)
    or a
    jr z, .next_bee_cand
    ld a, (ix+8)
    or a
    jr nz, .next_bee_cand
    ld a, (ix+1)            ; type == 0?
    or a
    jp z, .start_dive
.next_bee_cand:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_bee_diver
    jr .find_any_diver      ; Fallback if no bees in formation

.try_butterfly_attack:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_bf_diver:
    ld a, (ix+0)
    or a
    jr z, .next_bf_cand
    ld a, (ix+8)
    or a
    jr nz, .next_bf_cand
    ld a, (ix+1)            ; type == 1?
    cp 1
    jp z, .start_dive
.next_bf_cand:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_bf_diver
    jr .find_any_diver      ; Fallback if no butterflies in formation

.try_boss_attack:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_boss_diver:
    ld a, (ix+0)
    or a
    jr z, .next_boss_cand
    ld a, (ix+8)
    or a
    jr nz, .next_boss_cand
    ld a, (ix+1)            ; type == 2?
    cp 2
    jp z, .start_dive
.next_boss_cand:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_boss_diver
    ;; Fall through to .find_any_diver

.find_any_diver:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_any_loop:
    ld a, (ix+0)
    or a
    jr z, .next_any_cand
    ld a, (ix+8)
    or a
    jr z, .start_dive
.next_any_cand:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_any_loop
    jp .update_diving

.start_dive:
    ld (ix+8), 1            ; state = 1 (diving)
    call PlaySoundDive

    ;; Check if enemy is Boss Galaga (Type 2)
    ld a, (ix+1)
    cp 2
    jr nz, .update_diving

    ;; Boss Galaga dive: find up to 2 Goeis in formation to escort!
    ld (ix+11), 0           ; default 0 escorts
    push ix
    ld iy, enemy_data
    ld c, ENEMY_COUNT
    ld d, 0                 ; escort count
.find_escort:
    ld a, (iy+0)            ; alive?
    or a
    jr z, .next_esc_cand
    ld a, (iy+8)            ; in formation (state 0)?
    or a
    jr nz, .next_esc_cand
    ld a, (iy+1)            ; type == 1 (Goei)?
    cp 1
    jr nz, .next_esc_cand
    ;; Found a Goei escort!
    ld (iy+8), 1            ; state = 1 (dive with boss!)
    inc d
    ld a, d
    cp 2                    ; max 2 escorts
    jr z, .escorts_done
.next_esc_cand:
    ld de, ENEMY_SIZE
    add iy, de
    dec c
    jr nz, .find_escort
.escorts_done:
    pop ix
    ld (ix+11), d           ; store escort count in Boss Galaga

.update_diving:
    ;; --- 4. Move diving enemies ---
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.dive_loop:
    ld a, (ix+0)
    or a
    jp z, .next_dive_slot
    ld a, (ix+8)
    or a
    jp z, .next_dive_slot   ; In formation: already handled

    ;; Check dive state: 1 = Diving, 2 = Returning, >=3 = Tractor states
    cp 1
    jr z, .is_diving_movement
    cp 2
    jp z, .handle_returning
    jp .next_dive_slot      ; Tractor states handled in UpdateTractorState

.is_diving_movement:
    ;; --- State 1: DIVING ---

    ;; 1. Erase old sprite
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc

    ;; 2. Move Y down by 2 scanlines
    ld a, (ix+3)
    add a, 2
    cp 228
    jr nc, .loop_to_top     ; Reached bottom -> loop to top


    ld (ix+3), a

    ;; 3. Steer X toward player_x with boundary clamping (PLAY_X_MIN <= X <= PLAY_X_MAX)
    ld a, (player_x)
    ld c, (ix+2)
    cp c
    jr z, .dive_x_done
    jr c, .dive_steer_left
    inc c                   ; move right
    ld a, c
    cp PLAY_X_MAX + 1
    jr c, .dive_store_x
    ld c, PLAY_X_MAX
    jr .dive_store_x
.dive_steer_left:
    dec c                   ; move left
    ld a, c
    cp PLAY_X_MIN
    jr nc, .dive_store_x
    ld c, PLAY_X_MIN
.dive_store_x:
    ld (ix+2), c
.dive_x_done:

    ;; 4. Drop bullet at Y == 110 or Y == 150
    ld a, (ix+3)
    cp 110
    jr z, .dive_drop_bomb
    cp 150
    jr nz, .dive_skip_drop
.dive_drop_bomb:
    ld a, (enemy_fire_freeze)
    or a
    jr nz, .dive_skip_drop  ; Freeze active: cannot fire!
    push bc
    push ix
    ld b, (ix+2)
    ld c, (ix+3)
    call SpawnEBullet
    pop ix
    pop bc
.dive_skip_drop:

    ;; 5. Update old coordinates and draw at new position
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a

    push bc
    call DrawEnemyIX
    pop bc
    jp .next_dive_slot

.loop_to_top:
    ;; If transform enemy escapes off bottom, group bonus is forfeit!
    ld a, (ix+1)
    cp 6
    jr c, .no_tr_escape
    xor a
    ld (transform_killed), a
.no_tr_escape:

    ;; Wrap around to top safely below HUD (scanline 36, HUD ends at 31)
    ld a, 36
    ld (ix+3), a
    ld (ix+5), a            ; old_y = 36
    ld a, (ix+2)
    ld (ix+4), a            ; old_x = x
    ld (ix+8), 2            ; state = 2 (returning)

    push bc
    call DrawEnemyIX
    pop bc
    jp .next_dive_slot

.handle_returning:
    ;; --- State 2: RETURNING TO FORMATION ---
    ;; 1. Erase old sprite
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc

    ;; 2. Steer X toward target X (base_x + sway_offset)
    ld a, (ix+7)            ; base_x
    ld hl, sway_offset
    add a, (hl)
    ld c, a                 ; target X

    ld a, (ix+2)            ; current X
    cp c
    jr z, .ret_chk_y
    jr c, .ret_inc_x
    dec a                   ; X > target X: move left
    cp PLAY_X_MIN
    jr nc, .ret_x_ok
    ld a, PLAY_X_MIN
.ret_x_ok:
    ld (ix+2), a
    jr .ret_chk_y
.ret_inc_x:
    inc a                   ; X < target X: move right
    cp PLAY_X_MAX + 1
    jr c, .ret_x_ok2
    ld a, PLAY_X_MAX
.ret_x_ok2:
    ld (ix+2), a

.ret_chk_y:
    ;; 3. Steer Y toward base_y (stepping by 1 prevents overshoot)
    ld a, (ix+10)           ; base_y (target Y)
    ld c, a
    ld a, (ix+3)            ; current Y
    cp c
    jr z, .ret_at_target_y
    jr c, .ret_inc_y
    dec a                   ; Y > base_y: move up
    cp 36
    jr nc, .ret_y_ok
    ld a, 36
.ret_y_ok:
    ld (ix+3), a
    jr .ret_draw
.ret_inc_y:
    inc a                   ; Y < base_y: move down by 1
    ld (ix+3), a
    jr .ret_draw

.ret_at_target_y:
    ;; Y has reached base_y! Check if X also reached target X
    ld a, (ix+7)            ; base_x
    ld hl, sway_offset
    add a, (hl)
    ld c, a                 ; target X
    ld a, (ix+2)
    cp c
    jr nz, .ret_draw        ; X not aligned yet

    ;; Both X and Y arrived at formation slot!
    ld (ix+8), 0            ; state = 0 (in formation!)
    ld a, c
    ld (ix+2), a            ; snap to exact target X
    ld a, (ix+10)
    ld (ix+3), a            ; snap to exact base_y

    ;; If transform enemy (type >= 6), revert to Bee (type 0)
    ld a, (ix+1)
    cp 6
    jr c, .ret_draw
    ld (ix+1), 0
    xor a
    ld (transform_killed), a

.ret_draw:
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a

    push bc
    call DrawEnemyIX
    pop bc

.next_dive_slot:
    ld de, ENEMY_SIZE
    add ix, de
    dec b
    jp nz, .dive_loop

    call UpdateTractorState
    call UpdateCapturedFighter
    ret

;; ----------------------------------------------------------------------------
;; CheckAnyTransformActive: Returns NZ if any transformed enemy is alive
;; ----------------------------------------------------------------------------
CheckAnyTransformActive:
    ld iy, enemy_data
    ld b, ENEMY_COUNT
.chk_tr_loop:
    ld a, (iy+0)            ; alive?
    or a
    jr z, .chk_tr_next
    ld a, (iy+1)            ; type >= 6?
    cp 6
    jr c, .chk_tr_next
    ld a, 1
    or a
    ret                     ; NZ: found active transform!
.chk_tr_next:
    ld de, ENEMY_SIZE
    add iy, de
    djnz .chk_tr_loop
    xor a                   ; Z: none active
    ret

;; ----------------------------------------------------------------------------
;; CountBeesInFormation: Returns count of alive Bees in formation in A
;; ----------------------------------------------------------------------------
CountBeesInFormation:
    ld iy, enemy_data
    ld b, ENEMY_COUNT
    ld c, 0
.cnt_b_loop:
    ld a, (iy+0)            ; alive?
    or a
    jr z, .cnt_b_next
    ld a, (iy+8)            ; in formation?
    or a
    jr nz, .cnt_b_next
    ld a, (iy+1)            ; type == 0 (Bee)?
    or a
    jr nz, .cnt_b_next
    inc c
.cnt_b_next:
    ld de, ENEMY_SIZE
    add iy, de
    djnz .cnt_b_loop
    ld a, c
    ret

;; ----------------------------------------------------------------------------
;; StartTransformTrio: 3 Bees transform into aliens and dive together in formation!
;; ----------------------------------------------------------------------------
StartTransformTrio:
    ;; Determine transform alien type based on stage:
    ;; Stage 4..6: Type 6 (Sasori) -> 1,000 pts
    ;; Stage 7..9: Type 7 (Midori Stingray) -> 2,000 pts
    ;; Stage 10+:  Type 8 (Galboss Flagship) -> 3,000 pts
    ld a, (current_stage)
    cp 7
    ld c, 6                 ; Sasori
    jr c, .got_tr_type
    cp 10
    ld c, 7                 ; Midori Stingray
    jr c, .got_tr_type
    ld c, 8                 ; Galboss Flagship
.got_tr_type:
    ;; Reset group kill counter
    xor a
    ld (transform_killed), a

    ;; Find 3 bees in formation and morph them!
    ld iy, enemy_data
    ld b, ENEMY_COUNT
    ld d, 3                 ; Need 3 bees
.find_trio_loop:
    ld a, (iy+0)
    or a
    jr z, .next_trio_cand
    ld a, (iy+8)
    or a
    jr nz, .next_trio_cand
    ld a, (iy+1)
    or a
    jr nz, .next_trio_cand

    ;; Found a bee for the trio!
    ld (iy+1), c            ; Set type to transform alien!
    ld (iy+8), 1            ; Set state = 1 (diving!)

    dec d
    jr z, .trio_found_all
.next_trio_cand:
    ld de, ENEMY_SIZE
    add iy, de
    djnz .find_trio_loop

.trio_found_all:
    call PlaySoundDive
    ret

;; ============================================================================
;; Entry Phase Logic: Dynamic 2-Phase Flow (Arcade Authentic)
;; ============================================================================

;; ----------------------------------------------------------------------------
;; CheckAndRestoreDockedEnemies:
;; Checks if the sprite footprint at (ix+4, ix+5) overlaps any docked enemy.
;; If so, redraws that docked enemy above the overlapping sprite.
;; Prevents background holes without redrawing all docked enemies every frame!
;; ----------------------------------------------------------------------------
CheckAndRestoreDockedEnemies:
    push ix
    push bc
    ld iy, enemy_data
    ld b, ENEMY_COUNT
.card_loop:
    ld a, (iy+0)            ; alive?
    or a
    jr z, .card_next
    ld a, (iy+8)            ; state == STATE_FORMATION (0)?
    or a
    jr nz, .card_next

    ;; Check horizontal overlap: |(ix+4) - (iy+2)| < 8
    ld a, (ix+4)
    sub (iy+2)
    jr nc, .dx_pos
    neg
.dx_pos:
    cp 8
    jr nc, .card_next

    ;; Check vertical overlap: |(ix+5) - (iy+3)| < 16
    ld a, (ix+5)
    sub (iy+3)
    jr nc, .dy_pos
    neg
.dy_pos:
    cp 16
    jr nc, .card_next

    ;; Overlap! Redraw this docked enemy (IY)
    push bc
    push iy
    pop ix
    ld a, (global_anim)
    ld (ix+6), a
    call DrawEnemyIX
    pop bc

.card_next:
    ld de, ENEMY_SIZE
    add iy, de
    djnz .card_loop
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; UpdateEntryPhase: Manage Entry Swarm phase of standard combat stages
;; Enemies swoop in along intricate flight curves before locking into top grid
;; ----------------------------------------------------------------------------
UpdateEntryPhase:
    ;; 1. Wing flap animation during entry
    ld a, (flap_timer)
    inc a
    ld (flap_timer), a
    cp 18
    jr c, .entry_chk_spawn
    xor a
    ld (flap_timer), a
    ld a, (global_anim)
    xor 1
    ld (global_anim), a

.entry_chk_spawn:
    ;; 2. Spawn next enemy from entry_enemy_defs
    ld a, (entry_spawn_idx)
    ld hl, stage_enemy_total
    cp (hl)
    jr nc, .entry_spawns_done

    call WaitForEntryWave
    jr c, .entry_spawns_done

    ld a, (entry_spawn_timer)
    dec a
    ld (entry_spawn_timer), a
    jr nz, .entry_spawns_done

    call SpawnEntryEnemy

.entry_spawns_done:
    ;; ------------------------------------------------------------------------
    ;; Pass 1: Erase old sprite positions of all MOVING enemies
    ;; If an erased sprite overlaps any docked enemy, restore ONLY that docked enemy!
    ;; Eliminates tearing and full-formation redraw flicker.
    ;; ------------------------------------------------------------------------
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.erase_moving_loop:
    res 6, (ix+11)           ; Clear the transient redraw marker.
    ld a, (ix+0)            ; alive?
    or a
    jr z, .next_erase_m

    ld a, (ix+8)            ; state
    cp STATE_ENTRY          ; 6 (flying)
    jr z, .do_erase_m
    cp STATE_RETURNING      ; 2 (returning)
    jr nz, .next_erase_m

.do_erase_m:
    set 6, (ix+11)           ; Track sprites drawn during this update.
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16

    ;; Restore any docked enemy that overlapped this erase rectangle
    call CheckAndRestoreDockedEnemies
    pop bc

.next_erase_m:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .erase_moving_loop

    ;; The entry erase pass is CPU-heavy; keep the music moving before redraw.
    call SoundMusicUpdate

    ;; ------------------------------------------------------------------------
    ;; Pass 2: Move and Draw all MOVING enemies at their new coordinates
    ;; ------------------------------------------------------------------------
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.entry_move_loop:
    ld a, (ix+0)            ; alive?
    or a
    jp z, .next_entry_slot

    ld a, (ix+8)            ; state
    cp STATE_ENTRY          ; 6
    jr z, .move_entry_flight
    cp STATE_RETURNING      ; 2
    jp z, .move_entry_returning
    ;; STATE_FORMATION (0): already redrawn in Pass 2!
    jp .next_entry_slot

.move_entry_flight:
    ;; Advance Y down by 2 scanlines
    ld a, (ix+3)
    add a, 2
    ld (ix+3), a

    ;; Check entry path: (ix+11)
    ld a, (ix+11)
    and #7
    or a
    jr z, .epath_0
    cp 1
    jr z, .epath_1
    cp 3
    jr z, .epath_center
    cp 4
    jr z, .epath_lower_left
    cp 5
    jr z, .epath_lower_right

    ;; Path 2: Upper-right entry (Zakos)
    ld a, (ix+3)
    cp 150
    jr nc, .switch_to_returning
    cp 120
    jr c, .entry_steer_left
    jr .entry_steer_right

.epath_1:
    ;; Path 1: Upper-left entry (Goeis & Zakos)
    ld a, (ix+3)
    cp 150
    jr nc, .switch_to_returning
    cp 120
    jr c, .entry_steer_right
    jr .entry_steer_left

.epath_0:
    ;; Path 0: Upper-right entry (Boss Galagas & Goeis)
    ld a, (ix+3)
    cp 140
    jr nc, .switch_to_returning
    cp 110
    jr c, .entry_steer_left
    jr .entry_steer_right

.epath_center:
    ld a, (ix+3)
    cp 166
    jr nc, .switch_to_returning
    cp 112
    jr c, .entry_steer_left
    cp 142
    jr c, .entry_steer_right
    jr .entry_steer_left

.epath_lower_left:
    ld a, (ix+3)
    cp 164
    jr nc, .switch_to_returning
    jr .entry_steer_right

.epath_lower_right:
    ld a, (ix+3)
    cp 164
    jr nc, .switch_to_returning
    jr .entry_steer_left

.entry_steer_left:
    ld a, (ix+2)
    dec a
    cp PLAY_X_MIN
    jr nc, .entry_store_x
    ld a, PLAY_X_MIN
    jr .entry_store_x

.entry_steer_right:
    ld a, (ix+2)
    inc a
    cp PLAY_X_MAX + 1
    jr c, .entry_store_x
    ld a, PLAY_X_MAX
    jr .entry_store_x

.switch_to_returning:
    ld (ix+8), STATE_RETURNING
    ld a, (ix+2)
    jr .entry_store_x

.entry_store_x:
    ld (ix+2), a

    ;; Selected entry enemies fire while crossing the playfield.
    bit 7, (ix+11)
    jr z, .entry_no_shot
    ld a, (enemy_fire_freeze)
    or a
    jr nz, .entry_no_shot
    ld a, (ix+3)
    cp 110
    jr z, .entry_fire
    cp 150
    jr nz, .entry_no_shot
.entry_fire:
    push bc
    push ix
    ld b, (ix+2)
    ld c, (ix+3)
    call SpawnEBullet
    pop ix
    pop bc
.entry_no_shot:
    ;; Update old coordinates and draw at new position
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a
    ld a, (global_anim)
    ld (ix+6), a
    push bc
    call DrawEnemyIX
    pop bc
    jp .next_entry_slot

.move_entry_returning:
    ;; Steer X toward base_x
    ld a, (ix+7)            ; base_x
    ld c, a
    ld a, (ix+2)            ; current X
    cp c
    jr z, .ret_e_chk_y
    jr c, .ret_e_inc_x
    dec a
    cp PLAY_X_MIN
    jr nc, .ret_e_x_ok
    ld a, PLAY_X_MIN
.ret_e_x_ok:
    ld (ix+2), a
    jr .ret_e_chk_y
.ret_e_inc_x:
    inc a
    cp PLAY_X_MAX + 1
    jr c, .ret_e_x_ok2
    ld a, PLAY_X_MAX
.ret_e_x_ok2:
    ld (ix+2), a

.ret_e_chk_y:
    ;; Steer Y toward base_y (stepping by 2 for smooth ascending speed)
    ld a, (ix+10)           ; base_y (target Y: 68, 84, 100)
    ld c, a
    ld a, (ix+3)            ; current Y (>= base_y)
    cp c
    jr z, .ret_e_at_y
    jr c, .ret_e_inc_y
    ;; Y > base_y: ascend towards top formation
    sub 2
    cp c
    jr nc, .ret_e_y_ok
    ld a, c                 ; snap to target Y if passed
.ret_e_y_ok:
    ld (ix+3), a
    jr .ret_e_draw
.ret_e_inc_y:
    ld a, (ix+11)
    and #7
    cp 6
    jr nz, .ret_e_step_y
    ld a, (ix+3)
    add a, 4
    cp c
    jr c, .ret_e_step_y_store
    ld a, c
    jr .ret_e_step_y_store
.ret_e_step_y:
    inc a
.ret_e_step_y_store:
    ld (ix+3), a
    jr .ret_e_draw

.ret_e_at_y:
    ;; Y reached base_y! Check if X also reached base_x
    ld a, (ix+7)            ; base_x
    cp (ix+2)
    jr nz, .ret_e_draw

    ;; Both X and Y reached target slot! Lock into formation grid!
    ld (ix+8), STATE_FORMATION

.ret_e_draw:
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a
    ld a, (global_anim)
    ld (ix+6), a
    push bc
    call DrawEnemyIX
    pop bc

.next_entry_slot:
    ld de, ENEMY_SIZE
    add ix, de
    dec b
    jp nz, .entry_move_loop

    ;; Moving sprites draw after docked enemies. Restore crossed formation
    ;; sprites after every mover has drawn, including enemies that just docked.
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.restore_docked_loop:
    bit 6, (ix+11)
    jr z, .next_restore_docked
    push bc
    call CheckAndRestoreDockedEnemies
    pop bc
    res 6, (ix+11)
.next_restore_docked:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .restore_docked_loop

    ;; 4. Check if Entry Phase is complete
    ld a, (entry_spawn_idx)
    ld hl, stage_enemy_total
    cp (hl)
    jr c, .entry_phase_exit ; Still spawning

    ;; Check if all alive enemies are in STATE_FORMATION (0)
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.chk_entry_done:
    ld a, (ix+0)
    or a
    jr z, .chk_next_docked
    ld a, (ix+8)
    or a
    jr nz, .entry_phase_exit ; At least one is still flying
.chk_next_docked:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .chk_entry_done

    ;; *** FORMATION GRID FORMED! TRANSITION TO ATTACK PHASE! ***
    ld a, STAGE_PHASE_ATTACK
    ld (stage_phase), a
    xor a
    ld (attack_timer), a
    ld (sway_timer), a
    ld (sway_offset), a

.entry_phase_exit:
    ;; Entry animation still runs behind heavy sprite drawing. Add one small
    ;; catch-up tick every four frames to smooth the remaining tempo dip.
    ld a, (entry_music_catchup)
    inc a
    cp 4
    jr c, .entry_music_catchup_store
    xor a
    ld (entry_music_catchup), a
    call SoundMusicUpdate
    jr .entry_music_catchup_done

.entry_music_catchup_store:
    ld (entry_music_catchup), a

.entry_music_catchup_done:
    call UpdateCapturedFighter
    ret

;; ----------------------------------------------------------------------------
;; SpawnEntryEnemy: Spawn 1 enemy for the Entry Swarm
;; ----------------------------------------------------------------------------
SpawnEntryEnemy:
    ;; 1. Point IX to enemy_data + (entry_spawn_idx * 12)
    ld a, (entry_spawn_idx)
    ld l, a
    ld h, 0                 ; HL = idx
    add hl, hl              ; * 2
    ld e, l
    ld d, h                 ; DE = idx * 2
    add hl, hl              ; * 4
    add hl, de              ; * 6
    add hl, hl              ; * 12 (16-bit safe, up to 28 * 12 = 336)
    ld de, enemy_data
    add hl, de              ; HL = enemy_data + (idx * 12)
    push hl
    pop ix                  ; IX -> enemy slot

    ;; 2. Point HL to entry_enemy_defs + (entry_spawn_idx * 7)
    ld a, (entry_spawn_idx)
    ld l, a
    ld h, 0                 ; HL = idx
    add hl, hl              ; * 2
    add hl, hl              ; * 4
    add hl, hl              ; * 8
    ld e, a
    ld d, 0                 ; DE = idx
    or a                    ; clear carry
    sbc hl, de              ; HL = idx * 7 (16-bit safe)
    ld de, entry_enemy_defs
    add hl, de              ; HL -> entry_enemy_defs + (idx * 7)

    ;; 3. Initialize enemy slot
    ld (ix+0), 1            ; alive = 1
    ld a, (hl) : inc hl     ; type
    ld (ix+1), a
    ld a, (hl) : inc hl     ; hp
    ld (ix+9), a
    ld a, (hl) : inc hl     ; base_x
    ld (ix+7), a
    ld a, (hl) : inc hl     ; base_y
    ld (ix+10), a
    ld a, (hl) : inc hl     ; start_x
    ld (ix+2), a
    ld (ix+4), a
    ld a, (hl) : inc hl     ; start_y
    ld (ix+3), a
    ld (ix+5), a
    ld a, (hl)              ; entry_path
    ld (ix+11), a
    call SelectDifficultyEntryPath
    ld (ix+11), a
    push hl
    ld a, (entry_spawn_idx)
    ld l, a
    ld h, 0
    ld de, entry_shooter_flags
    add hl, de
    ld a, (hl)
    or a
    jr z, .entry_not_shooter
    set 7, (ix+11)
.entry_not_shooter:
    pop hl

    ld a, (global_anim)
    ld (ix+6), a            ; anim_frame
    ld (ix+8), STATE_ENTRY  ; state = 6
    ld a, (ix+11)
    and #7
    cp 6
    jr nz, .entry_state_ready
    ld (ix+8), STATE_RETURNING
.entry_state_ready:

    ;; Draw initial sprite
    call DrawEnemyIX

    ;; Advance spawn index
    ld a, (entry_spawn_idx)
    inc a
    ld (entry_spawn_idx), a

    ;; Check if starting a new entry attack wave (0, 4, 10, 16, or 22)
    dec a
    or a
    jr z, .check_entry_wave_sfx
    cp 4
    jr z, .check_entry_wave_sfx
    cp 10
    jr z, .check_entry_wave_sfx
    cp 16
    jr z, .check_entry_wave_sfx
    cp 22
    jr nz, .done_entry_wave_sfx
.check_entry_wave_sfx:
    ld a, (music_playing)
    or a
    jr nz, .done_entry_wave_sfx
    call PlaySoundDive
.done_entry_wave_sfx:

    ;; Set delay to next spawn
    ld a, (entry_spawn_idx)
    cp 4
    jr z, .pause_wave
    cp 10
    jr z, .pause_wave
    cp 16
    jr z, .pause_wave
    cp 22
    jr z, .pause_wave
    ld a, 8                 ; Keep entry rendering bounded on every difficulty.
    ld (entry_spawn_timer), a
    ret

.pause_wave:
    ld a, 22                ; Pause before the next group can enter.
    ld (entry_spawn_timer), a
    ret

;; At each entry-group boundary, hold the next group until the current group
;; has docked or been destroyed. Carry is set while any member is still flying.
WaitForEntryWave:
    ld a, (entry_spawn_idx)
    cp 4
    jr z, .first_wave
    cp 10
    jr z, .second_wave
    cp 16
    jr z, .third_wave
    cp 22
    jr z, .fourth_wave
    or a
    ret

.first_wave:
    ld ix, enemy_data
    ld b, 4
    jr .check_wave
.second_wave:
    ld ix, enemy_data + (4 * ENEMY_SIZE)
    ld b, 6
    jr .check_wave
.third_wave:
    ld ix, enemy_data + (10 * ENEMY_SIZE)
    ld b, 6
    jr .check_wave
.fourth_wave:
    ld ix, enemy_data + (16 * ENEMY_SIZE)
    ld b, 6
.check_wave:
    ld a, (ix+0)
    or a
    jr z, .next_wave_enemy
    ld a, (ix+8)
    or a
    jr nz, .wave_still_flying
.next_wave_enemy:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .check_wave
    or a
    ret
.wave_still_flying:
    scf
    ret

;; Higher settings mix quick top, center, and lower-side approaches.
;; A = table path; IX points to the enemy being initialized.
SelectDifficultyEntryPath:
    ld (ix+11), a
    ld a, (difficulty_level)
    or a
    jr nz, .check_top_entry
    ld a, (ix+11)
    ret

.check_top_entry:
    ld a, (entry_spawn_idx)
    cp 4
    jr c, .first_wave_index
    cp 10
    jr c, .second_wave_index
    cp 16
    jr c, .third_wave_index
    cp 22
    jr c, .fourth_wave_index
    sub 22
    jr .entry_wave_index_ready
.first_wave_index:
    or a
    jr .entry_wave_index_ready
.second_wave_index:
    sub 4
    jr .entry_wave_index_ready
.third_wave_index:
    sub 10
    jr .entry_wave_index_ready
.fourth_wave_index:
    sub 16
.entry_wave_index_ready:
    ld c, a
    ld a, (difficulty_level)
    cp 1
    jr z, .medium_top_limit
    cp 2
    jr z, .hard_top_limit
    ld a, 4
    jr .check_top_limit
.hard_top_limit:
    ld a, 3
    jr .check_top_limit
.medium_top_limit:
    ld a, 1
.check_top_limit:
    ld b, a
    ld a, c
    cp b
    jr c, .use_top_route

.has_difficulty:
    ld a, (entry_spawn_idx)
    and 3
    ld b, a
    ld a, (difficulty_level)
    cp 1
    jr z, .medium
    cp 2
    jr z, .hard
    ; Hardest: cycle center, lower-left, lower-right, and center approaches.
    ld a, b
    cp 1
    jr z, .lower_left
    cp 2
    jr z, .lower_right
    jr .center
.hard:
    ld a, b
    or a
    jr z, .center
    cp 2
    jr nz, .keep_path
    ld a, (entry_spawn_idx)
    bit 2, a
    jr nz, .lower_right
    jr .lower_left
.medium:
    ld a, b
    or a
    jr nz, .keep_path
.center:
    ld (ix+2), 44
    ld (ix+4), 44
    ld (ix+3), 64
    ld (ix+5), 64
    ld a, 3
    ret
.lower_left:
    ld (ix+2), PLAY_X_MIN
    ld (ix+4), PLAY_X_MIN
    ld (ix+3), 92
    ld (ix+5), 92
    ld a, 4
    ret
.lower_right:
    ld (ix+2), PLAY_X_MAX
    ld (ix+4), PLAY_X_MAX
    ld (ix+3), 92
    ld (ix+5), 92
    ld a, 5
    ret
.keep_path:
    ld a, (ix+11)
    ret
.use_top_route:
    ld a, (ix+7)
    ld (ix+2), a
    ld (ix+4), a
    ld (ix+3), 36
    ld (ix+5), 36
    ld a, 6
    ret

;; ----------------------------------------------------------------------------
;; Entry Phase Enemy Definitions (28 enemies: 4 Bosses, 12 Butterflies, 12 Bees)
;; Format: [type, hp, base_x, base_y, start_x, start_y, entry_path] - 7 bytes each
;; ----------------------------------------------------------------------------
entry_enemy_defs:
    ;; Wave 1: 4 Boss Galagas (Row 1, Y=52) - Swoop top-right (path 0)
    defb 2, 2, 27, 52,  66, 36, 0  ; Slot 0: Boss Galaga 1 (target 27, 52)
    defb 2, 2, 37, 52,  66, 36, 0  ; Slot 1: Boss Galaga 2 (target 37, 52)
    defb 2, 2, 47, 52,  66, 36, 0  ; Slot 2: Boss Galaga 3 (target 47, 52)
    defb 2, 2, 57, 52,  66, 36, 0  ; Slot 3: Boss Galaga 4 (target 57, 52)

    ;; Wave 2: 6 Goei Butterflies (Row 2, Y=68) - Swoop top-left (path 1)
    defb 1, 1, 17, 68,  16, 36, 1  ; Slot 4: Goei 1 (target 17, 68)
    defb 1, 1, 27, 68,  16, 36, 1  ; Slot 5: Goei 2 (target 27, 68)
    defb 1, 1, 37, 68,  16, 36, 1  ; Slot 6: Goei 3 (target 37, 68)
    defb 1, 1, 47, 68,  16, 36, 1  ; Slot 7: Goei 4 (target 47, 68)
    defb 1, 1, 57, 68,  16, 36, 1  ; Slot 8: Goei 5 (target 57, 68)
    defb 1, 1, 67, 68,  16, 36, 1  ; Slot 9: Goei 6 (target 67, 68)

    ;; Wave 3: 6 Goei Butterflies (Row 3, Y=84) - Swoop top-right (path 2)
    defb 1, 1, 17, 84,  72, 36, 2  ; Slot 10: Goei 7 (target 17, 84)
    defb 1, 1, 27, 84,  72, 36, 2  ; Slot 11: Goei 8 (target 27, 84)
    defb 1, 1, 37, 84,  72, 36, 2  ; Slot 12: Goei 9 (target 37, 84)
    defb 1, 1, 47, 84,  72, 36, 2  ; Slot 13: Goei 10 (target 47, 84)
    defb 1, 1, 57, 84,  72, 36, 2  ; Slot 14: Goei 11 (target 57, 84)
    defb 1, 1, 67, 84,  72, 36, 2  ; Slot 15: Goei 12 (target 67, 84)

    ;; Wave 4: 6 Zako Bees (Row 4, Y=100) - Swoop top-left (path 1)
    defb 0, 1, 17, 100, 16, 36, 1  ; Slot 16: Zako 1 (target 17, 100)
    defb 0, 1, 27, 100, 16, 36, 1  ; Slot 17: Zako 2 (target 27, 100)
    defb 0, 1, 37, 100, 16, 36, 1  ; Slot 18: Zako 3 (target 37, 100)
    defb 0, 1, 47, 100, 16, 36, 1  ; Slot 19: Zako 4 (target 47, 100)
    defb 0, 1, 57, 100, 16, 36, 1  ; Slot 20: Zako 5 (target 57, 100)
    defb 0, 1, 67, 100, 16, 36, 1  ; Slot 21: Zako 6 (target 67, 100)

    ;; Wave 5: 6 Zako Bees (Row 5, Y=116) - Swoop top-right (path 0)
    defb 0, 1, 17, 116, 66, 36, 0  ; Slot 22: Zako 7 (target 17, 116)
    defb 0, 1, 27, 116, 66, 36, 0  ; Slot 23: Zako 8 (target 27, 116)
    defb 0, 1, 37, 116, 66, 36, 0  ; Slot 24: Zako 9 (target 37, 116)
    defb 0, 1, 47, 116, 66, 36, 0  ; Slot 25: Zako 10 (target 47, 116)
    defb 0, 1, 57, 116, 66, 36, 0  ; Slot 26: Zako 11 (target 57, 116)
    defb 0, 1, 67, 116, 66, 36, 0  ; Slot 27: Zako 12 (target 67, 116)
