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

    ;; Delay expired! Clear "FIGHTER CAPTURED" banner; the replacement fighter
    ;; appears once the attacking enemies are back in formation.
    call ClearCapturedBanner
    ld a, 1
    ld (respawn_wait), a

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
    ;; Boss dives straight down to TRACTOR_HOVER_Y to emit beam
    ld a, (ix+3)
    add a, 2
    ld (ix+3), a
    cp TRACTOR_HOVER_Y
    jr c, .dive_down_ok

    ;; Reached hover scanline! Switch to emitting beam
    ld (ix+3), TRACTOR_HOVER_Y
    ld (ix+8), STATE_TRACTOR_BEAM
    ld a, 1
    ld (tractor_beam_active), a
    ld a, 120               ; ~2.4 seconds duration
    ld (tractor_timer), a
    ld a, (ix+2)
    ld (tractor_boss_x), a
    sub 8
    jr nc, .beam_x_ok
    xor a
.beam_x_ok:
    ld (tractor_beam_x), a
    ld a, (ix+3)
    ld (tractor_boss_y), a

.dive_down_ok:
    call EraseEnemyDeltaIX
    ld a, (ix+2)
    ld (ix+4), a
    ld a, (ix+3)
    ld (ix+5), a
    push bc
    call DrawEnemyIX
    pop bc
    ret

.handle_tractor_beam:
    ;; Emitting beam while hovering at TRACTOR_HOVER_Y
    call RedrawTractorBoss
    call PlaySoundTractor

    ;; Check if player is caught in beam (never while no fighter is on screen)
    call IsPlayerAbsent
    jp nz, .beam_timer_tick
    ld a, (player_invincible_timer)
    or a
    jp nz, .beam_timer_tick     ; Immune while invincible!

    ;; Capture when the player's 8-byte-wide sprite overlaps the 24-byte beam.
    ld a, (player_x)
    add a, 8
    ld c, a
    ld a, (tractor_beam_x)
    cp c
    jp nc, .beam_timer_tick

    ld a, (tractor_beam_x)
    add a, 24
    ld c, a
    ld a, (player_x)
    cp c
    jp nc, .beam_timer_tick

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
    ;; Center the captured ship under the beam and begin a gradual lift.
    ld a, (tractor_boss_x)
    ld (player_x), a
    ld (old_player_x), a
    ld (ix+8), STATE_CAPTURING
    ld a, 2
    ld (tractor_beam_active), a
    jp .handle_capturing

.handle_capturing:
    call RedrawTractorBoss

    ;; Move the ship upward two pixels per frame until it reaches the Boss.
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (player_y)
    cp TRACTOR_BEAM_Y
    jr c, .capture_reached_boss
    jr z, .capture_reached_boss
    sub 2
    cp TRACTOR_BEAM_Y
    jr nc, .capture_y_ready
    ld a, TRACTOR_BEAM_Y
.capture_y_ready:
    ld (player_y), a
    ld (old_player_y), a
    ret

.capture_reached_boss:
    ;; The ship is fully lifted; clear the beam before docking it by the Boss.
    ld (ix+8), STATE_RETURNING
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16
    push ix
    call EraseTractorBeam
    pop ix
    xor a
    ld (tractor_beam_active), a
    jp CompleteTractorCapture

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
    ld (ix+12), 0           ; Pick a fresh dive speed and aim point.
    ld (ix+13), 0
    ret

;; The hovering Boss is not moved, so other sprites erasing over it would
;; leave it invisible. Redraw it every frame while the beam is active.
RedrawTractorBoss:
    push bc
    call DrawEnemyIX
    pop bc
    ret

CompleteTractorCapture:
    ;; Dock captured fighter next to the Boss and charge the lost life.
    ld a, 1
    ld (captured_fighter_active), a
    ;; Decrease player lives with underflow prevention
    ld a, (player_lives)
    or a
    jr z, .capture_game_over
    dec a
    ld (player_lives), a
    call DrawLivesHUD

    or a
    jr z, .capture_game_over

    ;; Display "FIGHTER CAPTURED" banner in Cyan
    call DrawFighterCapturedBanner
    call PlayMusicFighterCaptured
    ld a, 150               ; ~3.0s delay for 21-step capture tune before next ship spawns
    ld (capture_delay), a
    ret

.capture_game_over:
    call ClearCapturedBanner
    ld a, 1
    ld (game_over), a
    ld a, 1
    ld (restart_debounce), a
    call DrawGameOverText
    call PlaySoundGameOver
    ret

ClearCapturedBanner:
    jp ClearFighterCapturedBanner

;; ----------------------------------------------------------------------------
;; DrawTractorBeam: Render the native frames from tractorSpriteMap.png.
;; ----------------------------------------------------------------------------
DrawTractorBeam:
    ld a, (tractor_anim)
    inc a
    cp 12
    jr c, .store_anim
    xor a
.store_anim:
    ld (tractor_anim), a

    ld a, (tractor_anim)
    cp 4
    jr c, .frame_1
    cp 8
    jr c, .frame_2
    ld hl, tractor_beam_frame_3
    jr .draw
.frame_1:
    ld hl, tractor_beam_frame_1
    jr .draw
.frame_2:
    ld hl, tractor_beam_frame_2
.draw:
    ld de, 384                ; Skip the 16 scanlines hidden by the Boss sprite.
    add hl, de
    ld a, (tractor_beam_x)
    ld b, a
    ld c, TRACTOR_BEAM_Y
    ld d, 24
    ld e, TRACTOR_BEAM_H
    call DrawBitmapRect
    ld a, 1
    ld (tractor_beam_drawn), a
    ret

DrawTractorCaptureFighter:
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, captured_player_sprite
    jp DrawSprite16x16

;; ----------------------------------------------------------------------------
;; EraseTractorBeam: Remove the last frame and restore its background.
;; ----------------------------------------------------------------------------
EraseTractorBeam:
    ld a, (tractor_beam_drawn)
    or a
    ret z

    ld a, (tractor_beam_x)
    ld b, a
    ld c, TRACTOR_BEAM_Y
    ld d, 24
    ld e, TRACTOR_BEAM_H
    call ClearBitmapRect
    xor a
    ld (tractor_beam_drawn), a
    call RedrawStars

    ;; Restore enemies that were behind the beam before their next update.
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.redraw_enemy:
    ld a, (ix+0)
    or a
    jr z, .next_enemy

    ld a, (ix+2)
    add a, 8
    ld c, a
    ld a, (tractor_beam_x)
    cp c
    jr nc, .next_enemy

    ld a, (tractor_beam_x)
    add a, 24
    ld c, a
    ld a, (ix+2)
    cp c
    jr nc, .next_enemy

    ld a, (ix+3)
    add a, 16
    cp TRACTOR_BEAM_Y
    jr c, .next_enemy
    jr z, .next_enemy
    ld a, (ix+3)
    cp TRACTOR_BEAM_Y + TRACTOR_BEAM_H
    jr nc, .next_enemy

    push bc
    call DrawEnemyIX
    pop bc
.next_enemy:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .redraw_enemy
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
    ;; With no fighter on screen (captured or awaiting respawn) player_y is not
    ;; the player's line, so the freed fighter waits in place until it is.
    call IsPlayerAbsent
    jr z, .rescue_player_present
    ld a, (captured_old_x)
    or a
    ret z
    ld b, a
    ld a, (captured_old_y)
    ld c, a
    ld hl, player_sprite
    jp DrawSprite16x16
.rescue_player_present:
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
