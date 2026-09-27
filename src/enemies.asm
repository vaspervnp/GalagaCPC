;; ============================================================================
;; Galaga CPC - Enemies Logic & Formation Management
;; ============================================================================

InitEnemies:
    xor a
    ld (sway_offset), a
    ld (attack_timer), a

    ld ix, enemy_data
    ld b, ENEMY_COUNT
    ld hl, initial_enemies
.init_loop:
    ld a, (hl)              ; alive
    ld (ix+0), a
    inc hl
    ld a, (hl)              ; type (0=Bee, 1=Butterfly, 2=Boss)
    ld (ix+1), a
    inc hl
    ld a, (hl)              ; x
    ld (ix+2), a
    ld (ix+4), a            ; old_x
    ld (ix+7), a            ; base_x
    inc hl
    ld a, (hl)              ; y
    ld (ix+3), a
    ld (ix+5), a            ; old_y
    ld (ix+10), a           ; base_y
    inc hl
    ld a, (hl)              ; hp
    ld (ix+9), a
    inc hl
    ld (ix+6), 0            ; anim_frame = 0
    ld (ix+8), 0            ; state = 0 (formation)
    ld (ix+11), 0           ; pad

    push bc
    push hl
    call DrawEnemyIX
    pop hl
    pop bc

    ld de, ENEMY_SIZE
    add ix, de
    djnz .init_loop
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
    ld a, (is_challenging_stage)
    or a
    jp nz, UpdateChallengingStage

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

    ;; Erase at old position
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
    cp (hl)                 ; Dynamic threshold based on current stage
    jr c, .update_diving

    xor a
    ld (attack_timer), a

    ;; Check if Boss Galaga should initiate tractor beam
    call CheckTractorTrigger
    jr c, .update_diving

    ;; Pick first alive enemy in formation to dive
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_diver:
    ld a, (ix+0)
    or a
    jr z, .next_cand
    ld a, (ix+8)            ; in formation?
    or a
    jr z, .start_dive
.next_cand:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_diver
    jr .update_diving

.start_dive:
    ld (ix+8), 1            ; state = 1 (diving)
    call PlaySoundDive

    ;; Check transform if enemy is Type 0 (Bee)
    ld a, (ix+1)
    or a
    jr nz, .update_diving

    ;; Check stage for transform
    ld a, (current_stage)
    cp 4
    jr c, .update_diving    ; Stage 1-3: no transforms
    cp 7
    jr c, .transform_sasori ; Stage 4-6: Sasori
    cp 10
    jr c, .transform_stingray ; Stage 7-9: Midori Stingray
    ;; Stage 10+: Galboss Flagship
    ld (ix+1), 8
    jr .update_diving

.transform_sasori:
    ld (ix+1), 6
    jr .update_diving

.transform_stingray:
    ld (ix+1), 7
    jr .update_diving

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
    cp 224
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

