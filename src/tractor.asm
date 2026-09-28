;; ============================================================================
;; Galaga CPC - Tractor Beam, Fighter Capture & Dual Fighter Rescue
;; Amstrad CPC 464 / 6128
;; Reference: StrategyWiki Walkthrough - Section 1 "Double your fire power"
;; ============================================================================

;; ----------------------------------------------------------------------------
;; CheckTractorTrigger: Check if a Boss Galaga should initiate Tractor Beam
;; Called when attack_timer fires in enemies.asm
;; Output: Carry SET if tractor beam initiated, CLEAR otherwise
;; ----------------------------------------------------------------------------
CheckTractorTrigger:
    ;; Conditions:
    ;; 1. Not in Challenging Stage
    ld a, (is_challenging_stage)
    or a
    ret nz

    ;; 2. Player must be single fighter
    ld a, (is_dual_fighter)
    or a
    ret nz

    ;; 3. No fighter currently captured or being captured
    ld a, (captured_fighter_active)
    or a
    ret nz
    ld a, (tractor_beam_active)
    or a
    ret nz

    ;; 4. Check trigger counter (every 3rd attack)
    ld a, (tractor_trigger_cnt)
    inc a
    ld (tractor_trigger_cnt), a
    cp 3
    ret c

    ;; Find an alive Boss Galaga in formation
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_boss:
    ld a, (ix+0)            ; alive?
    or a
    jr z, .next_b
    ld a, (ix+1)            ; type == 2 (Boss)?
    cp 2
    jr nz, .next_b
    ld a, (ix+8)            ; in formation (state == 0)?
    or a
    jr z, .init_tractor_boss
.next_b:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_boss
    ret

.init_tractor_boss:
    xor a
    ld (tractor_trigger_cnt), a
    ld (ix+8), STATE_TRACTOR_DIVE
    ld a, (ix+2)
    ld (tractor_boss_x), a
    ld a, (ix+3)
    ld (tractor_boss_y), a
    ld (captor_boss_ptr), ix
    scf                     ; Signal tractor beam initiated
    ret

;; ----------------------------------------------------------------------------
;; UpdateTractorState: Update Tractor Beam Boss, Beam Visuals, and Capture
;; Called each frame from GameLoop
;; ----------------------------------------------------------------------------
UpdateTractorState:
    ;; Check if waiting for replacement fighter after capture
    ld a, (capture_delay)
    or a
    jr z, .no_capture_delay
    dec a
    ld (capture_delay), a
    jr nz, .no_capture_delay

    ;; Delay expired! Clear "FIGHTER CAPTURED" banner and spawn replacement fighter
    call ClearCapturedBanner
    call RespawnPlayer

.no_capture_delay:
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.find_tractor_loop:
    ld a, (ix+0)
    or a
    jr z, .next_t_slot
    ld a, (ix+8)            ; state
    cp STATE_TRACTOR_DIVE
    jr z, .handle_tractor_dive
    cp STATE_TRACTOR_BEAM
    jr z, .handle_tractor_beam
    cp STATE_CAPTURING
    jp z, .handle_capturing

.next_t_slot:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .find_tractor_loop
    ret

.handle_tractor_dive:
    ;; Boss dives straight down to Y = 142 to emit beam
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc

    ld a, (ix+3)
    add a, 2
    ld (ix+3), a
    cp 142
    jr c, .dive_down_ok

    ;; Reached hover scanline! Switch to emitting beam
    ld (ix+3), 142
    ld (ix+8), STATE_TRACTOR_BEAM
    ld a, 1
    ld (tractor_beam_active), a
    ld a, 120               ; ~2.4 seconds duration
    ld (tractor_timer), a
    ld a, (ix+2)
    ld (tractor_boss_x), a

.dive_down_ok:
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a
    push bc
    call DrawEnemyIX
    pop bc
    ret

