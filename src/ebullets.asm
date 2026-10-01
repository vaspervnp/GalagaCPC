;; ============================================================================
;; Galaga CPC - Enemy Bullets Management
;; Playfield Y=PF_Y_TOP..EBULLET_KILL_Y (bottom of the overscan screen)
;; ============================================================================

SpawnEBullet:
    ;; Input: B = Enemy X, C = Enemy Y
    ;; Preserves: BC, DE, HL, IX, IY
    push ix
    push de
    push bc

    ;; Difficulty sets the maximum number of enemy bullets on screen:
    ;; Easy=2, Medium=3, Hard=4, Hardest=5, one more from EXTRA_BULLET_STAGE.
    ld ix, ebullet_data
    ld b, MAX_EBULLETS
    ld c, 0
.count_active_bullets:
    ld a, (ix+0)
    or a
    jr z, .next_active_bullet
    inc c
.next_active_bullet:
    ld de, EBULLET_SIZE
    add ix, de
    djnz .count_active_bullets
    ld a, (current_stage)
    cp EXTRA_BULLET_STAGE
    ccf                     ; Carry = 1 from EXTRA_BULLET_STAGE on
    ld a, (difficulty_level)
    adc a, 2
    cp c
    jr c, .bullet_limit_reached
    jr z, .bullet_limit_reached

    ;; Find free bullet slot in ebullet_data (MAX_EBULLETS slots)
    ld ix, ebullet_data
    ld b, MAX_EBULLETS
.find_eb_slot:
    ld a, (ix+0)
    or a
    jr z, .found_eb_slot
    ld de, EBULLET_SIZE
    add ix, de
    djnz .find_eb_slot
    pop bc
    pop de
    pop ix
    ret

.bullet_limit_reached:
    pop bc
    pop de
    pop ix
    ret                     ; No free bullet slot

.found_eb_slot:
    pop bc                  ; Restore B=enemy X, C=enemy Y
    push bc

    ld (ix+0), 1            ; active = 1
    ld a, b
    add a, 3
    ld (ix+1), a            ; x = enemy X + 3
    ld a, c
    add a, 14
    ld (ix+2), a            ; y = enemy Y + 14
    ld (ix+5), 0            ; has_old = 0

    ;; Calculate horizontal aiming dx based on target (player center) vs bullet X
    ld a, (is_dual_fighter)
    or a
    jr nz, .target_dual
    ld a, (player_x)
    add a, 3                ; Center of single fighter
    jr .got_target_x
.target_dual:
    ld a, (player_x)
    add a, 7                ; Center of dual fighter
.got_target_x:
    sub (ix+1)              ; A = Target_X - Bullet_X (signed)

    ;; Enemy fire remains vertical until stage 40, then always has diagonal drift.
    ld c, a
    ld a, (current_stage)
    cp 40
    ld a, c
    jr nc, .stage_40_diagonal
    xor a
    jr .store_dx

.stage_40_diagonal:
    or a
    jr z, .force_diagonal
    jp p, .diagonal_right
    neg
    cp 17
    jr c, .dx_gentle_left
    ld a, -2
    jr .store_dx

.diagonal_right:
    cp 17
    jr c, .dx_gentle_right
    ld a, 2
    jr .store_dx

.force_diagonal:
    ld a, (player_x)
    cp PF_X_CENTER
    jr c, .force_diagonal_left
    ld a, 1
    jr .store_dx
.force_diagonal_left:
    ld a, -1
    jr .store_dx

.dx_gentle_left:
    ld a, -1
    jr .store_dx

.dx_gentle_right:
    ld a, 1
    jr .store_dx

.store_dx:
    ld (ix+6), a            ; dx (-2, -1, 0, 1, 2)
    xor a
    ld (ix+7), a            ; phase = 0

    pop bc
    pop de
    pop ix
    ret

UpdateEBullets:
    ld ix, ebullet_data
    ld b, MAX_EBULLETS
.eb_loop:
    ld a, (ix+0)
    or a
    jp z, .next_eb

    ;; Erase old position
    ld a, (ix+5)
    or a
    jr z, .skip_erase_eb
    push bc
    ld b, (ix+3)
    ld c, (ix+4)
    call EraseEBullet
    pop bc

.skip_erase_eb:
    ;; 1. Update horizontal drift
    ld a, (ix+6)            ; dx
    or a
    jr z, .no_x_drift
    ld c, a                 ; C = dx
    inc (ix+7)              ; increment phase
    ld a, (ix+7)
    bit 0, a
    jr nz, .check_fast_drift

    ;; Even frame (phase & 1 == 0): apply step for all non-zero dx
    bit 7, c
    jr nz, .drift_left
    inc (ix+1)
    jr .check_x_bounds
