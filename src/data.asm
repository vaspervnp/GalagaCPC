;; ============================================================================
;; Galaga CPC - Game Variables & Static Data Tables
;; Overscan Geometry Coordinates (Playfield X=8..87, Y=32..231)
;; ============================================================================

player_x:           defb 44
old_player_x:       defb 44
player_y:           defb DEFAULT_PLAYER_Y
old_player_y:       defb DEFAULT_PLAYER_Y
is_dual_fighter:    defb 0
player_invincible_timer: defb 0 ; Respawn invincibility countdown (100 frames = 2.0s at 50Hz)
fire_button_state:  defb 0
player_score:       defw 0
high_score:         defw 20000
player_lives:       defb 3
extra_life_awarded: defb 0
game_over:          defb 0
restart_debounce:   defb 0
game_over_timer:    defb 0
game_over_phase:    defb 0  ; 0=Game Over text, 1=Results Screen
enemy_fire_freeze:  defb 0  ; Arcade rule: diving boss kill stops enemy firing
transform_killed:   defb 0  ; Arcade rule: count kills in transform group

shots_fired:        defw 0  ; Arcade statistics: total missiles fired
shots_hit:          defw 0  ; Arcade statistics: total missiles that hit enemies

;; Tractor Beam & Captured Fighter Variables
tractor_beam_active:        defb 0
tractor_boss_x:             defb 0
tractor_boss_y:             defb 0
tractor_timer:              defb 0
tractor_anim:               defb 0
tractor_trigger_cnt:        defb 0
captor_boss_ptr:            defw enemy_data
capture_delay:              defb 0
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

;; Stage Phase & Entry Wave Variables
stage_phase:        defb 0  ; 0 = Entry Phase, 1 = Attack Phase
entry_spawn_idx:    defb 0  ; Enemies spawned in entry (0..ENEMY_COUNT)
entry_spawn_timer:  defb 0  ; Delay between entry spawns

;; Starfield: 12 stars [x, y, color, speed] inside Playfield (X=10..84, Y=34..228)
stars_data:
    defb 14, 45,  #AA, 1   ; White
    defb 28, 70,  #22, 2   ; Yellow
    defb 42, 100, #88, 1   ; Blue
    defb 56, 140, #44, 2   ; Red
    defb 72, 160, #AA, 1   ; White
    defb 80, 55,  #22, 2   ; Yellow
    defb 20, 180, #88, 1   ; Blue
    defb 36, 115, #44, 2   ; Red
    defb 50, 40,  #AA, 1   ; White
    defb 64, 85,  #22, 2   ; Yellow
    defb 76, 125, #88, 1   ; Blue
    defb 24, 205, #44, 2   ; Red

;; Initial Enemies (4 Bosses at Y=52, 8 Butterflies at Y=68/84, 8 Bees at Y=100/116)
;; Format: [alive, type, x, y, hp] - 5 bytes per enemy
initial_enemies:
    ;; 4 Boss Galagas (Row 1, Y=52):
    defb 1, 2, 26, 52, 2
    defb 1, 2, 38, 52, 2
    defb 1, 2, 50, 52, 2
    defb 1, 2, 62, 52, 2

    ;; 4 Goei Butterflies (Row 2, Y=68):
    defb 1, 1, 26, 68, 1
    defb 1, 1, 38, 68, 1
    defb 1, 1, 50, 68, 1
    defb 1, 1, 62, 68, 1

    ;; 4 Goei Butterflies (Row 3, Y=84):
    defb 1, 1, 26, 84, 1
    defb 1, 1, 38, 84, 1
    defb 1, 1, 50, 84, 1
    defb 1, 1, 62, 84, 1

    ;; 4 Zako Bees (Row 4, Y=100):
    defb 1, 0, 26, 100, 1
    defb 1, 0, 38, 100, 1
    defb 1, 0, 50, 100, 1
    defb 1, 0, 62, 100, 1

    ;; 4 Zako Bees (Row 5, Y=116):
    defb 1, 0, 26, 116, 1
    defb 1, 0, 38, 116, 1
    defb 1, 0, 50, 116, 1
    defb 1, 0, 62, 116, 1

;; Enemy data structure: 20 enemies x 12 bytes
;; [alive, type, x, y, old_x, old_y, anim_frame, base_x, state, hp, base_y, pad]
enemy_data:
    defs ENEMY_SIZE * ENEMY_COUNT, 0

;; Title Screen state
is_title_screen:        defb 1
title_timer:            defb 0
