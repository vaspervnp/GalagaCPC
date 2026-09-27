;; ============================================================================
;; Galaga CPC - Player Ship Logic & Input
;; ============================================================================

ReadInput:
    ;; Check if player is being tractor-beamed (input locked)
    ld a, (tractor_beam_active)
    cp 2
    ret z

    ;; Left Cursor Key (Key 8)
    ld a, 8
    call #BB1E              ; KM TEST KEY
    jr z, .check_right
    ld a, (player_x)
    cp 2
    jr c, .check_right
    dec a
    ld (player_x), a
    jr .check_fire

.check_right:
    ;; Right Cursor Key (Key 1)
    ld a, 1
    call #BB1E              ; KM TEST KEY
    jr z, .check_fire

    ld a, (is_dual_fighter)
    or a
    jr nz, .check_right_dual

    ;; Single Fighter right limit: X <= 70
    ld a, (player_x)
    cp 70
    jr nc, .check_fire
    inc a
    ld (player_x), a
    jr .check_fire

.check_right_dual:
    ;; Dual Fighter right limit: X <= 62 (so player_x + 8 <= 70)
    ld a, (player_x)
    cp 62
    jr nc, .check_fire
    inc a
    ld (player_x), a

.check_fire:
    ;; Spacebar (Key 47) or Joystick Fire (Key 77)
    ld a, 47
    call #BB1E
    jr nz, .fire_pressed

    ld a, 77
    call #BB1E
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
    ld a, (player_x)
    ld hl, old_player_x
    cp (hl)
    ret z

    ld a, (is_dual_fighter)
    or a
    jr nz, .update_dual

    ;; --- Single Fighter ---
    ld a, (old_player_x)
    call GetPlayerScreenAddr
    call ClearSprite16x16

    ld a, (player_x)
    ld (old_player_x), a
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16
    ret

.update_dual:
    ;; --- Dual Fighter ---
    ;; 1. Erase old dual ship
    ld a, (old_player_x)
    call GetPlayerScreenAddr
    call ClearSprite16x16

    ld a, (old_player_x)
    add a, 8
    call GetPlayerScreenAddr
    call ClearSprite16x16

    ;; 2. Update coordinate
    ld a, (player_x)
    ld (old_player_x), a

    ;; 3. Draw new dual ship (two side-by-side fighters)
    ld a, (player_x)
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16

    ld a, (player_x)
    add a, 8
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16
    ret

GetPlayerScreenAddr:
    ld hl, #C640            ; Row 20 base: #C000 + 20*80 = #C640 (Scanline 160)
    ld e, a
    ld d, 0
    add hl, de
    ex de, hl
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
    call GetPlayerScreenAddr
    call ClearSprite16x16

    ld a, (player_x)
    add a, 8
    call GetPlayerScreenAddr
    call ClearSprite16x16

    ;; Spawn explosion at player position
    ld a, (player_x)
    add a, 4
    ld b, a
    ld c, 160
    call SpawnExplosion
    call PlaySoundExplosion

    ;; Redraw single surviving fighter
    ld a, (player_x)
    ld (old_player_x), a
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16
    ret

PlayerDied:
    ;; Erase player ship
    ld a, (is_dual_fighter)
    or a
    jr nz, .erase_dual_death

    ld a, (player_x)
    call GetPlayerScreenAddr
    call ClearSprite16x16
    jr .do_death_exp

.erase_dual_death:
    xor a
    ld (is_dual_fighter), a
    ld a, (player_x)
    call GetPlayerScreenAddr
    call ClearSprite16x16
    ld a, (player_x)
    add a, 8
    call GetPlayerScreenAddr
    call ClearSprite16x16

.do_death_exp:
    ;; Spawn Player Explosion at (player_x, 160)
    ld a, (player_x)
    ld b, a
    ld c, 160
    call SpawnExplosion
    call PlaySoundExplosion

    ;; Decrease lives
    ld a, (player_lives)
    dec a
    ld (player_lives), a
    call DrawLivesHUD

    or a
    jr z, .trigger_game_over

    ;; Respawn single player at center
    ld a, 36
    ld (player_x), a
    ld (old_player_x), a
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16
    ret

.trigger_game_over:
    ld a, 1
    ld (game_over), a
    xor a
    ld (restart_debounce), a

    ;; Display "GAME OVER" in Red at center (Column 6, Row 12)
    ld h, 6
    ld l, 12
    call #BB75
    ld a, 2                 ; Red
    call #BB90
    ld hl, txt_game_over
    call PrintString
    ret

