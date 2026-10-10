;; ============================================================================
;; Galaga CPC - Main Entry Point & Game Loop
;; Amstrad CPC 464 / 6128 Overscan Edition
;; Based on LoukoumasCPC overscan architecture
;; ============================================================================

    org #0600

    include "config.asm"
    include "constants.asm"

start:
    di
    ld sp, #7FFF                ; Place stack below Page 2 Video RAM (#8000..#FFFF)

    ;; 1. Set Mode 0 and disable firmware ROMs via Gate Array
    ld bc, #7F8C                ; Mode 0, Upper ROM off, Lower ROM off
    out (c), c

    ;; Copy disk routines out of the load image into unused low RAM.
    ld hl, disk_reloc_src
    ld de, HS_DISK_CODE
    ld bc, DISK_CODE_SIZE
    ldir

    ;; 2. Precompute scanline table spanning Page 2 and Page 3
    call build_line_tab

    ;; 3. All pens black until the title screen is drawn, so leftovers in
    ;; video RAM (or the tape loading screen) never show in overscan
    call SetBlackPalette

    ;; 4. Setup CRTC registers for 96x272 overscan
    call setup_crtc

    ;; 5. Initialize AY-3-8912 PSG Sound Driver
    call SoundInit

    ;; Restore the saved Hall of Fame before drawing the title screen.
    call HighScoreLoad
    call SoundInterruptInit

    ;; 6. Jump to Title Screen & Attract Mode!
    jp ShowTitleScreen

GameLoop:
    ;; A steady 25 updates a second: one every second VSYNC
    call WaitFrame25

    ;; --- TOP OF FRAME / VBLANK ZONE ---
    ;; Update Enemies FIRST, right after VSYNC, so the formation near the top
    ;; of the playfield is drawn as early as possible ahead of the raster.
    call UpdateEnemies

    ;; Check Collisions immediately after enemy movement
    call CheckCollisions

    ;; Moving Starfield Background
    call UpdateStars

    ;; Check if Game Over is active
    ld a, (game_over)
    or a
    jp nz, HandleGameOver

    ;; Update the player before other lower-screen sprites so its scanlines
    ;; are ready well before the raster reaches the bottom of the display.
    call ReadInput
    call UpdatePlayer

    ;; Update Player Missiles
    call UpdateMissiles

    ;; Update Enemy Bullets
    call UpdateEBullets

    ;; Update Explosions
    call UpdateExplosions

    ;; Update Floating Bonus Score Popups
    call UpdateBonusScore

    ;; Draw the beam last so stars and later-updated sprites cannot show through it.
    ld a, (tractor_beam_active)
    cp 1
    jr z, .draw_tractor_beam
    cp 2
    jr nz, .skip_tractor_beam
.draw_tractor_beam:
    call DrawTractorBeam
    ld a, (tractor_beam_active)
    cp 2
    call z, DrawTractorCaptureFighter
.skip_tractor_beam:

    ;; Update AY-3-8912 Sound Envelopes & Pitch
    call SoundUpdate

    ;; Check Stage Progression & Wave Clearing
    call UpdateStageProgression

    ;; Refresh any active text/banners so letters always have priority over sprites
    call RefreshPriorityText
    call BlinkActiveLabel

    jp GameLoop

;; ----------------------------------------------------------------------------
;; HandleGameOver: Frozen gameplay loop during Game Over, waiting for restart
;; ----------------------------------------------------------------------------
HandleGameOver:
    call DrawActiveLabel
    call SoundUpdate
    call UpdateExplosions
    call RefreshPriorityText

    ld a, (game_over_phase)
    or a
    jr nz, .results_phase

    ;; Phase 0: "GAME OVER" banner displayed
    ld a, (game_over_timer)
    inc a
    ld (game_over_timer), a
    cp 43                   ; ~1.7 seconds, then always show the results
    jp c, GameLoop

    ;; Transition to Phase 1: Authentic Results Screen!
    ld a, 1
    ld (game_over_phase), a
    call ClearGameOverText
    call DrawResultsScreen
    jp GameLoop

.results_phase:
    ;; Debounce delay (~1.5s = 75 frames at 50Hz) before accepting restart
    ld a, (restart_debounce)
    cp 38
    jr nc, .check_restart_key
    inc a
    ld (restart_debounce), a
    jp GameLoop

