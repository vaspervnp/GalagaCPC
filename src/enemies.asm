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
    cp 6
    ret c
    cp 12
    jr c, .one_shooter
    cp 18
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

    ;; Enemy sprites must remain inside the playfield's vertical range.
    ld a, (ix+3)
    cp PF_Y_TOP
    ret c
    cp SPRITE_Y_LIMIT
    ret nc

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
    ;; Keep the opaque beam in place while active; the end-of-frame draw
    ;; replaces the whole beam image. Erase and restore its background once
    ;; it has been switched off.
    ld a, (tractor_beam_active)
    cp 1
    jr z, .keep_tractor_beam
    cp 2
    jr z, .keep_tractor_beam
    call EraseTractorBeam
.keep_tractor_beam:

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
    jr nz, .attack_phase
    call UpdateEntryPhase
    jp .check_dive_trigger

.attack_phase:
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

    ld (ix+2), c
    call EraseEnemyDeltaIX
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
    ;; No new attacks while there is no fighter on screen.
    call IsPlayerAbsent
    jp nz, .update_diving

    ld a, (attack_timer)
    inc a
    ld (attack_timer), a
    ld hl, attack_threshold
    cp (hl)                 ; Dynamic threshold based on stage and difficulty
    jp c, .update_diving

    xor a
    ld (attack_timer), a

    ;; Existing formation enemies can attack while later entry groups arrive.
    ;; Chance per attack interval rises with difficulty: 1/8, 2/8, 4/8, 6/8.
    ld a, (stage_phase)
    or a
    jr nz, .attack_interval_ready
    call ShouldAttackDuringEntry
    or a
    jp z, .update_diving

.attack_interval_ready:
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
    ld (ix+12), 0           ; Choose a fresh horizontal dive speed.
    ld (ix+13), 0
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
    ld (iy+12), 0           ; Each escort gets an independent dive speed.
    ld (iy+13), 0
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
    ;; Shared 0..2 phase for fractional dive speeds.
    ld a, (dive_phase)
    inc a
    cp 3
    jr c, .store_dive_phase
    xor a
.store_dive_phase:
    ld (dive_phase), a

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
    jp nz, .next_dive_slot  ; Tractor states handled in UpdateTractorState
    ;; During the entry phase UpdateEntryPhase already moves returners;
    ;; moving them here too erased and redrew them twice per frame.
    ld a, (stage_phase)
    or a
    jp nz, .handle_returning
    jp .next_dive_slot

.is_diving_movement:
    ;; --- State 1: DIVING ---
    ;; The old sprite is erased just before drawing at the new position.

    ;; Pick each diver's speed once per dive: 1/3 faster, 1/3 normal,
    ;; and 1/3 slower. Fractional steps preserve those average speeds.
    ld a, (ix+12)
    or a
    jr nz, .dive_speed_ready
    call GetRandomByte
    cp 85
    jr c, .dive_speed_fast
    cp 170
    jr c, .dive_speed_normal
    ld a, 3
    jr .store_dive_speed
.dive_speed_fast:
    ld a, 1
    jr .store_dive_speed
.dive_speed_normal:
    ld a, 2
.store_dive_speed:
    ;; Pick the lane while (ix+12) is still 0 so this diver ignores itself.
    push af
    call PickDiveLane
    ld (ix+13), a
    pop af
    ld (ix+12), a
.dive_speed_ready:
    ld d, 1
    ld a, (ix+12)
    cp 1
    jr z, .dive_speed_fast_step
    cp 3
    jr nz, .dive_speed_move
    ld a, (dive_phase)
    or a
    jr nz, .dive_speed_move
    ld d, 0                 ; Slow divers skip every third horizontal step.
    jr .dive_speed_move
.dive_speed_fast_step:
    ld a, (dive_phase)
    or a
    jr nz, .dive_speed_move
    inc d                   ; Fast divers take an extra step every third frame.
