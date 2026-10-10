;; ============================================================================
;; Galaga CPC - Game Variables & Static Data Tables
;; Playfield X=0..71 (HUD column X=72..95), sprite Y=PF_Y_TOP..SPRITE_Y_LIMIT-1
;; ============================================================================

player_x:           defb PLAYER_START_X
old_player_x:       defb PLAYER_START_X
player_y:           defb DEFAULT_PLAYER_Y
old_player_y:       defb DEFAULT_PLAYER_Y
player_invincible_timer: defb 0 ; Respawn invincibility countdown (100 frames = 2.0s at 50Hz)
fire_button_state:  defb 0
high_score:             defw 30000
high_score_hi:          defb 0

;; Top 5 Hall of Fame / High Score Table (5 entries x 6 bytes = 30 bytes)
;; Each entry: Score Lo Word (2), Score Hi Byte (1), 3 Initials chars (3)
top5_table:
    defw 30000 : defb 0 : defb 'V', 'A', 'S'  ; 1ST
    defw 20000 : defb 0 : defb 'C', 'P', 'C'  ; 2ND
    defw 15000 : defb 0 : defb 'N', 'A', 'M'  ; 3RD
    defw 10000 : defb 0 : defb 'G', 'A', 'L'  ; 4TH
    defw  5000 : defb 0 : defb 'A', 'A', 'A'  ; 5TH

qualify_rank:           defb 0
entered_initials:       defb 'A', 'A', 'A'
current_slot:           defb 0
entry_blink:            defb 0
title_display_mode:     defb 0      ; 0 = Point Values, 1 = Top 5 Hall of Fame
title_mode_timer:       defb 0      ; Alternates screen mode every ~250 frames
difficulty_level:       defb 1      ; 0 = Easy, 1 = Medium (default), 2 = Hard, 3 = Hardest
game_over:          defb 0
pause_active:       defb 0
restart_debounce:   defb 0
game_over_timer:    defb 0
game_over_phase:    defb 0  ; 0=Game Over text, 1=Results Screen

;; Floating Bonus Score Popup Variables
bonus_score_timer:      defb 0  ; Active if > 0 (6 frames duration)
bonus_score_x:          defb 0
bonus_score_y:          defb 0
bonus_score_old_x:      defb 0
bonus_score_old_y:      defb 0
bonus_score_ptr:        defw 0  ; Pointer to bonus score sprite


;; Tractor Beam & Captured Fighter Variables
tractor_beam_active:        defb 0
tractor_boss_x:             defb 0
tractor_boss_y:             defb 0
tractor_beam_x:             defb 0
tractor_beam_drawn:         defb 0
tractor_timer:              defb 0
tractor_anim:               defb 0
capture_delay:              defb 0
respawn_wait:               defb 0  ; Frames until the next fighter after losing a life


;; Priority Text Variables
priority_text_active:       defb 0
priority_text_x:            defb 0
priority_text_y:            defb 0
priority_text_ptr:          defw 0



;; Missiles: [active, x, y, old_x, old_y, has_old]
missile_data:
    defs MISSILE_SIZE * MAX_MISSILES, 0

;; Enemy Bullets: [active, x, y, old_x, old_y, has_old, dx, phase]
ebullet_data:
    defs EBULLET_SIZE * MAX_EBULLETS, 0

;; Explosions: [active, x, y, timer]
explosion_data:
    defs EXPLOSION_SIZE * MAX_EXPLOSIONS, 0


random_seed:        defb 1
star_draw_x:        defb 0  ; Screen X of the star being updated
star_half:          defb 0  ; In play: which half of the stars moves this frame
irq_count:          defb 0  ; Gate Array interrupts (300 Hz) since the update began
sway_step:          defw 0  ; Formation sway: table walk direction
sway_move:          defb 0  ; Formation sway: direction of the current step
restore_skip_x:     defb 200 ; Docked restore: leave enemies overlapping this
restore_skip_y:     defb 0   ; sprite position to the later pass (200: none)
hud_in_column:      defb 0  ; 1 = in-game HUD column, 0 = title screen top HUD

