;; ============================================================================
;; Galaga CPC - Main Entry Point & Game Loop
;; Amstrad CPC 464 / 6128
;; ============================================================================

    org #4000

    include "constants.asm"

start:
    ;; 1. Set Mode 0 (Firmware: 160x200, 16 colors)
    ld a, 0
    call #BC0E              ; SCR SET MODE

    ;; 2. Setup Full Palette (Firmware SCR SET INK)
    ;; Pen 0 = Black (Firmware Color 0)
    ld a, 0
    ld b, 0
    ld c, 0
    call #BC32

    ;; Pen 1 = Bright Blue (Firmware Color 2)
    ld a, 1
    ld b, 2
    ld c, 2
    call #BC32

    ;; Pen 2 = Bright Red (Firmware Color 6)
    ld a, 2
    ld b, 6
    ld c, 6
    call #BC32

    ;; Pen 3 = Bright Yellow (Firmware Color 24)
    ld a, 3
    ld b, 24
    ld c, 24
    call #BC32

    ;; Pen 4 = Bright Cyan (Firmware Color 11)
    ld a, 4
    ld b, 11
    ld c, 11
    call #BC32

    ;; Pen 5 = Bright Magenta (Firmware Color 7)
    ld a, 5
    ld b, 7
    ld c, 7
    call #BC32

    ;; Pen 6 = Bright Green (Firmware Color 18)
    ld a, 6
    ld b, 18
    ld c, 18
    call #BC32

    ;; Pen 15 = Bright White (Firmware Color 26)
    ld a, 15
    ld b, 26
    ld c, 26
    call #BC32

    ;; Border = Black (Firmware Color 0)
    ld b, 0
    ld c, 0
    call #BC38              ; SCR SET BORDER

    ;; 3. Clear entire 16KB Video RAM (#C000 - #FFFF) to Black (#00)
    ld hl, #C000
    ld de, #C001
    ld bc, #3FFF
    ld (hl), 0
    ldir

    ;; 4. Initialize HUD and Lives indicator
    call InitHUD
    call DrawLivesHUD

    ;; 5. Draw initial authentic player ship
    ld a, (player_x)
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16
    ld a, (player_x)
    ld (old_player_x), a

    ;; 6. Initialize enemy formation (10 enemies)
    call InitEnemies

    ;; 7. Initialize AY-3-8912 PSG Sound Driver
    call SoundInit

GameLoop:
    ;; 8. Wait for VSYNC (Firmware: 50Hz)
    call #BD19              ; MC WAIT FLYBACK

    ;; 9. Moving Starfield Background
    call UpdateStars

    ;; 10. Check if Game Over is active
    ld a, (game_over)
    or a
    jp nz, HandleGameOver

    ;; 11. Read Keyboard input (Left, Right, Space/Fire)
    call ReadInput

    ;; 12. Update Player Ship
    call UpdatePlayer

    ;; 13. Update Player Missiles
    call UpdateMissiles

    ;; 14. Update Enemy Bullets
    call UpdateEBullets

    ;; 15. Update Enemy Formation & Dive-bombing
    call UpdateEnemies

    ;; 16. Check Collisions (Missile vs Enemy, EBullet vs Player, Enemy vs Player)
    call CheckCollisions

    ;; 17. Update Explosions
    call UpdateExplosions

    ;; 18. Update AY-3-8912 Sound Envelopes & Pitch
    call SoundUpdate

    ;; 19. Check Stage Progression & Wave Clearing
    call UpdateStageProgression

    jp GameLoop

;; ----------------------------------------------------------------------------
;; HandleGameOver: Frozen gameplay loop during Game Over, waiting for restart
;; ----------------------------------------------------------------------------
HandleGameOver:
    ;; Allow explosion animation and sound decay to finish playing
    call SoundUpdate
    call UpdateExplosions

    ;; Debounce delay (~1.5s = 75 frames at 50Hz) before accepting restart
    ld a, (restart_debounce)
    cp 75
    jr nc, .check_restart_key
    inc a
    ld (restart_debounce), a
    jp GameLoop

.check_restart_key:
    ;; Check Spacebar (Key 47) or Joystick Fire (Key 77)
    ld a, 47
    call #BB1E              ; KM TEST KEY
    jr nz, .do_restart

    ld a, 77
    call #BB1E
    jr nz, .do_restart

    jp GameLoop

.do_restart:
    call RestartGame
    jp GameLoop

;; ----------------------------------------------------------------------------
;; RestartGame: Reset game state and start fresh game
;; ----------------------------------------------------------------------------
RestartGame:
    ;; 1. Reset state flags
    xor a
    ld (game_over), a
    ld (restart_debounce), a
    ld (fire_button_state), a
    ld (stage_clear_active), a
    ld (stage_clear_timer), a
    ld (is_dual_fighter), a
    ld (extra_life_awarded), a
    ld (tractor_beam_active), a
    ld (tractor_trigger_cnt), a
    ld (captured_fighter_active), a
    ld (captured_old_x), a
    ld (is_challenging_stage), a
    ld (challenging_active), a

    ld a, 3
    ld (player_lives), a

    ld a, 1
    ld (current_stage), a

    ld a, 130
    ld (attack_threshold), a

    ;; Reset player score
    ld hl, 0
    ld (player_score), hl

    ;; Reset player coordinates
    ld a, 36
    ld (player_x), a
    ld (old_player_x), a
    ld a, 160
    ld (player_y), a
    ld (old_player_y), a

    ;; Clear all missiles, enemy bullets, and explosions
    ld hl, missile_data
    ld de, missile_data + 1
    ld bc, (MISSILE_SIZE * MAX_MISSILES) - 1
    ld (hl), 0
    ldir

    ld hl, ebullet_data
    ld de, ebullet_data + 1
    ld bc, (EBULLET_SIZE * MAX_EBULLETS) - 1
    ld (hl), 0
    ldir

    ld hl, explosion_data
    ld de, explosion_data + 1
    ld bc, (EXPLOSION_SIZE * MAX_EXPLOSIONS) - 1
    ld (hl), 0
    ldir


    ;; 2. Clear entire 16KB Video RAM (#C000 - #FFFF) to Black (#00)
    ld hl, #C000
    ld de, #C001
    ld bc, #3FFF
    ld (hl), 0
    ldir

    ;; 3. Redraw HUD, Lives, Stage
    call InitHUD
    call DrawLivesHUD
    call DrawStageHUD

    ;; 4. Draw Player Ship
    ld a, (player_x)
    call GetPlayerScreenAddr
    ld hl, player_sprite
    call DrawSprite16x16

    ;; 5. Reset Sound
    call SoundInit

    ;; 6. Reset and draw enemy formation
    call InitEnemies
    ret


;; ----------------------------------------------------------------------------
;; Included Modular Components
;; ----------------------------------------------------------------------------
    include "video.asm"
    include "hud.asm"
    include "player.asm"
    include "missiles.asm"
    include "ebullets.asm"
    include "enemies.asm"
    include "tractor.asm"
    include "challenging.asm"
    include "collisions.asm"
    include "explosions.asm"
    include "stars.asm"
    include "sound.asm"
    include "stages.asm"
    include "data.asm"
    include "sprites.asm"


;; ----------------------------------------------------------------------------
;; Export to DSK Virtual Disk
;; ----------------------------------------------------------------------------
end_program:
    save "GALAGA.BIN", #4000, end_program-#4000, DSK, "build/galaga.dsk", start
