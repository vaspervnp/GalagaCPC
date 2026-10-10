;; ============================================================================
;; Galaga CPC - Floating Bonus Score Popups
;; Displays floating score numbers (150, 400, 800, 1000, 1600, 2000, 3000)
;; for 6 frames at the explosion position, floating 1 pixel up every 2 frames
;; ============================================================================

    include "bonus_sprites.asm"

BONUS_150   equ 0
BONUS_400   equ 1
BONUS_800   equ 2
BONUS_1000  equ 3
BONUS_1600  equ 4
BONUS_2000  equ 5
BONUS_3000  equ 6

BONUS_SCORE_W   equ 10  ; 10 bytes wide (20 Mode 0 pixels)
BONUS_SCORE_H   equ 8   ; 8 scanlines high

;; ----------------------------------------------------------------------------
;; DrawBonusScore: Draw 10-byte wide x 8 scanlines bonus score sprite
;; Input:  B = X (byte offset), C = Y (scanline), HL = pointer to sprite (80 bytes)
;; Preserves: BC
;; ----------------------------------------------------------------------------
DrawBonusScore:
    push ix
    push bc
    push hl
    ld e, c
    ld d, 0
    sla e
    rl d                ; DE = Y * 2
    ld ix, line_tab
    add ix, de          ; IX = line_tab pointer
    pop hl              ; HL = sprite data
    ld c, BONUS_SCORE_H ; 8 scanlines
.dbs_line:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .dbs_nc
    inc d
.dbs_nc:
    ;; Transfer 10 bytes from HL to DE
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl : inc de
    dec c
    jr nz, .dbs_line
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; ClearBonusScore: Erase 10-byte wide x 8 scanlines bonus score area with black
;; Input:  B = X (byte offset), C = Y (scanline)
;; Preserves: BC
;; ----------------------------------------------------------------------------
ClearBonusScore:
    push ix
    push bc
    ld e, c
    ld d, 0
    sla e
    rl d                ; DE = Y * 2
    ld ix, line_tab
    add ix, de
    ld c, BONUS_SCORE_H
.cbs_line:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .cbs_nc
    inc d
.cbs_nc:
    ex de, hl
    xor a
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    ld (hl), a : inc hl : ld (hl), a : inc hl
    dec c
    jr nz, .cbs_line
    pop bc
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; TriggerBonusScore:
;; Input:  A = bonus type (0..6: BONUS_150, BONUS_400, etc.)
;;         B = explosion X (0..80)
;;         C = explosion Y (34..230)
;; ----------------------------------------------------------------------------
TriggerBonusScore:
    ;; 1. Erase any currently active bonus score popup first
    push af
    push bc
    ld a, (bonus_score_timer)
    or a
    jr z, .no_prev_bonus
    ld a, (bonus_score_old_x)
    ld b, a
    ld a, (bonus_score_old_y)
    ld c, a
    call ClearBonusScore
.no_prev_bonus:
    pop bc                  ; Restore B = explosion X, C = explosion Y
    pop af                  ; Restore A = bonus type

    ;; 2. Look up sprite pointer from bonus_sprites_tab
    push bc                 ; Keep B=X, C=Y safe on stack
    add a, a
    ld l, a
    ld h, 0
    ld de, bonus_sprites_tab
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld (bonus_score_ptr), de
    pop bc                  ; Restore B=X, C=Y

    ;; 3. Center horizontally: shift 1 byte left from enemy X (width is 10 vs 8)
    ld a, b
    dec a
    cp PLAY_X_MIN
    jr nc, .tbs_x_min
    ld a, PLAY_X_MIN
.tbs_x_min:
    cp PLAY_X_MAX - 3
    jr c, .tbs_x_max
    ld a, PLAY_X_MAX - 3
.tbs_x_max:
    ld (bonus_score_x), a
    ld (bonus_score_old_x), a

    ;; 4. Center vertically: Y = enemy Y + 4
    ld a, c
    add a, 4
    ld (bonus_score_y), a
    ld (bonus_score_old_y), a

    ;; 5. Initialize active timer: 16 frames duration
    ld a, 8
    ld (bonus_score_timer), a

    ;; 6. Draw initial bonus score sprite immediately!
    ld a, (bonus_score_x)
    ld b, a
    ld a, (bonus_score_y)
    ld c, a
    ld hl, (bonus_score_ptr)
    call DrawBonusScore
    ret

;; ----------------------------------------------------------------------------
;; UpdateBonusScore: Called once per frame in GameLoop
;; Advances floating bonus score popup for 16 frames, floating 1 pixel up every 2 frames
;; ----------------------------------------------------------------------------
UpdateBonusScore:
    ld a, (bonus_score_timer)
    or a
    ret z

    ;; 1. Erase at old position
    ld a, (bonus_score_old_x)
    ld b, a
    ld a, (bonus_score_old_y)
    ld c, a
    call ClearBonusScore

    ;; 2. Decrement timer
    ld a, (bonus_score_timer)
    dec a
    ld (bonus_score_timer), a
    ret z                   ; Expired after 16 frames!

    ;; 3. Float 1 line upward every update
    ld hl, bonus_score_y
    dec (hl)
.no_float_up:

    ;; 4. Update old coordinates
    ld a, (bonus_score_x)
    ld (bonus_score_old_x), a
    ld a, (bonus_score_y)
    ld (bonus_score_old_y), a

    ;; 5. Draw at new position
    ld a, (bonus_score_x)
    ld b, a
    ld a, (bonus_score_y)
    ld c, a
    ld hl, (bonus_score_ptr)
    call DrawBonusScore
    ret