;; Starfield: 32 Parallax Stars [x, y, color, speed] inside Playfield (X=11..81, Y=34..228)
;; 3 Parallax Layers: Speed 1 (Distant), Speed 2 (Midground), Speed 3 (Foreground)
stars_data:
    ;; --- Layer 1: Distant Slow Stars (Speed 1, 14 stars) ---
    defb 11,  38, #80, 1   ; Blue (Left Pixel)
    defb 17, 112, #08, 1   ; Red (Left Pixel)
    defb 23, 186, #40, 1   ; Blue (Right Pixel)
    defb 29,  64, #04, 1   ; Red (Right Pixel)
    defb 35, 148, #80, 1   ; Blue (Left Pixel)
    defb 41, 218, #20, 1   ; Cyan (Left Pixel)
    defb 47,  46, #08, 1   ; Red (Left Pixel)
    defb 53, 128, #40, 1   ; Blue (Right Pixel)
    defb 59, 196, #04, 1   ; Red (Right Pixel)
    defb 65,  76, #80, 1   ; Blue (Left Pixel)
    defb 71, 162, #10, 1   ; Cyan (Right Pixel)
    defb 77,  96, #08, 1   ; Red (Left Pixel)
    defb 15, 224, #40, 1   ; Blue (Right Pixel)
    defb 81,  44, #04, 1   ; Red (Right Pixel)

    ;; --- Layer 2: Midground Medium Stars (Speed 2, 12 stars) ---
    defb 13,  78, #88, 2   ; Yellow (Left Pixel)
    defb 21, 154, #AA, 2   ; White (Left Pixel)
    defb 27,  44, #20, 2   ; Cyan (Left Pixel)
    defb 33, 192, #44, 2   ; Yellow (Right Pixel)
    defb 39,  88, #55, 2   ; White (Right Pixel)
    defb 45, 172, #88, 2   ; Yellow (Left Pixel)
    defb 51,  58, #10, 2   ; Cyan (Right Pixel)
    defb 57, 206, #AA, 2   ; White (Left Pixel)
    defb 63, 114, #44, 2   ; Yellow (Right Pixel)
    defb 69,  38, #55, 2   ; White (Right Pixel)
    defb 75, 136, #88, 2   ; Yellow (Left Pixel)
    defb 79, 176, #20, 2   ; Cyan (Left Pixel)

    ;; --- Layer 3: Foreground Fast Stars (Speed 3, 6 stars) ---
    defb 19,  52, #FF, 3   ; Bright White (Double Width)
    defb 31, 132, #AA, 3   ; White (Left Pixel)
    defb 43, 212, #CC, 3   ; Bright Yellow (Double Width)
    defb 55,  84, #FF, 3   ; Bright White (Double Width)
    defb 67, 166, #55, 3   ; White (Right Pixel)
    defb 73,  56, #88, 3   ; Yellow (Left Pixel)

;; ============================================================================
;; Per-player game state. Everything a player resumes with in a 2-player game
;; lives between player_state and player_state_end; SwapPlayerState exchanges
;; it with the inactive player's copy at PLAYER_SWAP_BUF.
;; ============================================================================
player_state:
player_score:           defw 0
player_score_hi:        defb 0
player_lives:           defb 3
extra_life_count:       defb 0  ; Milestone count: 1=20k, 2=70k, 3=140k...
next_extra_life_lo:     defw 20000
next_extra_life_hi:     defb 0
shots_fired:            defw 0  ; Arcade statistics: total missiles fired
shots_hit:              defw 0  ; Arcade statistics: total missiles that hit enemies
is_dual_fighter:        defb 0
current_stage:          defb 1
attack_threshold:       defb 130 ; Decreases as stages advance
enemy_fire_freeze:      defb 0  ; Arcade rule: diving boss kill stops enemy firing
transform_killed:       defb 0  ; Arcade rule: count kills in transform group
transform_type:         defb 0  ; Alien of the transform in flight (0 = none)
attack_cycle:           defb 0  ; Arcade attack rotation (0=Bee, 1=Butterfly, 2=Boss, 3=Bee)
transform_trigger_cnt:  defb 0  ; Cadence counter for Transform Trios
tractor_trigger_cnt:    defb 0
captor_boss_ptr:        defw enemy_data
captured_fighter_active: defb 0 ; 0=none, 1=docked in formation, 2=diving escort, 3=freed & descending
captured_fighter_x:     defb 0
captured_fighter_y:     defb 0
captured_old_x:         defb 0
captured_old_y:         defb 0
captured_spin:          defb 0

