;; ============================================================================
;; Galaga CPC - Player Ship Logic & Input
;; Overscan Geometry (Playfield X=10..78, Y=210)
;; ============================================================================

ReadInput:
    ;; Check if player is being tractor-beamed (input locked)
    ld a, (tractor_beam_active)
    cp 2
    ret z

    call read_controls

    ;; Check Left
    ld a, (ctl_now)
    bit CTL_LEFT, a
    jr z, .check_right
    ld a, (player_x)
    cp PLAY_X_MIN
    jr c, .check_right
    dec a
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
    cp PLAY_X_MAX
    jr nc, .check_fire
    inc a
    ld (player_x), a
    jr .check_fire

.check_right_dual:
    ;; Dual Fighter right limit: X <= PLAY_X_MAX - 8
    ld a, (player_x)
    cp PLAY_X_MAX - 8
    jr nc, .check_fire
    inc a
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

    ;; Decrease lives
    ld a, (player_lives)
    dec a
    ld (player_lives), a
    call DrawLivesHUD

    ld a, (player_lives)
    or a
    jr z, .trigger_game_over

    call RespawnPlayer
    ret

.trigger_game_over:
    ld a, 1
    ld (game_over), a
    ld a, 1
    ld (restart_debounce), a
    call DrawGameOverText
    call PlaySoundGameOver
    ret

RespawnPlayer:
    ld a, 44
    ld (player_x), a
    ld (old_player_x), a
    ld a, 210
    ld (player_y), a
    ld (old_player_y), a
    ld b, 44
    ld c, 210
    ld hl, player_sprite
    call DrawSprite16x16
    ret