.dive_speed_move:
    ;; 2. Move Y down by 2 scanlines
    ld a, (ix+3)
    add a, 2
    cp DIVE_WRAP_Y
    jp nc, .loop_to_top     ; Reached bottom -> loop to top


    ld (ix+3), a

    ;; 3. Steer X toward the diver's aim point until DIVE_LOCK_Y, then keep
    ;; flying straight so the player can dodge it off the bottom of the screen.
    bit 7, (ix+13)
    jr nz, .dive_x_done
    cp DIVE_LOCK_Y
    jr c, .dive_check_player
    set 7, (ix+13)
    jr .dive_x_done
.dive_check_player:
    ;; Without a fighter to chase, fly straight instead of converging on
    ;; its last position.
    call IsPlayerAbsent
    jr nz, .dive_x_done
.dive_steer:
    ;; Lanes are 8 bytes apart around the player. The lane set is centred on
    ;; the player but kept inside the playfield, so lanes never merge at an
    ;; edge and one lane always lines up with the fighter.
    ld a, (player_x)
    cp PLAY_X_MIN + DIVE_LANE_SPAN
    jr nc, .lane_center_min_ok
    ld a, PLAY_X_MIN + DIVE_LANE_SPAN
.lane_center_min_ok:
    cp PLAY_X_MAX - DIVE_LANE_SPAN + 1
    jr c, .lane_center_ok
    ld a, PLAY_X_MAX - DIVE_LANE_SPAN
.lane_center_ok:
    sub DIVE_LANE_SPAN
    ld e, a                 ; E = X of lane 0
    ld a, (ix+13)
    and 7
    add a, a
    add a, a
    add a, a                ; A = lane * 8
    add a, e                ; A = target X
    ld c, (ix+2)
    cp c
    jr z, .dive_x_done
    jr c, .dive_steer_left
    ld a, c
    add a, d                ; Faster divers may overshoot the player's X.
    ld c, a
    ld a, c
    cp PLAY_X_MAX + 1
    jr c, .dive_store_x
    ld c, PLAY_X_MAX
    jr .dive_store_x
.dive_steer_left:
    ld a, c
    sub d
    ld c, a
    ld a, c
    cp PLAY_X_MIN
    jr nc, .dive_store_x
    ld c, PLAY_X_MIN
.dive_store_x:
    ld (ix+2), c
.dive_x_done:

    ;; 4. Drop bullet at DIVE_FIRE_Y1 and DIVE_FIRE_Y2
    ld a, (ix+3)
    cp DIVE_FIRE_Y1
    jr z, .dive_drop_bomb
    cp DIVE_FIRE_Y2
    jr z, .dive_drop_bomb
    cp DIVE_FIRE_Y3
    jr nz, .dive_skip_drop
    ld a, (current_stage)
    cp DIVE_FIRE3_STAGE
    jr c, .dive_skip_drop
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

    ;; 5. Erase the uncovered strip, update old coordinates, draw
    call EraseEnemyDeltaIX
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a

    push bc
    call DrawEnemyIX
    pop bc
    jp .next_dive_slot

.loop_to_top:
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc

    ;; If transform enemy escapes off bottom, group bonus is forfeit!
    ld a, (ix+1)
    cp 6
    jr c, .no_tr_escape
    xor a
    ld (transform_killed), a
.no_tr_escape:

    ;; Wrap around to the top of the playfield
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a            ; old_y = top
    ld a, (ix+2)
    ld (ix+4), a            ; old_x = x
    ld (ix+8), 2            ; state = 2 (returning)

    push bc
    call DrawEnemyIX
    pop bc
    jp .next_dive_slot

.handle_returning:
    ;; --- State 2: RETURNING TO FORMATION ---
    ;; 1. The old sprite is erased just before drawing at the new position.

    ;; Recover an invalid Y coordinate so the enemy cannot remain outside the
    ;; playfield and hold an entry group indefinitely.
    ld a, (ix+3)
    cp PF_Y_TOP
    jr c, .recover_return_y
    cp SPRITE_Y_LIMIT
    jr c, .return_y_valid
