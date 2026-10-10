;; ============================================================================
;; Galaga CPC - Player Missiles Management
;; Playfield Y=PF_Y_TOP..SPRITE_Y_LIMIT-1, Player Y=DEFAULT_PLAYER_Y
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
    ld (ix+2), DEFAULT_PLAYER_Y - 6 ; y (player_y - 6)
    ld (ix+5), 0            ; has_old = 0
    ld hl, (shots_fired)
    inc hl
    ld (shots_fired), hl
    call PlaySoundShot
    pop bc
    pop de
    pop ix
    ret

SpawnDualMissiles:
    ;; Dual Fighter Missiles: Up to 4 active missiles on screen
    ;; Left ship fires from left barrel (player_x + 3) using Slots 0..1 (max 2 active)
    ;; Right ship fires from right barrel (player_x + 11) using Slots 2..3 (max 2 active)
    push ix
    push de
    push bc

    ld c, 0                     ; C = count of missiles fired in this shot (0..2)

    ;; 1. Check Left Fighter (Slots 0..1)
    ld ix, missile_data
    ld b, 2
.find_left_slot:
    ld a, (ix+0)
    or a
    jr z, .found_left_slot
    ld de, MISSILE_SIZE
    add ix, de
    djnz .find_left_slot
    jr .check_right_fighter     ; Left fighter already has 2 active missiles

.found_left_slot:
    ld (ix+0), 1
    ld a, (player_x)
    add a, 3                    ; Left fighter barrel
    ld (ix+1), a
    ld (ix+2), DEFAULT_PLAYER_Y - 6
    ld (ix+5), 0
    ld hl, (shots_fired)
    inc hl
    ld (shots_fired), hl
    inc c

.check_right_fighter:
    ;; 2. Check Right Fighter (Slots 2..3)
    ld ix, missile_data + (2 * MISSILE_SIZE)
    ld b, 2
.find_right_slot:
    ld a, (ix+0)
    or a
    jr z, .found_right_slot
    ld de, MISSILE_SIZE
    add ix, de
    djnz .find_right_slot
    jr .dual_done               ; Right fighter already has 2 active missiles

.found_right_slot:
    ld (ix+0), 1
    ld a, (player_x)
    add a, 11                   ; Right fighter barrel
    ld (ix+1), a
    ld (ix+2), DEFAULT_PLAYER_Y - 6
    ld (ix+5), 0
    ld hl, (shots_fired)
    inc hl
    ld (shots_fired), hl
    inc c

.dual_done:
    ;; If at least one fighter fired, play sound
    ld a, c
    or a
    jr z, .no_dual_fired
    call PlaySoundShot

.no_dual_fired:
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
    ;; Remove the missile before it moves past the top of the playfield.
    ld a, (ix+2)
    cp MISSILE_KILL_Y
    jr c, .kill_missile

    sub 10                  ; 10 scanlines an update
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
;; Player Missile Sprite: Mode 0 4-pixel (2-byte) x 9 scanlines
;; Exact sprite from assets/missilesmap.png (Top-Middle tile: Row 0, Col 1)
;; Blue tip & wings (Pen 1), White core (Pen 15), Red thruster tail (Pen 2)
;; ----------------------------------------------------------------------------
player_missile_sprite:
    defb #00, #80       ; Line 0: . . B . (Blue tip)
    defb #00, #80       ; Line 1: . . B . (Blue tip)
    defb #40, #C0       ; Line 2: . B B B (Blue wings)
    defb #40, #EA       ; Line 3: . B W B (Blue wings, White core)
    defb #40, #EA       ; Line 4: . B W B (Blue wings, White core)
    defb #00, #08       ; Line 5: . . R . (Red thruster)
    defb #00, #08       ; Line 6: . . R . (Red thruster)
    defb #00, #08       ; Line 7: . . R . (Red thruster)
    defb #00, #08       ; Line 8: . . R . (Red thruster)

;; ----------------------------------------------------------------------------
;; DrawMissile: Draw 2-byte x 9-scanline missile at B=X, C=Y
;; Uses line_tab directly for fast, overscan-buffer safe drawing
;; ----------------------------------------------------------------------------
DrawMissile:
    push bc
    push de
    push ix
    ld e, c
    ld d, 0
    sla e
    rl d
    ld ix, line_tab
    add ix, de                  ; IX = line_tab[Y]
    ld hl, player_missile_sprite
    ld c, 9                     ; 9 scanlines
.dm_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .dm_nc
    inc d
.dm_nc:
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl
    dec c
    jr nz, .dm_loop
    pop ix
    pop de
    pop bc
    ret

;; ----------------------------------------------------------------------------
;; EraseMissile: Erase 2-byte x 9-scanline missile at B=X, C=Y
;; ----------------------------------------------------------------------------
EraseMissile:
    push bc
    push de
    push ix
    ld e, c
    ld d, 0
    sla e
    rl d
    ld ix, line_tab
    add ix, de                  ; IX = line_tab[Y]
    ld c, 9                     ; 9 scanlines
.em_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .em_nc
    inc d
.em_nc:
    xor a
    ld (de), a
    inc de
    ld (de), a
    dec c
    jr nz, .em_loop
    pop ix
    pop de
    pop bc
    ret

