;; ============================================================================
;; Galaga CPC - Constants & Definitions
;; ============================================================================

MISSILE_SIZE    equ 6
MAX_MISSILES    equ 4

DEFAULT_PLAYER_Y equ 222


EBULLET_SIZE    equ 8
MAX_EBULLETS    equ 8

ENEMY_COUNT     equ 28
ENEMY_SIZE      equ 14

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