.recover_return_y:
    ;; The position jumps, so erase the whole old sprite first.
    call EraseEnemyOldIX
    ld a, (ix+7)
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
.return_y_valid:

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
    cp PF_Y_TOP
    jr nc, .ret_y_ok
    ld a, PF_Y_TOP
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
    call EraseEnemyDeltaIX
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
;; EraseEnemyDeltaIX: Erase only the part of the old sprite (ix+4, ix+5) that
;; the new position (ix+2, ix+3) will not cover. Sprites are opaque, so the
;; following draw overwrites the overlap; blanking the whole sprite first made
;; moving enemies flicker whenever the raster caught them between the two.
;; Preserves: BC, IX, IY
;; ----------------------------------------------------------------------------
EraseEnemyDeltaIX:
    ld a, (ix+5)
    cp PF_Y_TOP
    ret c
    cp SPRITE_Y_LIMIT
    ret nc

    ;; Moved a full sprite width or height (or more): erase it all.
    ld a, (ix+2)
    sub (ix+4)
    jr nc, .dx_abs
    neg
.dx_abs:
    cp 8
    jr nc, EraseEnemyOldIX
    ld a, (ix+3)
    sub (ix+5)
    jr nc, .dy_abs
    neg
.dy_abs:
    cp 16
    jr nc, EraseEnemyOldIX

    push bc
    ;; Vertical strip
    ld a, (ix+3)
    sub (ix+5)              ; A = new_y - old_y
    jr z, .horizontal
    jr c, .moved_up
    ld e, a                 ; Moved down: clear the old top rows.
    ld d, 8
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearBitmapRect
    jr .horizontal
.moved_up:
    neg
    ld e, a                 ; Moved up: clear the old bottom rows.
    ld d, 8
    ld b, (ix+4)
    ld a, (ix+3)
    add a, 16
    ld c, a
    call ClearBitmapRect

.horizontal:
    ld a, (ix+2)
    sub (ix+4)              ; A = new_x - old_x
    jr z, .done
    jr c, .moved_left
    ld d, a                 ; Moved right: clear the old left columns.
    ld e, 16
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearBitmapRect
    jr .done
.moved_left:
    neg
    ld d, a                 ; Moved left: clear the old right columns.
    ld e, 16
    ld a, (ix+2)
    add a, 8
    ld b, a
    ld c, (ix+5)
    call ClearBitmapRect
.done:
    pop bc
    ret

;; EraseEnemyOldIX: Erase the whole sprite at (ix+4, ix+5) if inside the playfield.
;; Preserves: BC, IX, IY
EraseEnemyOldIX:
    ld a, (ix+5)
    cp PF_Y_TOP
    ret c
    cp SPRITE_Y_LIMIT
    ret nc
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc
    ret

;; ----------------------------------------------------------------------------
;; PickDiveLane: Choose a dive lane (0..DIVE_LANES-1) that no other diver is
;; using, starting from a random lane. Divers with (ix+12) = 0 have not picked
;; a lane yet and are ignored, including the caller.
;; Output: A = lane
;; Preserves: BC, IX
;; ----------------------------------------------------------------------------
PickDiveLane:
    push bc
    push iy
    ;; C = bit mask of lanes in use
    ld c, 0
    ld iy, enemy_data
    ld b, ENEMY_COUNT
.scan:
    ld a, (iy+0)
    or a
    jr z, .scan_next
    ld a, (iy+8)
    cp STATE_DIVING
    jr nz, .scan_next
    ld a, (iy+12)
    or a
    jr z, .scan_next
    ld a, (iy+13)
    and 7
    call LaneBit
    or c
    ld c, a
.scan_next:
    ld de, ENEMY_SIZE
    add iy, de
    djnz .scan

    ;; Random start lane; the spare value 7 maps to the centre lane.
    call GetRandomByte
    and 7
    cp DIVE_LANES
    jr c, .start_ok
    ld a, DIVE_LANES / 2
