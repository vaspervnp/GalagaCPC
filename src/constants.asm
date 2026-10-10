;; ============================================================================
;; Galaga CPC - Constants & Definitions
;; ============================================================================

MISSILE_SIZE    equ 6
MAX_MISSILES    equ 4

DEFAULT_PLAYER_Y equ 240                     ; Ship occupies scanlines 240..255
PLAYER_START_X  equ PF_X_CENTER - 4          ; 32: centred in the playfield


EBULLET_SIZE    equ 8
;; Diagonal enemy fire: sideways speed in 1/256 byte a frame for 15, 20,
;; 25 and 30 degrees from vertical (3 lines a frame; a byte is 4 lines
;; wide on screen): 256 * 3 * tan(angle) / 4.
EBULLET_DX_15   equ 51
EBULLET_DX_20   equ 70
EBULLET_DX_25   equ 90
EBULLET_DX_30   equ 111
MAX_EBULLETS    equ 14                       ; Hardest at its peak

ENEMY_COUNT     equ 36                       ; Arcade formation, rows of 8
ENEMY_SIZE      equ 14

;; Arcade-style formation: 4 Bosses, then two rows of 8 Goei and two rows
;; of 8 Zako, columns one sprite width apart, entering in 5 waves of 8.
FORMATION_COLS  equ 8
FORMATION_X0    equ PF_X0 + 4                ; Column 0; sway keeps 2..62
FORMATION_DX    equ 8
ENTRY_WAVE_SIZE equ 8                        ; Wave boundaries are multiples of 8
STAGE_ENEMIES_MIN  equ 16                    ; Stage 1: the first two waves
STAGE_ENEMIES_STEP equ 4                     ; Half a wave more per regular stage

;; Larger movement step for everything in flight: 3 lines a frame down or
;; up, and 1.5 bytes a frame sideways (1 and 2 on alternate frames), so the
;; flight paths keep their shape at 1.5x the speed.
FLIGHT_STEP_Y   equ 3

;; From this stage a diving Zako splits into three aliens mid-dive.
TRANSFORM_STAGE equ 10
TRANSFORM_Y     equ DEFAULT_PLAYER_Y - 140   ; Scanline where the split happens
TRANSFORM_SPREAD equ 10                      ; Bytes between the three aliens

;; Divers stop steering below this scanline and fly straight past the player.
DIVE_LOCK_Y     equ DEFAULT_PLAYER_Y - 62
;; Divers drop a bomb as they cross these scanlines.
DIVE_FIRE_Y1    equ DEFAULT_PLAYER_Y - 112
DIVE_FIRE_Y2    equ DEFAULT_PLAYER_Y - 72
DIVE_FIRE_Y3    equ DEFAULT_PLAYER_Y - 92  ; Third bomb from DIVE_FIRE3_STAGE
DIVE_FIRE3_STAGE equ 5
EXTRA_BULLET_STAGE equ 10              ; One more enemy bullet on screen
;; Divers that pass this scanline wrap back to the top of the playfield.
DIVE_WRAP_Y     equ SPRITE_Y_LIMIT

;; Tractor beam: the Boss hovers so the 64-line beam ends at the player's Y.
TRACTOR_HOVER_Y equ DEFAULT_PLAYER_Y - 80
TRACTOR_BEAM_Y  equ TRACTOR_HOVER_Y + 16
TRACTOR_BEAM_H  equ 64

;; Stage watchdog: remove enemies that stay outside the playfield this long.
STAGE_WATCHDOG_FRAMES equ 250

;; After losing a life, wait at least this long (and until every attacking
;; enemy is back in formation) before the next fighter appears.
RESPAWN_MIN_WAIT equ 100

;; Each active diver aims at its own lane; lanes are one sprite width apart
;; and centred on the player, so divers never share an attack path.
DIVE_LANES      equ 7
FORMATION_Y_MIN equ 52 + PF_OLD_DY           ; Formation rows (entry_enemy_defs):
FORMATION_Y_MAX equ 116 + PF_OLD_DY          ; 5 rows, 16 lines apart
FORMATION_ROWS  equ 5
    assert FORMATION_Y_MAX - FORMATION_Y_MIN == (FORMATION_ROWS - 1) * 16
DIVE_LANE_SPAN  equ (DIVE_LANES / 2) * 8    ; Centre lane to outer lane

;; Starfield: the star table is laid out for the full-width title screen.
STAR_GAME_DX    equ -10                      ; Table X 11..81 -> playfield 1..71
STAR_GAME_Y_END equ SPRITE_Y_LIMIT

;; Projectile limits
MISSILE_KILL_Y  equ PF_Y_TOP + 5             ; Missile removed before passing the top
EBULLET_KILL_Y  equ SPRITE_Y_LIMIT - 2       ; Enemy bullet removed near the bottom

;; Challenging stage results text, centred in the playfield
CH_RESULTS_X    equ 24 + PF_OLD_DX
CH_RESULTS_Y1   equ PF_TEXT_Y - 8         ; Character rows: fast redraw
CH_RESULTS_Y2   equ PF_TEXT_Y + 8

MAX_EXPLOSIONS  equ 3
EXPLOSION_SIZE  equ 4

NUM_STARS       equ 32

;; Enemy States:
STATE_FORMATION     equ 0
STATE_DIVING        equ 1
STATE_RETURNING     equ 2
STATE_TRACTOR_DIVE  equ 3
STATE_TRACTOR_BEAM  equ 4
STATE_CAPTURING     equ 5
STATE_ENTRY         equ 6

;; Stage Phases:
STAGE_PHASE_ENTRY   equ 0
STAGE_PHASE_ATTACK  equ 1
