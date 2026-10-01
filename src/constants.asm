;; ============================================================================
;; Galaga CPC - Constants & Definitions
;; ============================================================================

MISSILE_SIZE    equ 6
MAX_MISSILES    equ 4

DEFAULT_PLAYER_Y equ 240                     ; Ship occupies scanlines 240..255
PLAYER_START_X  equ PF_X_CENTER - 4          ; 32: centred in the playfield


EBULLET_SIZE    equ 8
MAX_EBULLETS    equ 5

ENEMY_COUNT     equ 28
ENEMY_SIZE      equ 14

;; Divers stop steering below this scanline and fly straight past the player.
DIVE_LOCK_Y     equ DEFAULT_PLAYER_Y - 62
;; Divers drop a bomb at these scanlines (even: divers move 2 lines a frame).
DIVE_FIRE_Y1    equ DEFAULT_PLAYER_Y - 112
DIVE_FIRE_Y2    equ DEFAULT_PLAYER_Y - 72
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
DIVE_LANE_SPAN  equ (DIVE_LANES / 2) * 8    ; Centre lane to outer lane

;; Starfield: the star table is laid out for the full-width title screen.
STAR_GAME_DX    equ -10                      ; Table X 11..81 -> playfield 1..71
STAR_GAME_Y_END equ SPRITE_Y_LIMIT

;; Projectile limits
MISSILE_KILL_Y  equ PF_Y_TOP + 5             ; Missile removed before passing the top
EBULLET_KILL_Y  equ SPRITE_Y_LIMIT - 2       ; Enemy bullet removed near the bottom

;; Challenging stage results text, centred in the playfield
CH_RESULTS_X    equ 24 + PF_OLD_DX
CH_RESULTS_Y1   equ PF_TEXT_Y - 10
CH_RESULTS_Y2   equ PF_TEXT_Y + 6

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