.start_ok:
    ld h, a                 ; H = candidate lane
    ld l, DIVE_LANES        ; L = lanes left to try
.try:
    ld a, h
    call LaneBit
    and c
    jr z, .found
    ld a, h
    inc a
    cp DIVE_LANES
    jr c, .wrap_ok
    xor a
.wrap_ok:
    ld h, a
    dec l
    jr nz, .try
    ;; All lanes busy: reuse the random lane.
.found:
    ld a, h
    pop iy
    pop bc
    ret

;; LaneBit: A = 1 << A (A = 0..7). Preserves all other registers.
LaneBit:
    push bc
    ld b, a
    inc b
    ld a, 1
.shift:
    dec b
    jr z, .done
    add a, a
    jr .shift
.done:
    pop bc
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
    ld (iy+12), 0
    ld (iy+13), 0

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
;; Preserves: BC, IX, IY
;; ----------------------------------------------------------------------------
CheckAndRestoreDockedEnemies:
    ld a, (ix+5)
    cp FORMATION_Y_MAX + 16
    ret nc                  ; Below every formation row: nothing to restore
    ld (.old_y + 1), a
    push bc
    ld a, (ix+4)
    ld (.old_x + 1), a

    ;; Docked enemies sit on fixed rows 16 lines apart (slot -> row), so
    ;; only the row at or above the footprint and the one below can overlap.
    ld a, (.old_y + 1)
    sub FORMATION_Y_MIN
    jr nc, .row_index
    xor a
.row_index:
    rrca
    rrca
    rrca
    rrca
    and #0F
    ld c, a                 ; C = first candidate row (0..4)
    call .check_row
    ld a, c
    inc a
    cp FORMATION_ROWS
    call c, .check_row
    pop bc
    ret

;; A = formation row: test that row's slots. Preserves C.
.check_row:
    ld l, a
    add a, a
    add a, l
    ld l, a
    ld h, 0
    ld de, formation_row_tab
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    inc hl
    ld b, (hl)              ; B = slots in the row
    ex de, hl               ; HL = first slot
.card_loop:
    ld a, (hl)              ; alive?
    or a
    jr z, .card_next
    push hl

    ;; Vertical overlap: |y - old_y| < 16
    inc hl
    inc hl
    inc hl
    ld a, (hl)
.old_y:
    sub 0
    add a, 15
    cp 31
    jr nc, .card_skip

    ;; Horizontal overlap: |x - old_x| < 8
    dec hl
    ld a, (hl)
.old_x:
    sub 0
    add a, 7
    cp 15
    jr nc, .card_skip

    ;; Only enemies docked in formation (state 0)
    ld de, 6
    add hl, de
    ld a, (hl)
    or a
    jr nz, .card_skip

    ;; Overlap! Redraw this docked enemy
    pop hl
    push hl
    push ix
    push hl
    pop ix
    ld a, (global_anim)
    ld (ix+6), a
    push bc
    call DrawEnemyIX
    pop bc
    pop ix
.card_skip:
    pop hl
.card_next:
    ld de, ENEMY_SIZE
    add hl, de
    djnz .card_loop
    ret

;; Formation rows: first slot, slot count (see entry_enemy_defs)
formation_row_tab:
    defw enemy_data : defb 4
    defw enemy_data + 4 * ENEMY_SIZE : defb 6
    defw enemy_data + 10 * ENEMY_SIZE : defb 6
    defw enemy_data + 16 * ENEMY_SIZE : defb 6
    defw enemy_data + 22 * ENEMY_SIZE : defb 6

