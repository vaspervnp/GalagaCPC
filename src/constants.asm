;; ============================================================================
;; Galaga CPC - Constants & Definitions
;; ============================================================================

MISSILE_SIZE    equ 6
MAX_MISSILES    equ 4

DEFAULT_PLAYER_Y equ 222


EBULLET_SIZE    equ 8
MAX_EBULLETS    equ 5

ENEMY_COUNT     equ 28
ENEMY_SIZE      equ 14

;; Divers stop steering below this scanline and fly straight past the player.
DIVE_LOCK_Y     equ 160

;; Each active diver aims at its own lane; lanes are one sprite width apart
;; and centred on the player, so divers never share an attack path.
DIVE_LANES      equ 7
DIVE_LANE_SPAN  equ (DIVE_LANES / 2) * 8    ; Centre lane to outer lane

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