.check_restart_key:
    call read_controls
    ld a, (ctl_pressed)
    bit CTL_FIRE, a
    jp z, GameLoop

    ;; Player pressed Fire! Each player whose score qualifies for the Top 5
    ;; Hall of Fame enters initials, then back to the title screen.
    jp NextInitialsOrTitle

;; ----------------------------------------------------------------------------
;; NextInitialsOrTitle: Offer the initials screen to the next player that has
;; not been checked yet (player 1, then player 2), else show the title screen.
;; ----------------------------------------------------------------------------
NextInitialsOrTitle:
    ld a, (two_player)
    inc a
    ld b, a                     ; B = number of players
    ld a, (initials_player)
    cp b
    jp nc, ShowTitleScreen
    ld hl, active_player
    cp (hl)
    call nz, SwapPlayerState    ; Make that player's score the active one
    ld hl, initials_player
    inc (hl)
    call CheckHighScoreQualify
    jp nc, EnterInitialsScreen  ; Qualified (Carry clear)!
    jr NextInitialsOrTitle

;; ----------------------------------------------------------------------------
;; StartNewGame: Start a 1- or 2-player game (two_player already set). Player 2
;; starts from a copy of player 1's fresh state.
;; ----------------------------------------------------------------------------
StartNewGame:
    xor a
    ld (active_player), a
    ld (initials_player), a
    ld (player_out), a
    ld (results_drawn), a
    ld hl, 0
    ld (player_score + OTHER_PLAYER), hl
    ld (player_score_hi + OTHER_PLAYER), a
    call RestartGame
    ld a, (two_player)
    or a
    ret z
    ld hl, player_state
    ld de, PLAYER_SWAP_BUF
    ld bc, PLAYER_STATE_SIZE
    ldir
    ld hl, ENEMY_STATE
    ld de, ENEMY_SWAP_BUF
    ld bc, ENEMY_STATE_SIZE
    ldir
    ret

;; ----------------------------------------------------------------------------
;; SwapPlayerState: Exchange the active player's state with the inactive
;; player's copy and toggle active_player.
;; ----------------------------------------------------------------------------
SwapPlayerState:
    ld hl, player_state
    ld de, PLAYER_SWAP_BUF
    ld bc, PLAYER_STATE_SIZE
    call .swap
    ld hl, ENEMY_STATE
    ld de, ENEMY_SWAP_BUF
    ld bc, ENEMY_STATE_SIZE
    call .swap
    ld a, (active_player)
    xor 1
    ld (active_player), a
    ret
.swap:
    ld a, (de)
    push af
    ld a, (hl)
    ld (de), a
    pop af
    ld (hl), a
    inc hl
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .swap
    ret

;; OtherPlayerAlive: NZ in a 2-player game while the inactive player has lives.
OtherPlayerAlive:
    ld a, (two_player)
    or a
    ret z
    ld a, (player_lives + OTHER_PLAYER)
    or a
    ret

;; ----------------------------------------------------------------------------
;; SwitchPlayer: Hand the game to the other player. Their stage, enemies and
;; captured fighter resume exactly where they left off.
;; ----------------------------------------------------------------------------
SwitchPlayer:
    call ClearTransients
    xor a
    ld (player_out), a
    ld (bonus_score_timer), a
    ld (priority_text_active), a
    ld (tractor_beam_active), a
    ld (tractor_beam_drawn), a
    ld (tractor_anim), a
    ld (capture_delay), a
    ld (respawn_wait), a
    ld (fire_button_state), a
    call SwapPlayerState

    call SoundInit
    call ClearScreenOverscan
    call InitHUD
    call DrawLivesHUD
    call DrawStageHUD

    ;; Redraw the resumed formation
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.redraw:
    push bc
    call DrawEnemyIX
    pop bc
    ld de, ENEMY_SIZE
    add ix, de
    djnz .redraw

    call RespawnPlayer

    ;; "PLAYER n" banner while the formation is held
    ld a, 2
    ld (stage_intro_state), a
    ld a, 38
    ld (stage_intro_timer), a
    jp DrawPlayerBanner

;; ClearTransients: Remove all missiles, enemy bullets and explosions
ClearTransients:
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
    ret