;; EraseEntryEnemyOld: Delta-erase a moving entry enemy, then restore any
;; docked enemy that the old sprite overlapped.
;; Preserves: BC, IX
EraseEntryEnemyOld:
    call EraseEnemyDeltaIX
    ld a, (ix+5)
    cp PF_Y_TOP
    ret c
    cp SPRITE_Y_LIMIT
    ret nc
    jp CheckAndRestoreDockedEnemies

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
    ;; Pass 1: Move and draw all MOVING enemies. Each is erased right before
    ;; it is redrawn, so it is never left blank while the raster passes, and
    ;; is marked (bit 6 of +11) for the docked-enemy restore in pass 2.
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
    jp nz, .next_entry_slot ; STATE_FORMATION (0): docked, not redrawn
    set 6, (ix+11)
    jp .move_entry_returning

.move_entry_flight:
    set 6, (ix+11)
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
    cp 150 + PF_OLD_DY
    jr nc, .switch_to_returning
    cp 120 + PF_OLD_DY
    jr c, .entry_steer_left
    jr .entry_steer_right

.epath_1:
    ;; Path 1: Upper-left entry (Goeis & Zakos)
    ld a, (ix+3)
    cp 150 + PF_OLD_DY
    jr nc, .switch_to_returning
    cp 120 + PF_OLD_DY
    jr c, .entry_steer_right
    jr .entry_steer_left

.epath_0:
    ;; Path 0: Upper-right entry (Boss Galagas & Goeis)
    ld a, (ix+3)
    cp 140 + PF_OLD_DY
    jr nc, .switch_to_returning
    cp 110 + PF_OLD_DY
    jr c, .entry_steer_left
    jr .entry_steer_right

.epath_center:
    ld a, (ix+3)
    cp 166 + PF_OLD_DY
    jr nc, .switch_to_returning
    cp 112 + PF_OLD_DY
    jr c, .entry_steer_left
    cp 142 + PF_OLD_DY
    jr c, .entry_steer_right
    jr .entry_steer_left

.epath_lower_left:
    ld a, (ix+3)
    cp 164 + PF_OLD_DY
    jr nc, .switch_to_returning
    jr .entry_steer_right

.epath_lower_right:
    ld a, (ix+3)
    cp 164 + PF_OLD_DY
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
    cp 110 + PF_OLD_DY
    jr z, .entry_fire
    cp 150 + PF_OLD_DY
    jr z, .entry_fire
    cp 90 + PF_OLD_DY
    jr z, .entry_extra_fire_check
    cp 130 + PF_OLD_DY
    jr nz, .entry_no_shot
.entry_extra_fire_check:
    push bc
    call GetRandomByte
    ld b, a
    ld a, (difficulty_level)
    or a
    ld a, 26                 ; Easy: ~10% chance at each extra firing point.
    jr z, .entry_fire_chance_ready
    ld a, (difficulty_level)
    cp 1
    ld a, 52                 ; Medium: ~20%.
    jr z, .entry_fire_chance_ready
    cp 2
    ld a, 90                 ; Hard: ~35%.
    jr z, .entry_fire_chance_ready
    ld a, 128                ; Hardest: ~50%.
.entry_fire_chance_ready:
    cp b
    jr c, .entry_extra_fire_skip
    jr z, .entry_extra_fire_skip
    pop bc
    jr .entry_fire
.entry_extra_fire_skip:
    pop bc
    jr .entry_no_shot
.entry_fire:
    push bc
    push ix
    ld b, (ix+2)
    ld c, (ix+3)
    call SpawnEBullet
    pop ix
    pop bc
.entry_no_shot:
    ;; Erase the uncovered strip, update old coordinates, draw at new position
    call EraseEntryEnemyOld
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
    ;; Recover invalid vertical positions.
    ld a, (ix+3)
    cp PF_Y_TOP
    jr c, .entry_recover_return_y
    cp SPRITE_Y_LIMIT
    jr c, .entry_return_y_valid
.entry_recover_return_y:
    call EraseEnemyOldIX     ; The position jumps: erase the whole old sprite.
    ld a, (ix+7)
    ld (ix+2), a
    ld (ix+4), a
    ld a, PF_Y_TOP
    ld (ix+3), a
    ld (ix+5), a
