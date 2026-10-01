;; ============================================================================
;; Galaga CPC - Game Variables & Static Data Tables
;; Playfield X=0..71 (HUD column X=72..95), sprite Y=PF_Y_TOP..SPRITE_Y_LIMIT-1
;; ============================================================================

player_x:           defb PLAYER_START_X
old_player_x:       defb PLAYER_START_X
player_y:           defb DEFAULT_PLAYER_Y
old_player_y:       defb DEFAULT_PLAYER_Y
is_dual_fighter:    defb 0
player_invincible_timer: defb 0 ; Respawn invincibility countdown (100 frames = 2.0s at 50Hz)
fire_button_state:  defb 0
player_score:           defw 0
player_score_hi:        defb 0
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
player_lives:           defb 3
extra_life_count:       defb 0  ; Milestone count: 1=20k, 2=70k, 3=140k...
next_extra_life_lo:     defw 20000
next_extra_life_hi:     defb 0
game_over:          defb 0
pause_active:       defb 0
restart_debounce:   defb 0
game_over_timer:    defb 0
game_over_phase:    defb 0  ; 0=Game Over text, 1=Results Screen
enemy_fire_freeze:      defb 0  ; Arcade rule: diving boss kill stops enemy firing
transform_killed:       defb 0  ; Arcade rule: count kills in transform group
attack_cycle:           defb 0  ; Arcade attack rotation (0=Bee, 1=Butterfly, 2=Boss, 3=Bee)
transform_trigger_cnt:  defb 0  ; Cadence counter for Transform Trios

;; Floating Bonus Score Popup Variables
bonus_score_timer:      defb 0  ; Active if > 0 (6 frames duration)
bonus_score_x:          defb 0
bonus_score_y:          defb 0
bonus_score_old_x:      defb 0
bonus_score_old_y:      defb 0
bonus_score_ptr:        defw 0  ; Pointer to bonus score sprite

shots_fired:        defw 0  ; Arcade statistics: total missiles fired
shots_hit:          defw 0  ; Arcade statistics: total missiles that hit enemies

;; Tractor Beam & Captured Fighter Variables
tractor_beam_active:        defb 0
tractor_boss_x:             defb 0
tractor_boss_y:             defb 0
tractor_beam_x:             defb 0
tractor_beam_drawn:         defb 0
tractor_timer:              defb 0
tractor_anim:               defb 0
tractor_trigger_cnt:        defb 0
captor_boss_ptr:            defw enemy_data
capture_delay:              defb 0
respawn_wait:               defb 0  ; Frames until the next fighter after losing a life
captured_fighter_active:    defb 0  ; 0=none, 1=docked in formation, 2=diving escort, 3=freed & descending
captured_fighter_x:         defb 0
captured_fighter_y:         defb 0
captured_old_x:             defb 0
captured_old_y:             defb 0
captured_spin:              defb 0

;; Challenging Stage Variables
is_challenging_stage:       defb 0
challenging_wave:           defb 0
challenging_hits:           defb 0
challenging_timer:          defb 0
challenging_spawn_cnt:      defb 0
challenging_active:         defb 0

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

;; Formation Animation & Sway Variables
flap_timer:         defb 0
global_anim:        defb 0
sway_timer:         defb 0
sway_dir:           defb 1
sway_offset:        defb 0
attack_timer:       defb 0
dive_phase:         defb 0

;; Stage Phase & Entry Wave Variables
stage_phase:        defb 0  ; 0 = Entry Phase, 1 = Attack Phase
entry_spawn_idx:    defb 0  ; Enemies spawned in entry (0..stage_enemy_total)
stage_enemy_total:  defb 28 ; Active enemies for this stage (14..28, grows by stage)
entry_spawn_timer:  defb 0  ; Delay between entry spawns
random_seed:        defb 1
star_draw_x:        defb 0  ; Screen X of the star being updated
hud_in_column:      defb 0  ; 1 = in-game HUD column, 0 = title screen top HUD
entry_shooter_quota: defb 0
entry_shooter_start: defb 0
entry_shooter_size:  defb 0
entry_shooter_left:  defb 0
entry_shooter_flags:
    defs ENEMY_COUNT, 0

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

;; Initial Enemies (28 enemies: 4 Bosses, 12 Butterflies, 12 Bees)
;; Format: [alive, type, x, y, hp] - 5 bytes per enemy
initial_enemies:
    ;; 4 Boss Galagas (Row 1, Y=52):
    defb 1, 2, 27, 52, 2
    defb 1, 2, 37, 52, 2
    defb 1, 2, 47, 52, 2
    defb 1, 2, 57, 52, 2

    ;; 6 Goei Butterflies (Row 2, Y=68):
    defb 1, 1, 17, 68, 1
    defb 1, 1, 27, 68, 1
    defb 1, 1, 37, 68, 1
    defb 1, 1, 47, 68, 1
    defb 1, 1, 57, 68, 1
    defb 1, 1, 67, 68, 1

    ;; 6 Goei Butterflies (Row 3, Y=84):
    defb 1, 1, 17, 84, 1
    defb 1, 1, 27, 84, 1
    defb 1, 1, 37, 84, 1
    defb 1, 1, 47, 84, 1
    defb 1, 1, 57, 84, 1
    defb 1, 1, 67, 84, 1

    ;; 6 Zako Bees (Row 4, Y=100):
    defb 1, 0, 17, 100, 1
    defb 1, 0, 27, 100, 1
    defb 1, 0, 37, 100, 1
    defb 1, 0, 47, 100, 1
    defb 1, 0, 57, 100, 1
    defb 1, 0, 67, 100, 1

    ;; 6 Zako Bees (Row 5, Y=116):
    defb 1, 0, 17, 116, 1
    defb 1, 0, 27, 116, 1
    defb 1, 0, 37, 116, 1
    defb 1, 0, 47, 116, 1
    defb 1, 0, 57, 116, 1
    defb 1, 0, 67, 116, 1

;; Enemy data structure: 28 enemies x ENEMY_SIZE bytes
;; [alive, type, x, y, old_x, old_y, anim_frame, base_x, state, hp, base_y, path, dive_speed, dive_speed_phase]
enemy_data:
    defs ENEMY_SIZE * ENEMY_COUNT, 0

;; Title Screen state
is_title_screen:        defb 1
title_timer:            defb 0