.drift_left:
    dec (ix+1)
    jr .check_x_bounds

.check_fast_drift:
    ;; Odd frame (phase & 1 == 1): apply extra step only for fast (|dx| == 2)
    ld a, c
    cp 2
    jr z, .drift_fast_right
    cp -2
    jr nz, .no_x_drift
    dec (ix+1)
    jr .check_x_bounds
.drift_fast_right:
    inc (ix+1)

.check_x_bounds:
    ld a, (ix+1)
    cp PLAY_X_MIN
    jp c, .kill_eb
    cp PLAY_X_MAX
    jp nc, .kill_eb

.no_x_drift:
    ;; 2. Move down
    ld a, (ix+2)
    add a, 3                ; 3 scanlines/frame
    ld (ix+2), a
    cp EBULLET_KILL_Y       ; Stop at the bottom of the screen (bullet height 9)
    jp nc, .kill_eb

    ;; 3. Save old position
    ld a, (ix+1)
    ld (ix+3), a
    ld a, (ix+2)
    ld (ix+4), a
    ld (ix+5), 1

    ;; 4. Draw bullet at new position
    push bc
    ld b, (ix+1)
    ld c, (ix+2)
    call DrawEBullet
    pop bc
    jp .next_eb

.kill_eb:
    ;; Cleanly erase bullet before deactivating
    push bc
    ld a, (ix+5)
    or a
    jr z, .skip_kill_erase
    ld b, (ix+3)
    ld c, (ix+4)
    call EraseEBullet
.skip_kill_erase:
    pop bc
    ld (ix+0), 0
    ld (ix+5), 0

.next_eb:
    ld de, EBULLET_SIZE
    add ix, de
    dec b
    jp nz, .eb_loop
    ret

;; ----------------------------------------------------------------------------
;; Enemy Bullet Sprite: Mode 0 4-pixel (2-byte) x 9 scanlines
;; Exact sprite from assets/missilesmap.png (Bottom-Middle tile: Row 2, Col 1)
;; Red tip & shoulders (Pen 2), Blue wings (Pen 1), White core (Pen 15)
;; ----------------------------------------------------------------------------
enemy_bullet_sprite:
    defb #00, #08       ; Line 0: . . R . (Red tip)
    defb #00, #08       ; Line 1: . . R . (Red tip)
    defb #00, #08       ; Line 2: . . R . (Red tip)
    defb #00, #08       ; Line 3: . . R . (Red tip)
    defb #04, #0C       ; Line 4: . R R R (Red shoulders)
    defb #40, #EA       ; Line 5: . B W B (Blue wings, White core)
    defb #40, #C0       ; Line 6: . B B B (Blue wings)
    defb #00, #80       ; Line 7: . . B . (Blue tail)
    defb #00, #80       ; Line 8: . . B . (Blue tail)

;; ----------------------------------------------------------------------------
;; DrawEBullet: Draw 2-byte x 9-scanline enemy bullet at B=X, C=Y
;; Uses line_tab directly for fast, overscan-buffer safe drawing
;; ----------------------------------------------------------------------------
DrawEBullet:
    push bc
    push de
    push ix
    ld e, c
    ld d, 0
    sla e
    rl d
    ld ix, line_tab
    add ix, de                  ; IX = line_tab[Y]
    ld hl, enemy_bullet_sprite
    ld c, 9                     ; 9 scanlines
.deb_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .deb_nc
    inc d
.deb_nc:
    ld a, (hl) : ld (de), a : inc hl : inc de
    ld a, (hl) : ld (de), a : inc hl
    dec c
    jr nz, .deb_loop
    pop ix
    pop de
    pop bc
    ret

;; ----------------------------------------------------------------------------
;; EraseEBullet: Erase 2-byte x 9-scanline enemy bullet at B=X, C=Y
;; ----------------------------------------------------------------------------
EraseEBullet:
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
.eeb_loop:
    ld e, (ix+0)
    ld d, (ix+1)
    inc ix
    inc ix
    ld a, b
    add a, e
    ld e, a
    jr nc, .eeb_nc
    inc d
.eeb_nc:
    xor a
    ld (de), a
    inc de
    ld (de), a
    dec c
    jr nz, .eeb_loop
    pop ix
    pop de
    pop bc
    ret
