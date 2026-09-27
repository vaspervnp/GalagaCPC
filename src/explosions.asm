;; ============================================================================
;; Galaga CPC - Explosion Animation System
;; ============================================================================

;; ----------------------------------------------------------------------------
;; SpawnExplosion: Activate an explosion at screen coordinates (B, C)
;; Input:  B = X (0..79), C = Y (0..199)
;; Preserves: BC, DE, HL, IX, IY
;; ----------------------------------------------------------------------------
SpawnExplosion:
    push ix
    ld ix, explosion_data
    ld a, (ix+0)
    or a
    jr z, .found_slot0

    ld a, (ix+4)
    or a
    jr z, .found_slot1

    ld a, (ix+8)
    or a
    jr z, .found_slot2
    jr .no_slot

.found_slot2:
    ld de, 8
    add ix, de
    jr .init_slot

.found_slot1:
    ld de, 4
    add ix, de
    jr .init_slot

.found_slot0:
.init_slot:
    ld (ix+0), 1            ; active = 1
    ld (ix+1), b            ; true X coordinate
    ld (ix+2), c            ; true Y coordinate
    ld (ix+3), 0            ; timer = 0

.no_slot:
    pop ix
    ret

;; ----------------------------------------------------------------------------
;; UpdateExplosions: Animate all active explosions through 4 arcade frames
;; Frames: 1..6 (exp_1), 7..12 (exp_2), 13..18 (exp_3), 19..24 (exp_4)
;; Total duration = 24 frames (~0.48s at 50Hz)
;; ----------------------------------------------------------------------------
UpdateExplosions:
    ld ix, explosion_data
    ld b, MAX_EXPLOSIONS
.exp_loop:
    ld a, (ix+0)
    or a
    jr z, .next_exp

    ld a, (ix+3)
    inc a
    ld (ix+3), a
    cp 25
    jr nc, .finish_exp

    push bc
    cp 7
    jr c, .frame1           ; 1..6: Initial burst
    cp 13
    jr c, .frame2           ; 7..12: Expanding ring
    cp 19
    jr c, .frame3           ; 13..18: Full burst
    ld hl, explosion_4      ; 19..24: Fading particles
    jr .draw_exp
.frame1:
    ld hl, explosion_1
    jr .draw_exp
.frame2:
    ld hl, explosion_2
    jr .draw_exp
.frame3:
    ld hl, explosion_3

.draw_exp:
    ld b, (ix+1)
    ld c, (ix+2)
    call DrawSprite16x16
    pop bc
    jr .next_exp

.finish_exp:
    push bc
    ld b, (ix+1)
    ld c, (ix+2)
    call ClearSprite16x16
    pop bc
    ld (ix+0), 0

.next_exp:
    ld de, EXPLOSION_SIZE
    add ix, de
    djnz .exp_loop
    ret