.entry_return_y_valid:
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
    ld a, (ix+3)            ; A held the path number here, not Y.
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
    call EraseEntryEnemyOld
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

    ;; Pass 2: Moving sprites draw after docked enemies. Restore crossed
    ;; formation sprites after every mover has drawn, including enemies that
    ;; just docked. C counts alive enemies not yet in formation.
    ld ix, enemy_data
    ld bc, ENEMY_COUNT << 8
.restore_docked_loop:
    ld a, (ix+0)
    or a
    jr z, .next_restore_docked
    ld a, (ix+8)
    or a
    jr z, .restore_docked_check
    inc c
.restore_docked_check:
    bit 6, (ix+11)
    jr z, .next_restore_docked
    res 6, (ix+11)
    push bc
    call CheckAndRestoreDockedEnemies
    pop bc
.next_restore_docked:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .restore_docked_loop

    ;; 4. The entry phase ends when every enemy has spawned and docked
    ld a, c
    or a
    jr nz, .entry_phase_exit ; At least one is still flying
    ld a, (entry_spawn_idx)
    ld hl, stage_enemy_total
    cp (hl)
    jr c, .entry_phase_exit ; Still spawning

    ;; *** FORMATION GRID FORMED! TRANSITION TO ATTACK PHASE! ***
    ld a, STAGE_PHASE_ATTACK
    ld (stage_phase), a
    xor a
    ld (attack_timer), a
    ld (sway_timer), a
    ld (sway_offset), a

.entry_phase_exit:
    ret

;; Returns A=nonzero when an early attack is allowed at this interval.
ShouldAttackDuringEntry:
    call GetRandomByte
    and 7
    ld b, a
    ld a, (difficulty_level)
    or a
    ld a, 1
    jr z, .check_roll
    ld a, (difficulty_level)
    cp 1
    ld a, 2
    jr z, .check_roll
    cp 2
    ld a, 4
    jr z, .check_roll
    ld a, 6
.check_roll:
    cp b
    jr c, .attack_not_allowed
    jr z, .attack_not_allowed
    ld a, 1
    ret
.attack_not_allowed:
    xor a
    ret

;; ----------------------------------------------------------------------------
;; SpawnEntryEnemy: Spawn 1 enemy for the Entry Swarm
;; ----------------------------------------------------------------------------
SpawnEntryEnemy:
    ;; 1. Point IX to enemy_data + (entry_spawn_idx * ENEMY_SIZE)
    ld a, (entry_spawn_idx)
    ld l, a
    ld h, 0                 ; HL = idx
    add hl, hl              ; * 2
    ld d, h
    ld e, l                 ; DE = idx * 2
    add hl, hl              ; * 4
    add hl, hl              ; * 8
    add hl, hl              ; * 16
    or a
    sbc hl, de              ; * 14 (16-bit safe, up to 27 * 14 = 378)
    ld de, enemy_data
    add hl, de              ; HL = enemy_data + (idx * ENEMY_SIZE)
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
    ld (ix+2), 44 + PF_OLD_DX
    ld (ix+4), 44 + PF_OLD_DX
    ld (ix+3), 64 + PF_OLD_DY
    ld (ix+5), 64 + PF_OLD_DY
    ld a, 3
    ret
.lower_left:
    ld (ix+2), PLAY_X_MIN
    ld (ix+4), PLAY_X_MIN
    ld (ix+3), 92 + PF_OLD_DY
    ld (ix+5), 92 + PF_OLD_DY
    ld a, 4
    ret
.lower_right:
    ld (ix+2), PLAY_X_MAX
    ld (ix+4), PLAY_X_MAX
    ld (ix+3), 92 + PF_OLD_DY
    ld (ix+5), 92 + PF_OLD_DY
    ld a, 5
    ret
.keep_path:
    ld a, (ix+11)
    ret
.use_top_route:
    ld a, (ix+7)
    ld (ix+2), a
    ld (ix+4), a
    ld (ix+3), PF_Y_TOP
    ld (ix+5), PF_Y_TOP
    ld a, 6
    ret

