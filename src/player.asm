;; ============================================================================
;; Galaga CPC - Player Ship Logic & Input
;; Playfield X=PLAY_X_MIN..PLAY_X_MAX, Y=DEFAULT_PLAYER_Y
;; ============================================================================

ReadInput:
    ;; Player control is locked while the tractor beam is lifting the ship.
    ld a, (tractor_beam_active)
    cp 2
    ret z

    ;; Check if stage intro is active (input locked during Level 1 intro)
    ld a, (stage_intro_state)
    or a
    ret nz

    ;; Check if waiting for replacement fighter to spawn
    ld a, (capture_delay)
    or a
    ret nz
    ld a, (respawn_wait)
    or a
    ret nz

    call read_controls

    ;; Check Pause key ('H')
    ld a, (ctl_pressed)
    bit CTL_PAUSE, a
    jr z, .no_pause
    call HandlePause
    ret

.no_pause:
    ;; Check Left
    ld a, (ctl_now)
    bit CTL_LEFT, a
    jr z, .check_right
    ld a, (player_x)
    sub 2
    jr c, .check_fire
    cp PLAY_X_MIN - 1
    jr c, .check_fire
    ld (player_x), a
    jr .check_fire

.check_right:
    ld a, (ctl_now)
    bit CTL_RIGHT, a
    jr z, .check_fire

    ld a, (is_dual_fighter)
    or a
    jr nz, .check_right_dual

    ;; Single Fighter right limit: X <= PLAY_X_MAX
    ld a, (player_x)
    add a, 2
    cp PLAY_X_MAX + 2
    jr nc, .check_fire
    ld (player_x), a
    jr .check_fire

.check_right_dual:
    ;; Dual Fighter right limit: X <= PLAY_X_MAX - 8
    ld a, (player_x)
    add a, 2
    cp PLAY_X_MAX - 8 + 2
    jr nc, .check_fire
    ld (player_x), a

.check_fire:
    ld a, (ctl_now)
    bit CTL_FIRE, a
    jr nz, .fire_pressed

    xor a
    ld (fire_button_state), a
    ret

.fire_pressed:
    ld a, (fire_button_state)
    or a
    ret nz                  ; Already held

    ld a, 1
    ld (fire_button_state), a
    call SpawnMissile
    ret

UpdatePlayer:
    ld a, (game_over)
    or a
    ret nz

    ;; After losing a life, hold the next fighter back until the minimum wait
    ;; has passed and every attacking enemy is back in formation.
    ld a, (respawn_wait)
    or a
    jr z, .no_respawn_wait
    dec a
    jr z, .respawn_when_settled
    ld (respawn_wait), a
    ret
.respawn_when_settled:
    ;; Let a stage clear finish first: it belongs to the current player.
    ld a, (stage_clear_active)
    or a
    ret nz
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.settle_loop:
    ld a, (ix+0)
    or a
    jr z, .settle_next
    ld a, (ix+8)
    or a
    jr z, .settle_next
    cp STATE_ENTRY
    ret c                   ; Diving, returning or tractor states: keep waiting.
.settle_next:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .settle_loop
    xor a
    ld (respawn_wait), a
    ;; In a 2-player game the other player takes over while they have lives.
    call OtherPlayerAlive
    jp nz, SwitchPlayer
    jp RespawnPlayer
.no_respawn_wait:

    ;; The capture animation owns the player's position and drawing.
    ld a, (tractor_beam_active)
    cp 2
    ret z

    ;; If replacement is delayed after capture: skip UpdatePlayer.
    ld a, (capture_delay)
    or a
    ret nz

    ;; Decrement invincibility timer if active
    ld a, (player_invincible_timer)
    or a
    jr z, .p_not_invincible
    dec a
    ld (player_invincible_timer), a
.p_not_invincible:
    ;; During normal play, avoid erasing and redrawing a stationary ship.
    ld a, (player_invincible_timer)
    or a
    jr nz, .redraw_player
    ld a, (player_x)
    ld c, a
    ld a, (old_player_x)
    cp c
    jr nz, .redraw_player
    ret