.handle_tractor_beam:
    ;; Emitting beam while hovering at Y=142
    call PlaySoundTractor
    call DrawTractorBeam

    ;; Check if player is caught in beam
    ld a, (player_invincible_timer)
    or a
    jr nz, .beam_timer_tick     ; Immune while invincible!

    ;; Beam bottom width: (tractor_boss_x - 3) to (tractor_boss_x + 9)
    ld a, (tractor_boss_x)
    sub 3
    ld c, a
    ld a, (player_x)
    cp c
    jr c, .beam_timer_tick

    ld a, (tractor_boss_x)
    add a, 9
    ld c, a
    ld a, (player_x)
    cp c
    jr nc, .beam_timer_tick

    ;; *** PLAYER CAUGHT IN TRACTOR BEAM! ***
    ;; Cleanly erase player from ALL previous positions before centering!
    ld a, (old_player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ;; If dual fighter was active, also erase the second fighter and reset flag
    ld a, (is_dual_fighter)
    or a
    jr z, .cap_not_dual
    xor a
    ld (is_dual_fighter), a

    ld a, (old_player_x)
    add a, 8
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (player_x)
    add a, 8
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

.cap_not_dual:
    ;; Center player directly under Boss
    ld a, (tractor_boss_x)
    ld (player_x), a
    ld (old_player_x), a
    ld a, DEFAULT_PLAYER_Y
    ld (player_y), a
    ld (old_player_y), a

    ;; Draw player cleanly at new centered position
    ld a, (player_x)
    ld b, a
    ld c, DEFAULT_PLAYER_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ld (ix+8), STATE_CAPTURING
    ld a, 2
    ld (tractor_beam_active), a
    ret

.beam_timer_tick:
    ld a, (tractor_timer)
    dec a
    ld (tractor_timer), a
    ret nz

    ;; Timer expired without capture! Retract beam and resume dive
    call EraseTractorBeam
    xor a
    ld (tractor_beam_active), a
    ld (ix+8), STATE_DIVING
    ret

.handle_capturing:
    ;; 1. Erase player at current position BEFORE redrawing beam
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ;; 2. Keep tractor beam active & animated while player is ascending!
    call PlaySoundTractor
    call DrawTractorBeam

    ;; 3. Ascend player upward toward Boss by 1 scanline
    ld a, (player_y)
    dec a
    ld (player_y), a
    cp 158
    jr nc, .draw_ascending_player


    ;; *** FIGHTER DOCKED UNDER BOSS! CAPTURE COMPLETE! ***
    ;; Erase tractor beam
    call EraseTractorBeam

    ;; Erase player at scanline 158 (it is now docked with Boss as captured fighter)
    ld a, (player_x)
    ld b, a
    ld c, 158
    call ClearSprite16x16

    ;; Dock captured fighter with Boss
    ld a, 1
    ld (captured_fighter_active), a
    xor a
    ld (tractor_beam_active), a
    ld (ix+8), STATE_RETURNING

    ;; Decrease player lives with underflow prevention
    ld a, (player_lives)
    or a
    jr z, .captured_game_over
    dec a
    ld (player_lives), a
    call DrawLivesHUD

    or a
    jr z, .captured_game_over

    ;; Display "FIGHTER CAPTURED" banner in Cyan
    call DrawFighterCapturedBanner
    call PlayMusicFighterCaptured
    ld a, 150               ; ~3.0s delay for 21-step capture tune before next ship spawns
    ld (capture_delay), a
    ret

.captured_game_over:
    call ClearCapturedBanner
    ld a, 1
    ld (game_over), a
    ld a, 1
    ld (restart_debounce), a
    call DrawGameOverText
    call PlaySoundGameOver
    ret

.draw_ascending_player:
    ;; Alternate between normal sprite and red captured sprite (spinning)
    ld a, (player_y)
    and 4
    jr nz, .draw_red_spin
    ld hl, player_sprite
    jr .do_draw_asc
.draw_red_spin:
    ld hl, captured_player_sprite
.do_draw_asc:
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call DrawSprite16x16
    ret

ClearCapturedBanner:
    jp ClearFighterCapturedBanner

;; Pointer tables for the 7 16x16 tiles of each animation frame
tractor_f1_ptrs:
    defw tractor_f1_top, tractor_f1_mid_l, tractor_f1_mid_c, tractor_f1_mid_r
    defw tractor_f1_bot_l, tractor_f1_bot_c, tractor_f1_bot_r

tractor_f2_ptrs:
    defw tractor_f2_top, tractor_f2_mid_l, tractor_f2_mid_c, tractor_f2_mid_r
    defw tractor_f2_bot_l, tractor_f2_bot_c, tractor_f2_bot_r

tractor_f3_ptrs:
    defw tractor_f3_top, tractor_f3_mid_l, tractor_f3_mid_c, tractor_f3_mid_r
    defw tractor_f3_bot_l, tractor_f3_bot_c, tractor_f3_bot_r

;; ----------------------------------------------------------------------------
;; DrawTractorBeam: Render 7 authentic 16x16 tiles from galagaSpriteMap.png
;; Top tier: Y=126 (1 tile), Mid tier: Y=142 (3 tiles), Bot tier: Y=158 (3 tiles)
;; ----------------------------------------------------------------------------
DrawTractorBeam:
    ld a, (tractor_anim)
    inc a
    ld (tractor_anim), a
    rrca
    rrca                    ; Animate frame every 4 game ticks
    and 3
    cp 2
    jr z, .use_f3
    cp 1
    jr z, .use_f2
    ld iy, tractor_f1_ptrs
    jr .render_tiles
.use_f2:
    ld iy, tractor_f2_ptrs
    jr .render_tiles
.use_f3:
    ld iy, tractor_f3_ptrs

.render_tiles:
    ;; 1. Tier 1: Top Center (boss_x, 158)
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 158
    ld l, (iy+0)
    ld h, (iy+1)
    call DrawSprite16x16

    ;; 2. Tier 2: Mid Left (boss_x - 8, 174)
    ld a, (tractor_boss_x)
    sub 8
    cp PLAY_X_MIN
    jr nc, .m1_x
    ld a, PLAY_X_MIN
.m1_x:
    ld b, a
    ld c, 174
    ld l, (iy+2)
    ld h, (iy+3)
    call DrawSprite16x16

    ;; 3. Tier 2: Mid Center (boss_x, 174)
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 174
    ld l, (iy+4)
    ld h, (iy+5)
    call DrawSprite16x16

    ;; 4. Tier 2: Mid Right (boss_x + 8, 174)
    ld a, (tractor_boss_x)
    add a, 8
    cp PLAY_X_MAX + 1
    jr c, .m2_x
    ld a, PLAY_X_MAX
.m2_x:
    ld b, a
    ld c, 174
    ld l, (iy+6)
    ld h, (iy+7)
    call DrawSprite16x16

    ;; 5. Tier 3: Bot Left (boss_x - 8, 190)
    ld a, (tractor_boss_x)
    sub 8
    cp PLAY_X_MIN
    jr nc, .b1_x
    ld a, PLAY_X_MIN
.b1_x:
    ld b, a
    ld c, 190
    ld l, (iy+8)
    ld h, (iy+9)
    call DrawSprite16x16

    ;; 6. Tier 3: Bot Center (boss_x, 190)
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 190
    ld l, (iy+10)
    ld h, (iy+11)
    call DrawSprite16x16

    ;; 7. Tier 3: Bot Right (boss_x + 8, 190)
    ld a, (tractor_boss_x)
    add a, 8
    cp PLAY_X_MAX + 1
    jr c, .b2_x
    ld a, PLAY_X_MAX
.b2_x:
    ld b, a
    ld c, 190
    ld l, (iy+12)
    ld h, (iy+13)
    call DrawSprite16x16
    ret

;; ----------------------------------------------------------------------------
;; EraseTractorBeam: Clear all 7 16x16 tile areas to Black (Pen 0)
;; ----------------------------------------------------------------------------
EraseTractorBeam:
    ;; 1. Tier 1: Top Center
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 158
    call ClearSprite16x16

    ;; 2. Tier 2: Mid Left
    ld a, (tractor_boss_x)
    sub 8
    cp PLAY_X_MIN
    jr nc, .em1_x
    ld a, PLAY_X_MIN
.em1_x:
    ld b, a
    ld c, 174
    call ClearSprite16x16

    ;; 3. Tier 2: Mid Center
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 174
    call ClearSprite16x16

    ;; 4. Tier 2: Mid Right
    ld a, (tractor_boss_x)
    add a, 8
    cp PLAY_X_MAX + 1
    jr c, .em2_x
    ld a, PLAY_X_MAX
.em2_x:
    ld b, a
    ld c, 174
    call ClearSprite16x16

    ;; 5. Tier 3: Bot Left
    ld a, (tractor_boss_x)
    sub 8
    cp PLAY_X_MIN
    jr nc, .eb1_x
    ld a, PLAY_X_MIN
.eb1_x:
    ld b, a
    ld c, 190
    call ClearSprite16x16

    ;; 6. Tier 3: Bot Center
    ld a, (tractor_boss_x)
    ld b, a
    ld c, 190
    call ClearSprite16x16

    ;; 7. Tier 3: Bot Right
    ld a, (tractor_boss_x)
    add a, 8
    cp PLAY_X_MAX + 1
    jr c, .eb2_x
    ld a, PLAY_X_MAX
.eb2_x:
    ld b, a
    ld c, 190
    call ClearSprite16x16
    ret


;; ----------------------------------------------------------------------------
;; UpdateCapturedFighter: Manage red fighter in formation, dive escort, or rescue
;; ----------------------------------------------------------------------------
UpdateCapturedFighter:
    ld a, (captured_fighter_active)
    or a
    ret z

    cp 3
    jr z, .handle_rescue_fall

    ;; Check Captor Boss Galaga position
    ld ix, (captor_boss_ptr)
    ld a, (ix+0)
    or a
    jr z, .captor_dead
    ld a, (ix+1)
    cp 2
    jr z, .found_captor_boss

.captor_dead:
    ;; Boss was destroyed! Release captured fighter into rescue fall!
    ld a, (captured_fighter_active)
    or a
    ret z
    cp 3
    ret z
    ld a, 3
    ld (captured_fighter_active), a
    call PlaySoundRescue
    call AddPoints1000
    ret

.found_captor_boss:
    ;; Boss is alive. If Boss is in formation, fighter is state 1 (in formation).
    ;; If Boss is diving, fighter is state 2 (escort).
    ld a, (ix+8)
    cp STATE_DIVING
    jr z, .boss_is_diving
    ld a, 1
    ld (captured_fighter_active), a
    jr .dock_with_boss
.boss_is_diving:
    ld a, 2
    ld (captured_fighter_active), a

.dock_with_boss:
    ;; Erase at old position
    ld a, (captured_old_x)
    or a
    jr z, .skip_old_erase
    ld a, (captured_old_x)
    ld b, a
    ld a, (captured_old_y)
    ld c, a
    call ClearSprite16x16
.skip_old_erase:

    ;; Position fighter next to Boss (boss_x + 8, boss_y)
    ld a, (ix+2)
    add a, 8
    cp PLAY_X_MAX + 1
    jr c, .cap_x_ok
    ld a, PLAY_X_MAX
.cap_x_ok:
    ld (captured_fighter_x), a
    ld (captured_old_x), a
    ld a, (ix+3)
    ld (captured_fighter_y), a
    ld (captured_old_y), a

    ;; Draw red captured fighter
    ld a, (captured_fighter_x)
    ld b, a
    ld a, (captured_fighter_y)
    ld c, a
    ld hl, captured_player_sprite
    call DrawSprite16x16
    ret

.handle_rescue_fall:
    ;; *** FREED CAPTURED FIGHTER DESCENDING TO LINK UP WITH PLAYER! ***
    ;; Erase old position
    ld a, (captured_old_x)
    or a
    jr z, .no_prev_cap_erase
    ld b, a
    ld a, (captured_old_y)
    ld c, a
    call ClearSprite16x16
.no_prev_cap_erase:

    ;; Steer X toward player_x + 8 (up to 2 pixels/frame)
    ld a, (player_x)
    add a, 8
    ld c, a
    ld a, (captured_fighter_x)
    cp c
    jr z, .rescue_fall_y
    jr c, .rescue_inc_x
    dec a
    cp c
    jr z, .steer_x_done
    dec a
.steer_x_done:
    ld (captured_fighter_x), a
    jr .rescue_fall_y

.rescue_inc_x:
    inc a
    cp c
    jr z, .steer_x_inc_done
    inc a
.steer_x_inc_done:
    ld (captured_fighter_x), a

.rescue_fall_y:
    ;; Descend Y down toward player_y (2 pixels/frame for smooth, snappy arcade docking)
    ld a, (player_y)
    ld b, a
    ld a, (captured_fighter_y)
    add a, 2
    ld (captured_fighter_y), a
    cp b
    jr c, .draw_descending_rescue

    ;; *** DOCKED WITH PLAYER SHIP! CONVERT TO DUAL FIGHTER! ***
    xor a
    ld (captured_fighter_active), a
    ld (captured_old_x), a
    ld (captured_old_y), a
    ld a, 1
    ld (is_dual_fighter), a  ; DUAL FIGHTER ACTIVATED!

    ;; Redraw player as Dual Fighter
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_x)
    add a, 8
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16

    call PlaySoundRescue
    ret

.draw_descending_rescue:
    ld a, (captured_fighter_x)
    ld (captured_old_x), a
    ld a, (captured_fighter_y)
    ld (captured_old_y), a

    ld a, (captured_fighter_x)
    ld b, a
    ld a, (captured_fighter_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16
    ret

;; ----------------------------------------------------------------------------
;; ClearCapturedFighterSprite: Erase captured fighter sprite from screen if active
;; ----------------------------------------------------------------------------
ClearCapturedFighterSprite:
    ld a, (captured_old_x)
    or a
    ret z
    ld b, a
    ld a, (captured_old_y)
    ld c, a
    call ClearSprite16x16
    xor a
    ld (captured_old_x), a
    ld (captured_old_y), a
    ret
