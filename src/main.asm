;; ============================================================================
;; Galaga CPC - Main Entry Point & Game Loop
;; Amstrad CPC 464 / 6128 Overscan Edition
;; Based on LoukoumasCPC overscan architecture
;; ============================================================================

    org #4000

    include "config.asm"
    include "constants.asm"

start:
    di
    ld sp, #7FFF                ; Place stack below Page 2 Video RAM (#8000..#FFFF)

    ;; 1. Set Mode 0 and disable firmware ROMs via Gate Array
    ld bc, #7F8C                ; Mode 0, Upper ROM off, Lower ROM off
    out (c), c

    ;; 2. Precompute scanline table spanning Page 2 and Page 3
    call build_line_tab

    ;; 3. Setup CRTC registers for 96x272 overscan
    call setup_crtc

    ;; 4. Setup hardware palette
    ld hl, pal_play
    call set_pal

    ;; 5. Clear 32KB overscan buffer to black
    call ClearScreenOverscan

    ;; 6. Initialize AY-3-8912 PSG Sound Driver
    call SoundInit

    ;; 7. Initialize HUD (Upper border scores, Lower border lives & badges)
    call InitHUD
    call DrawLivesHUD
    call DrawStageHUD

    ;; 8. Draw initial authentic player ship
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    ld hl, player_sprite
    call DrawSprite16x16
    ld a, (player_x)
    ld (old_player_x), a

    ;; 9. Initialize enemy formation (10 enemies)
    call InitEnemies

GameLoop:
    ;; Wait for VSYNC (50Hz hardware flyback via PPI)
    call WaitVSync

    ;; Moving Starfield Background
    call UpdateStars

    ;; Check if Game Over is active
    ld a, (game_over)
    or a
    jp nz, HandleGameOver

    ;; Read Keyboard/Joystick input (Left, Right, Fire)
    call ReadInput

    ;; Update Player Ship
    call UpdatePlayer

    ;; Update Player Missiles
    call UpdateMissiles

    ;; Update Enemy Bullets
    call UpdateEBullets

    ;; Update Enemy Formation & Dive-bombing
    call UpdateEnemies

    ;; Check Collisions (Missile vs Enemy, EBullet vs Player, Enemy vs Player)
    call CheckCollisions

    ;; Update Explosions
    call UpdateExplosions

    ;; Update AY-3-8912 Sound Envelopes & Pitch
    call SoundUpdate

    ;; Check Stage Progression & Wave Clearing
    call UpdateStageProgression

    jp GameLoop

;; ----------------------------------------------------------------------------
;; HandleGameOver: Frozen gameplay loop during Game Over, waiting for restart
;; ----------------------------------------------------------------------------
HandleGameOver:
    call WaitVSync
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
    call read_controls
    ld a, (ctl_pressed)
    bit CTL_FIRE, a
    jp z, GameLoop

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
    ld a, 44
    ld (player_x), a
    ld (old_player_x), a
    ld a, 210
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

    ;; Clear 32KB Video RAM
    call ClearScreenOverscan

    ;; Redraw HUD, Lives, Stage
    call InitHUD
    call DrawLivesHUD
    call DrawStageHUD

    ;; Draw Player Ship
    ld b, 44
    ld c, 210
    ld hl, player_sprite
    call DrawSprite16x16

    ;; Reset Sound
    call SoundInit

    ;; Reset and draw enemy formation
    call InitEnemies
    ret

;; ----------------------------------------------------------------------------
;; Included Modular Components
;; ----------------------------------------------------------------------------
    include "crtc.asm"
    include "keys.asm"
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
