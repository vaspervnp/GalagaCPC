;; ============================================================================
;; Galaga CPC - Enemy Bullets Management
;; ============================================================================

SpawnEBullet:
    ;; Input: B = X, C = Y
    ;; Preserves: BC, DE, HL, IX, IY
    push ix
    push de
    ld ix, ebullet_data
    ld a, (ix+0)
    or a
    jr z, .found_eb0
    ld a, (ix+6)
    or a
    jr z, .found_eb1
    jr .no_eb_slot

.found_eb1:
    ld de, EBULLET_SIZE
    add ix, de

.found_eb0:
    ld (ix+0), 1            ; active = 1
    ld a, b
    add a, 3
    ld (ix+1), a            ; x = enemy X + 3
    ld a, c
    add a, 14
    ld (ix+2), a            ; y = enemy Y + 14
    ld (ix+5), 0            ; has_old = 0

.no_eb_slot:
    pop de
    pop ix
    ret

UpdateEBullets:
    ld ix, ebullet_data
    ld b, MAX_EBULLETS
.eb_loop:
    ld a, (ix+0)
    or a
    jr z, .next_eb

    ;; Erase old
    ld a, (ix+5)
    or a
    jr z, .skip_erase_eb
    push bc
    ld b, (ix+3)
    ld c, (ix+4)
    call EraseEBullet
    pop bc

.skip_erase_eb:
    ;; Move down
    ld a, (ix+2)
    add a, 3                ; 3 scanlines/frame
    ld (ix+2), a
    cp 185
    jr nc, .kill_eb

    ;; Save old
    ld a, (ix+1)
    ld (ix+3), a
    ld a, (ix+2)
    ld (ix+4), a
    ld (ix+5), 1

    ;; Draw
    push bc
    ld b, (ix+1)
    ld c, (ix+2)
    call DrawEBullet
    pop bc
    jr .next_eb

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
    djnz .eb_loop
    ret

DrawEBullet:
    call GetScreenAddr
    ex de, hl
    ld a, #44               ; Red bullet (Pen 2)
    ld (de), a
    call NextScanlineDE
    ld a, #44
    ld (de), a
    call NextScanlineDE
    ld a, #44
    ld (de), a
    ret

EraseEBullet:
    call GetScreenAddr
    ex de, hl
    xor a
    ld (de), a
    call NextScanlineDE
    xor a
    ld (de), a
    call NextScanlineDE
    xor a
    ld (de), a
    ret