;; ----------------------------------------------------------------------------
;; RestartGame: Reset game state and start fresh game
;; ----------------------------------------------------------------------------
RestartGame:
    ;; 1. Reset state flags
    xor a
    ld (game_over), a
    ld (pause_active), a
    ld (restart_debounce), a
    ld (game_over_timer), a
    ld (game_over_phase), a
    ld (enemy_fire_freeze), a
    ld (transform_killed), a
    ld (fire_button_state), a
    ld (stage_clear_active), a
    ld (stage_clear_timer), a
    ld (priority_text_active), a
    ld (player_invincible_timer), a
    ld (is_dual_fighter), a
    ld (extra_life_count), a
    ld (tractor_beam_active), a
    ld (tractor_beam_drawn), a
    ld (tractor_anim), a
    ld (tractor_trigger_cnt), a
    ld (captured_fighter_active), a
    ld (captured_old_x), a
    ld (is_challenging_stage), a
    ld (challenging_active), a
    ld (stage_phase), a
    ld (entry_spawn_idx), a
    ld (entry_spawn_timer), a
    ld (bonus_score_timer), a
    ld (respawn_wait), a
    ld (capture_delay), a

    ld hl, 0
    ld (shots_fired), hl
    ld (shots_hit), hl

    ld a, 3
    ld (player_lives), a

    ld a, 1
    ld (current_stage), a

    call InitAttackThreshold

    ;; Reset player score (24-bit)
    ld hl, 0
    ld (player_score), hl
    xor a
    ld (player_score_hi), a
    ld (extra_life_count), a
    ld hl, 20000
    ld (next_extra_life_lo), hl
    ld (next_extra_life_hi), a

    ;; Reset player coordinates
    ld a, PLAYER_START_X
    ld (player_x), a
    ld (old_player_x), a
    ld a, DEFAULT_PLAYER_Y
    ld (player_y), a
    ld (old_player_y), a

    ;; Clear all missiles, enemy bullets, and explosions
    call ClearTransients

    ;; Clear 32KB Video RAM
    call ClearScreenOverscan

    ;; Redraw HUD, Lives, Stage
    call InitHUD
    call DrawLivesHUD
    call DrawStageHUD

    ;; Draw Player Ship
    ld b, PLAYER_START_X
    ld c, DEFAULT_PLAYER_Y
    ld hl, player_sprite
    call DrawSprite16x16

    ;; Reset Sound
    call SoundInit

    ;; Play authentic Game Start Tune from assets/game-start-tune.mid
    call PlayMusicGameStart

    ;; Reset and draw enemy formation
    call InitEnemies

    ;; Setup Stage 1 Intro sequence:
    ;; 1. Display "STAGE 1" for at least 2 seconds (105 frames = ~2.1s at 50Hz)
    ;; 2. Followed by "PLAYER 1" for 1 second (50 frames at 50Hz)
    ;; 3. Intro music plays continuously in background
    ld a, 1
    ld (stage_intro_state), a
    ld a, 53
    ld (stage_intro_timer), a
    call DrawStageBanner
    ret

;; ----------------------------------------------------------------------------
;; Included Modular Components
;; ----------------------------------------------------------------------------
    include "crtc.asm"
    include "keys.asm"
    include "video.asm"
    include "hud.asm"
    include "badges.asm"
    include "player.asm"
    include "missiles.asm"
    include "ebullets.asm"
    include "enemies.asm"
    include "tractor.asm"
    include "challenging.asm"
    include "collisions.asm"
    include "explosions.asm"
    include "stars.asm"
    include "bonus_score.asm"
    include "sound.asm"
    include "stages.asm"
    include "title.asm"
    include "initials.asm"
    include "data.asm"
    include "sprites.asm"
    include "tractor_beam_data.asm"

;; Disk code is embedded in the load image and relocated to low RAM at boot.
disk_reloc_src:
    include "disk.asm"
DISK_CODE_SIZE equ disk_code_end-HS_DISK_CODE
    assert disk_code_end <= #0600
;; Once relocated, the load-image copy is free: the scanline table goes there.
line_tab        equ disk_reloc_src
    assert DISK_CODE_SIZE >= DISPLAY_LINES * 2
    org disk_reloc_src+DISK_CODE_SIZE, disk_reloc_src+DISK_CODE_SIZE

;; ----------------------------------------------------------------------------
;; Export to DSK Virtual Disk
;; ----------------------------------------------------------------------------
end_program:
    assert end_program <= #8000
    ; The build script packages the binary and raw save sector into the DSK.