;; Challenging Stage Variables
is_challenging_stage:   defb 0
challenging_wave:       defb 0
challenging_hits:       defb 0
challenging_timer:      defb 0
challenging_spawn_cnt:  defb 0
challenging_active:     defb 0

;; Formation Animation & Sway Variables
flap_timer:             defb 0
global_anim:            defb 0
sway_timer:             defb 0
sway_dir:               defb 1
sway_offset:            defb 0
attack_timer:           defb 0

;; Stage Phase & Entry Wave Variables
stage_phase:            defb 0  ; 0 = Entry Phase, 1 = Attack Phase
entry_spawn_idx:        defb 0  ; Enemies spawned in entry (0..stage_enemy_total)
stage_enemy_total:      defb ENEMY_COUNT ; Active enemies for this stage (24 or 36)
;; Entrance pattern of this stage, copied from entry_pattern_tab
entry_order_ptr:        defw 0  ; Spawn order (slot numbers)
entry_starts_ptr:       defw 0  ; First spawn index of each entry group
entry_gap:              defb 0  ; Updates between entry spawns
entry_pairs:            defb 0  ; 1: enemies fly in side by side
entry_pattern:          defb 0  ; 0, 1, 2: entrance pattern 1, 2, 3
entry_spawn_timer:      defb 0  ; Delay between entry spawns
stage_watchdog:         defb 0  ; Frames with enemies alive but none on screen
entry_shooter_quota:    defb 0
entry_shooter_start:    defb 0
entry_shooter_size:     defb 0
entry_shooter_left:     defb 0
player_state_end:

PLAYER_STATE_SIZE equ player_state_end - player_state

;; Page 3 of video RAM uses 13 rows x 96 = 1248 bytes of each 2K raster
;; block, so #C4E0..#C7FF, #CCE0..#CFFF, ... are never shown or drawn to.
VRAM_GAP        equ PAGE3_BASE + (DISPLAY_ROWS - PAGE2_ROWS) * BYTES_PER_LINE
VRAM_GAP_SIZE   equ #800 - (DISPLAY_ROWS - PAGE2_ROWS) * BYTES_PER_LINE

;; Inactive player's state lives in the first gap.
PLAYER_SWAP_BUF equ VRAM_GAP
    assert PLAYER_STATE_SIZE <= VRAM_GAP_SIZE

;; The enemy table is per-player state too, but too large for the load image:
;; it lives in the second gap, and the inactive player's copy in the third.
;; Both are cleared by InitEnemies / SelectEntryShooters before use.
entry_shooter_flags equ VRAM_GAP + #800          ; ENEMY_COUNT bytes, by spawn order
;; Enemy data structure: ENEMY_COUNT enemies x ENEMY_SIZE bytes
;; [alive, type, x, y, old_x, old_y, anim_frame, base_x, state, hp, base_y, path, dive_speed, dive_speed_phase]
enemy_data      equ entry_shooter_flags + ENEMY_COUNT
ENEMY_STATE     equ entry_shooter_flags
ENEMY_STATE_SIZE equ ENEMY_COUNT * (ENEMY_SIZE + 1)
ENEMY_SWAP_BUF  equ VRAM_GAP + #1000
    assert ENEMY_STATE_SIZE <= VRAM_GAP_SIZE

;; Offset of a per-player variable inside the inactive player's copy
OTHER_PLAYER    equ PLAYER_SWAP_BUF - player_state

;; 2-player game control
two_player:             defb 0  ; 1 = 2-player game
active_player:          defb 0  ; 0 = player 1, 1 = player 2
initials_player:        defb 0  ; Next player to check for the Hall of Fame
player_out:             defb 0  ; 1 while showing "GAME OVER" for one player
hud_blink:              defb 0  ; Blink counter for the active player's label
results_drawn:          defb 0  ; Results screen on screen (stars stopped)

;; Title Screen state
is_title_screen:        defb 1
title_timer:            defb 0
