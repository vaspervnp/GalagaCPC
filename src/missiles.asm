;; ============================================================================
;; Galaga CPC - Player Missiles Management
;; Overscan Geometry (Playfield Y=32..231, Player Y=210)
;; ============================================================================

SpawnMissile:
    ld a, (is_dual_fighter)
    or a
    jr nz, SpawnDualMissiles

    ;; Single Fighter Missile: Find 1 free slot (max 2 active missiles)
    push ix
    push de
    push bc
    ld ix, missile_data
    ld b, 2                 ; Max 2 on screen for single fighter
.find_slot_single:
    ld a, (ix+0)
    or a
    jr z, .found_single_slot
    ld de, MISSILE_SIZE
    add ix, de
    djnz .find_slot_single
    pop bc
    pop de
    pop ix
    ret

.found_single_slot:
    ld (ix+0), 1
    ld a, (player_x)
    add a, 3
    ld (ix+1), a            ; x
    ld (ix+2), 204          ; y (player_y 210 - 6)
    ld (ix+5), 0            ; has_old = 0
    call PlaySoundShot
    pop bc
    pop de
    pop ix
    ret

SpawnDualMissiles:
    ;; Dual Fighter Missiles: Up to 4 active missiles on screen
    push ix
    push de
    push bc

    ;; Find 1st free slot (Left fighter)
    ld ix, missile_data
    ld b, MAX_MISSILES
.find_d1:
    ld a, (ix+0)
    or a
    jr z, .found_d1
    ld de, MISSILE_SIZE
    add ix, de
    djnz .find_d1
    pop bc
    pop de
    pop ix
    ret

.found_d1:
    ld (ix+0), 1
    ld a, (player_x)
    add a, 3                ; Left fighter barrel
    ld (ix+1), a
    ld (ix+2), 204
    ld (ix+5), 0

    ;; Find 2nd free slot (Right fighter)
    ld ix, missile_data
    ld b, MAX_MISSILES
.find_d2:
    ld a, (ix+0)
    or a
    jr z, .found_d2
    ld de, MISSILE_SIZE
    add ix, de
    djnz .find_d2
    jr .dual_fired_one

.found_d2:
    ld (ix+0), 1
    ld a, (player_x)
    add a, 11               ; Right fighter barrel
    ld (ix+1), a
    ld (ix+2), 204
    ld (ix+5), 0

.dual_fired_one:
    call PlaySoundShot
    pop bc
    pop de
    pop ix
    ret


UpdateMissiles:
    ld ix, missile_data
    ld b, MAX_MISSILES
.missile_loop:
    ld a, (ix+0)
    or a
    jr z, .next_slot

    ;; 1. Erase old missile
    ld a, (ix+5)
    or a
    jr z, .skip_erase
    push bc
    ld b, (ix+3)
    ld c, (ix+4)
    call EraseMissile
    pop bc

.skip_erase:
    ;; 2. Move missile up
    ;; Safety top boundary: scanlines 0..31 are Upper Border HUD.
    ;; If Y < 34, kill before entering HUD!
    ld a, (ix+2)
    cp 34
    jr c, .kill_missile

    sub 5                   ; 5 scanlines per frame
    ld (ix+2), a

    ;; 3. Save old position
    ld a, (ix+1)
    ld (ix+3), a
    ld a, (ix+2)
    ld (ix+4), a
    ld (ix+5), 1

    ;; 4. Draw missile
    push bc
    ld b, (ix+1)
    ld c, (ix+2)
    call DrawMissile
    pop bc
    jr .next_slot

.kill_missile:
    ld (ix+0), 0
    ld (ix+5), 0

.next_slot:
    ld de, MISSILE_SIZE
    add ix, de
    djnz .missile_loop
    ret

;; ----------------------------------------------------------------------------
;; DrawMissile: Draw 4-scanline missile at B=X, C=Y
;; Uses line_tab directly for overscan buffer safety
;; ----------------------------------------------------------------------------
DrawMissile:
    push bc
    call GetScreenAddr
    ld (hl), #FF            ; White tip
    inc c
    call GetScreenAddr
    ld (hl), #CC            ; Yellow body
    inc c
    call GetScreenAddr
    ld (hl), #CC            ; Yellow body
    inc c
    call GetScreenAddr
    ld (hl), #0C            ; Red thruster
    pop bc
    ret

;; ----------------------------------------------------------------------------
;; EraseMissile: Erase 4-scanline missile at B=X, C=Y
;; ----------------------------------------------------------------------------
EraseMissile:
    push bc
    call GetScreenAddr
    ld (hl), 0
    inc c
    call GetScreenAddr
    ld (hl), 0
    inc c
    call GetScreenAddr
    ld (hl), 0
    inc c
    call GetScreenAddr
    ld (hl), 0
    pop bc
    ret
