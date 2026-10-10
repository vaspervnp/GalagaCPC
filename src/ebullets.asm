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

    ;; Maximum number of enemy bullets on screen: Easy 2, one more once the
    ;; ramped stage reaches EXTRA_BULLET_STAGE. Medium / Hard / Hardest
    ;; start at 5 / 6 / 7 and gain one every 4 ramped stages up to 9 / 11 / 14.
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
    call EBulletLimit
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

    ;; Enemy fire is vertical until the difficulty's diagonal stage
    ;; (Easy 40, Medium 10, Hard 5, Hardest 1), then always drifts sideways.
    ld c, a
    push hl
    ld a, (difficulty_level)
    ld e, a
    ld d, 0
    ld hl, diagonal_fire_stage
    add hl, de
    ld a, (current_stage)
    cp (hl)
    pop hl
    ld a, c
    jr nc, .diagonal_fire
    xor a
    jr .store_dx

.diagonal_fire:
    ;; Aim at the fighter with the same straight bullet, at 15, 20, 25 or 30
    ;; degrees from vertical, whichever is closest to the fighter's direction.
    ;; Bullets fall 3 lines a frame and a byte is as wide as 4 lines are
    ;; tall, so tan(angle) = 4 * |dx| / dy.
    push hl
    ld d, 0                 ; D = 1: drift left
    or a
    jr nz, .aim_side_known
    ld a, (player_x)        ; Straight below: drift toward the screen centre
    cp PF_X_CENTER
    ld a, 0                 ; |dx| = 0 (flags kept)
    jr nc, .aim_dist_ready
    inc d
    jr .aim_dist_ready
.aim_side_known:
    jp p, .aim_dist_ready
    neg
    inc d
.aim_dist_ready:
    ld h, a
    ld l, 0                 ; HL = |dx| * 256
    ld a, (player_y)
    sub (ix+2)
    jr c, .aim_dy_min
    cp 8
    jr nc, .aim_dy_ok
.aim_dy_min:
    ld a, 8
.aim_dy_ok:
    ld c, a                 ; C = dy
    ;; Midpoints between the angles: tan 17.5 / 22.5 / 27.5 degrees = 0.315 /
    ;; 0.414 / 0.521, i.e. |dx| * 256 against dy * 20 / 27 / 33.
    ld e, EBULLET_DX_15
    ld a, 20
    call .at_least
    jr nc, .aim_ready
    ld e, EBULLET_DX_20
    ld a, 27
    call .at_least
    jr nc, .aim_ready
    ld e, EBULLET_DX_25
    ld a, 33
    call .at_least
    jr nc, .aim_ready
    ld e, EBULLET_DX_30
.aim_ready:
    ld a, e
    dec d
    jr nz, .aim_store
    neg
.aim_store:
    pop hl
    jr .store_dx

;; Carry set if HL >= C * A. Keeps C, DE, HL.
.at_least:
    push de
    push hl
    ld b, a
    ld hl, 0
    ld e, c
    ld d, 0
.at_least_mul:
    add hl, de
    djnz .at_least_mul
    ex de, hl               ; DE = dy * A
    pop hl
    push hl
    or a
    sbc hl, de
    ccf
    pop hl
    pop de
    ret

.store_dx:
    ld (ix+6), a            ; dx: signed sideways speed, 1/256 byte a frame
    ld (ix+7), #80          ; fraction of a byte, starting half way

    pop bc
    pop de
    pop ix
    ret

;; EBulletLimit: A = enemy bullets allowed on screen now (see SpawnEBullet).
;; Preserves: BC, DE, HL
EBulletLimit:
    push hl
    push de
    ld a, (difficulty_level)
    add a, a
    ld e, a
    ld d, 0
    ld hl, ebullet_limits
    add hl, de              ; HL -> [start, maximum] for this difficulty
    or a
    jr nz, .ramped
    call RampedStage        ; Easy: 2, then 3 from EXTRA_BULLET_STAGE
    cp EXTRA_BULLET_STAGE
    ld a, (hl)
    jr c, .done
    inc a
    jr .done
.ramped:
    call RampedStage
    dec a
    srl a
    srl a                   ; One more every 4 ramped stages
    add a, (hl)
    inc hl
    cp (hl)
    jr c, .done
    ld a, (hl)              ; Capped at the maximum
.done:
    pop de
    pop hl
    ret

;; [start, maximum] enemy bullets on screen, Easy..Hardest
ebullet_limits:
    defb 2, 3
    defb 5, 9
    defb 6, 11
    defb 7, MAX_EBULLETS

;; First stage with diagonal enemy fire, by difficulty (Easy..Hardest)
diagonal_fire_stage:
    defb 40, 10, 5, 1

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
    ;; 1. Update horizontal drift: |dx| is added to a fraction of a byte
    ;; twice (an update is two frames) and the bullet moves one byte each
    ;; time it carries over.
    ld a, (ix+6)            ; dx
    or a
    jr z, .no_x_drift
    ld c, a                 ; C: sign of dx
    jp p, .drift_abs
    neg
.drift_abs:
    ld e, a
    ld d, 0                 ; D = bytes to move
    add a, (ix+7)
    jr nc, .drift_frac2
    inc d
.drift_frac2:
    add a, e
    jr nc, .drift_frac_done
    inc d
.drift_frac_done:
    ld (ix+7), a
    ld a, d
    or a
    jr z, .no_x_drift
    bit 7, c
    jr z, .drift_move
    neg
.drift_move:
    add a, (ix+1)
    ld (ix+1), a

.check_x_bounds:
    ;; The 2-byte bullet stays inside the playfield (below 0 wraps to 255)
    ld a, (ix+1)
    cp PF_X0 + PF_W - 1
    jp nc, .kill_eb

.no_x_drift:
    ;; 2. Move down
    ld a, (ix+2)
    add a, 6                ; 6 scanlines an update
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