.redraw_player:
    ld a, (is_dual_fighter)
    or a
    jr nz, .update_dual

    ;; --- Single Fighter ---
    ld a, (old_player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (player_x)
    ld (old_player_x), a

    ;; Check invincibility flicker (blink every 2 frames)
    ld a, (player_invincible_timer)
    or a
    jr z, .draw_single_ship
    bit 0, a
    ret nz                  ; Skip draw on flicker frame

.draw_single_ship:
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16
    ret

.update_dual:
    ;; --- Dual Fighter ---
    ld a, (old_player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (old_player_x)
    add a, 8
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16

    ld a, (player_x)
    ld (old_player_x), a

    ;; Check invincibility flicker (blink every 2 frames)
    ld a, (player_invincible_timer)
    or a
    jr z, .draw_dual_ships
    bit 0, a
    ret nz

.draw_dual_ships:
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
    ret

HitPlayer:
    ;; The tractor beam controls the ship during its capture animation.
    ld a, (tractor_beam_active)
    cp 2
    ret z

    ;; Immune while invincible
    ld a, (player_invincible_timer)
    or a
    ret nz

    ld a, (is_dual_fighter)
    or a
    jp z, PlayerDied

    ;; Dual Fighter hit! One fighter absorbs the hit, other survives!
    xor a
    ld (is_dual_fighter), a

    ;; Erase dual ship
    ld a, (player_x)
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

    ;; Spawn explosion at player position
    ld a, (player_x)
    add a, 4
    ld b, a
    ld a, (player_y)
    ld c, a
    call SpawnExplosion
    call PlaySoundExplosion

    ;; Redraw single surviving fighter
    ld a, (player_x)
    ld (old_player_x), a
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16
    ret

PlayerDied:
    ;; Erase player ship
    ld a, (is_dual_fighter)
    or a
    jr nz, .erase_dual_death

    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16
    jr .do_death_exp

.erase_dual_death:
    xor a
    ld (is_dual_fighter), a
    ld a, (player_x)
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

.do_death_exp:
    ;; Spawn Player Explosion
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call SpawnExplosion
    call PlaySoundExplosion

    ;; Decrease lives with strict underflow check
    ld a, (player_lives)
    or a
    jr z, PlayerOut
    dec a
    ld (player_lives), a
    call DrawLivesHUD

    ld a, (player_lives)
    or a
    jr z, PlayerOut

    ld a, RESPAWN_MIN_WAIT
    ld (respawn_wait), a
    ret

;; PlayerOut: The active player has no lives left. In a 2-player game with the
;; other player still in, show "GAME OVER" and hand over; otherwise the game
;; is over.
PlayerOut:
    xor a
    ld (player_invincible_timer), a
    call OtherPlayerAlive
    jr z, .game_over
    ld a, 1
    ld (player_out), a
    ld a, RESPAWN_MIN_WAIT
    ld (respawn_wait), a
    jr .show
.game_over:
    ld a, 1
    ld (game_over), a
    ld (restart_debounce), a
.show:
    call DrawGameOverText
    jp PlaySoundGameOver

;; IsPlayerAbsent: NZ while no fighter is on screen for enemies to attack
;; (captured, being lifted by the beam, or waiting to respawn).
IsPlayerAbsent:
    ld a, (respawn_wait)
    or a
    ret nz
    ld a, (capture_delay)
    or a
    ret nz
    ld a, (tractor_beam_active)
    cp 2
    jr z, .absent
    xor a
    ret
.absent:
    or a
    ret

RespawnPlayer:
    ld a, 50                ; 2 seconds invincibility
    ld (player_invincible_timer), a
    ld a, PLAYER_START_X
    ld (player_x), a
    ld (old_player_x), a
    ld a, DEFAULT_PLAYER_Y
    ld (player_y), a
    ld (old_player_y), a
    ld b, PLAYER_START_X
    ld c, DEFAULT_PLAYER_Y
    ld hl, player_sprite
    call DrawSprite16x16
    ret

;; ----------------------------------------------------------------------------
;; HandlePause - Pause gameplay, display "PAUSE" banner, mute audio until 'H'
;; ----------------------------------------------------------------------------
HandlePause:
    ld a, 1
    ld (pause_active), a
    call DrawPauseBanner
    call SoundMute

.pause_loop:
    call WaitVSync
    call read_controls
    ld a, (ctl_pressed)
    bit CTL_PAUSE, a
    jr z, .pause_loop

    ;; Unpause!
    xor a
    ld (pause_active), a
    call ClearPauseBanner
    call SoundUnmute
    ret