;; ----------------------------------------------------------------------------
;; Entry Phase Enemy Definitions (28 enemies: 4 Bosses, 12 Butterflies, 12 Bees)
;; Format: [type, hp, base_x, base_y, start_x, start_y, entry_path] - 7 bytes each
;; ----------------------------------------------------------------------------
entry_enemy_defs:
    ;; Positions are written in the pre-column layout (comments too) and moved
    ;; into the current playfield by PF_OLD_DX / PF_OLD_DY.
    ;; Wave 1: 4 Boss Galagas (Row 1, Y=52) - Swoop top-right (path 0)
    defb 2, 2, 27 + PF_OLD_DX, 52 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 0: Boss Galaga 1 (target 27, 52)
    defb 2, 2, 37 + PF_OLD_DX, 52 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 1: Boss Galaga 2 (target 37, 52)
    defb 2, 2, 47 + PF_OLD_DX, 52 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 2: Boss Galaga 3 (target 47, 52)
    defb 2, 2, 57 + PF_OLD_DX, 52 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 3: Boss Galaga 4 (target 57, 52)

    ;; Wave 2: 6 Goei Butterflies (Row 2, Y=68) - Swoop top-left (path 1)
    defb 1, 1, 17 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 4: Goei 1 (target 17, 68)
    defb 1, 1, 27 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 5: Goei 2 (target 27, 68)
    defb 1, 1, 37 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 6: Goei 3 (target 37, 68)
    defb 1, 1, 47 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 7: Goei 4 (target 47, 68)
    defb 1, 1, 57 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 8: Goei 5 (target 57, 68)
    defb 1, 1, 67 + PF_OLD_DX, 68 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 9: Goei 6 (target 67, 68)

    ;; Wave 3: 6 Goei Butterflies (Row 3, Y=84) - Swoop top-right (path 2)
    defb 1, 1, 17 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 10: Goei 7 (target 17, 84)
    defb 1, 1, 27 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 11: Goei 8 (target 27, 84)
    defb 1, 1, 37 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 12: Goei 9 (target 37, 84)
    defb 1, 1, 47 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 13: Goei 10 (target 47, 84)
    defb 1, 1, 57 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 14: Goei 11 (target 57, 84)
    defb 1, 1, 67 + PF_OLD_DX, 84 + PF_OLD_DY, 72 + PF_OLD_DX, 36 + PF_OLD_DY, 2  ; Slot 15: Goei 12 (target 67, 84)

    ;; Wave 4: 6 Zako Bees (Row 4, Y=100) - Swoop top-left (path 1)
    defb 0, 1, 17 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 16: Zako 1 (target 17, 100)
    defb 0, 1, 27 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 17: Zako 2 (target 27, 100)
    defb 0, 1, 37 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 18: Zako 3 (target 37, 100)
    defb 0, 1, 47 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 19: Zako 4 (target 47, 100)
    defb 0, 1, 57 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 20: Zako 5 (target 57, 100)
    defb 0, 1, 67 + PF_OLD_DX, 100 + PF_OLD_DY, 16 + PF_OLD_DX, 36 + PF_OLD_DY, 1  ; Slot 21: Zako 6 (target 67, 100)

    ;; Wave 5: 6 Zako Bees (Row 5, Y=116) - Swoop top-right (path 0)
    defb 0, 1, 17 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 22: Zako 7 (target 17, 116)
    defb 0, 1, 27 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 23: Zako 8 (target 27, 116)
    defb 0, 1, 37 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 24: Zako 9 (target 37, 116)
    defb 0, 1, 47 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 25: Zako 10 (target 47, 116)
    defb 0, 1, 57 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 26: Zako 11 (target 57, 116)
    defb 0, 1, 67 + PF_OLD_DX, 116 + PF_OLD_DY, 66 + PF_OLD_DX, 36 + PF_OLD_DY, 0  ; Slot 27: Zako 12 (target 67, 116)
