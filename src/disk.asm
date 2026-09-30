;; ============================================================================
;; Persistent Hall of Fame storage on the raw score sector (track 0, #C5).
;; The routines run from low RAM because the game occupies almost all RAM below
;; the screen. Disk access is only attempted at boot and after initials entry.
;; ============================================================================

HS_DISK_ORG       equ #0040      ; Above the IM 1 jump at #0038
HS_DISK_SECTOR    equ #C5
HS_DISK_MAGIC_0   equ 'G'
HS_DISK_MAGIC_1   equ 'H'
HS_DISK_VERSION   equ 1
HS_DISK_DATA_SIZE equ 30
HS_DISK_DATA_OFF  equ 3
HS_DISK_SUM_OFF   equ HS_DISK_DATA_OFF+HS_DISK_DATA_SIZE

FDC_TO            equ 30000
FDC_STO           equ 50000
FDC_XTO           equ 50000
FDC_MSR           equ #FB7E
FDC_MOTOR         equ #FA7E

;; HighScoreSave failure codes, returned in A with Carry set.
HS_SAVE_FAILED    equ 0
HS_SAVE_PROTECTED equ 1
HS_SAVE_NO_DISK   equ 2

    org HS_DISK_ORG, disk_reloc_src

HS_DISK_BUFFER:
    defs 512, 0

;; Load only a valid, checksummed table; defaults remain intact on any failure.
HighScoreLoad:
    di
    call fdc_motor_on
    ld b, 3
.try:
    push bc
    call fdc_reinit
    call fdc_read_sector
    pop bc
    jr nc, .read_ok
    djnz .try
    jr .done
.read_ok:
    ;; The score sector is readable, so later saves can be attempted.
    ld a, 1
    ld (hs_disk_ok), a
    call hs_validate
    jr nz, .done
    ld hl, HS_DISK_BUFFER+HS_DISK_DATA_OFF
    ld de, top5_table
    ld bc, HS_DISK_DATA_SIZE
    ldir
    ld hl, (top5_table)
    ld (high_score), hl
    ld a, (top5_table+2)
    ld (high_score_hi), a
.done:
    call fdc_off
    ret

;; Write the whole table, then read it back before reporting success.
;; Skip saving when the boot-time load found no disk (e.g. a tape copy).
HighScoreSave:
    ld a, (hs_disk_ok)
    or a
    jr nz, .have_disk
    ld a, HS_SAVE_NO_DISK
    scf
    ret
.have_disk:
    di
    ld hl, HS_DISK_BUFFER
    ld de, HS_DISK_BUFFER+1
    ld bc, 511
    ld (hl), 0
    ldir
    ld a, HS_DISK_MAGIC_0
    ld (HS_DISK_BUFFER), a
    ld a, HS_DISK_MAGIC_1
    ld (HS_DISK_BUFFER+1), a
    ld a, HS_DISK_VERSION
    ld (HS_DISK_BUFFER+2), a
    ld hl, top5_table
    ld de, HS_DISK_BUFFER+HS_DISK_DATA_OFF
    ld bc, HS_DISK_DATA_SIZE
    ldir
    ld hl, HS_DISK_BUFFER+HS_DISK_DATA_OFF
    ld b, HS_DISK_DATA_SIZE
    call hs_checksum
    ld (HS_DISK_BUFFER+HS_DISK_SUM_OFF), a

    call fdc_motor_on
    call fdc_reinit
    call fdc_write_protected
    jr z, .write_allowed
    call fdc_off
    ld a, HS_SAVE_PROTECTED
    scf
    ei
    ret
.write_allowed:
    ld b, 3
.write_try:
    push bc
    call fdc_reinit
    call fdc_write_sector
    pop bc
    jr nc, .verify
    djnz .write_try
    jr .failed

.verify:
    call fdc_reinit
    call fdc_read_sector
    jr c, .failed
    call hs_validate
    jr nz, .failed
    ld hl, HS_DISK_BUFFER+HS_DISK_DATA_OFF
    ld de, top5_table
    ld b, HS_DISK_DATA_SIZE
.compare:
    ld a, (de)
    cp (hl)
    jr nz, .failed
    inc hl
    inc de
    djnz .compare
    call fdc_off
    xor a
    ei
    ret

.failed:
    call fdc_off
    ld a, HS_SAVE_FAILED
    scf
    ei
    ret

;; Sense Drive Status: NZ when ST3 reports the disk as write protected.
;; If the FDC does not answer, return Z and let the write report the failure.
fdc_write_protected:
    call fdc_sis_drain
    ld a, #04
    call send_fdc
    xor a
    call send_fdc
    call recv_fdc
    ld b, a
    ld a, (fdc_abort)
    or a
    jr nz, .unknown
    ld a, b
    and #40
    ret
.unknown:
    xor a
    ret

hs_validate:
    ld a, (HS_DISK_BUFFER)
    cp HS_DISK_MAGIC_0
    ret nz
    ld a, (HS_DISK_BUFFER+1)
    cp HS_DISK_MAGIC_1
    ret nz
    ld a, (HS_DISK_BUFFER+2)
    cp HS_DISK_VERSION
    ret nz
    ld hl, HS_DISK_BUFFER+HS_DISK_DATA_OFF
    ld b, HS_DISK_DATA_SIZE
    call hs_checksum
    ld hl, HS_DISK_BUFFER+HS_DISK_SUM_OFF
    cp (hl)
    ret

hs_checksum:
    xor a
.sum:
    add a, (hl)
    inc hl
    djnz .sum
    ret

fdc_read_sector:
    call fdc_seek
    ld a, (fdc_abort)
    or a
    jr nz, fdc_transfer_fail
    call fdc_sis_drain
    ld a, #46
    call fdc_rw_command
    ld hl, HS_DISK_BUFFER
    call fdc_exec_read
    jp fdc_result

fdc_write_sector:
    call fdc_seek
    ld a, (fdc_abort)
    or a
    jr nz, fdc_transfer_fail
    call fdc_sis_drain
    ld a, #45
    call fdc_rw_command
    ld hl, HS_DISK_BUFFER
    call fdc_exec_write
    jp fdc_result

fdc_transfer_fail:
    scf
    ret

fdc_rw_command:
    call send_fdc
    xor a
    call send_fdc
    xor a
    call send_fdc
    xor a
    call send_fdc
    ld a, HS_DISK_SECTOR
    call send_fdc
    ld a, 2
    call send_fdc
    ld a, HS_DISK_SECTOR
    call send_fdc
    ld a, #2A
    call send_fdc
    ld a, #FF
    call send_fdc
    ret

fdc_exec_write:
    ld de, FDC_XTO
    ld bc, FDC_MSR
.loop:
    in a, (c)
    bit 7, a
    jr nz, .ready
    dec de
    ld a, d
    or e
    jr nz, .loop
    jr fdc_io_abort
.ready:
    bit 5, a
    ret z
    ld a, (hl)
    inc c
    out (c), a
    dec c
    inc hl
    jr .loop

fdc_exec_read:
    ld de, FDC_XTO
    ld bc, FDC_MSR
.loop:
    in a, (c)
    bit 7, a
    jr nz, .ready
    dec de
    ld a, d
    or e
    jr nz, .loop
    jr fdc_io_abort
.ready:
    bit 5, a
    ret z
    inc c
    in a, (c)
    ld (hl), a
    dec c
    inc hl
    jr .loop

fdc_io_abort:
    ld a, 1
    ld (fdc_abort), a
    ret

fdc_result:
    xor a
    ld (fdc_st1), a
    ld (fdc_st2), a
    ld (fdc_rescnt), a
    ld a, (fdc_abort)
    or a
    jr nz, .fail
.wait:
    ld de, FDC_STO
.poll:
    ld bc, FDC_MSR
    in a, (c)
    bit 4, a
    jr z, .done
    and #C0
    cp #C0
    jr z, .read_result
    dec de
    ld a, d
    or e
    jr nz, .poll
    ld a, 1
    ld (fdc_abort), a
    jr .fail
.read_result:
    inc c
    in a, (c)
    ld b, a
    ld a, (fdc_rescnt)
    cp 12
    jr nc, .fail
    inc a
    ld (fdc_rescnt), a
    dec a
    jr z, .wait
    dec a
    jr nz, .next_result
    ld a, b
    ld (fdc_st1), a
    jr .wait
.next_result:
    dec a
    jr nz, .wait
    ld a, b
    ld (fdc_st2), a
    jr .wait
.done:
    ld a, (fdc_abort)
    or a
    jr nz, .fail
    ld a, (fdc_st1)
    and #37
    jr nz, .fail
    ld a, (fdc_st2)
    and #77
    jr nz, .fail
    or a
    ret
.fail:
    scf
    ret

fdc_reinit:
    xor a
    ld (fdc_abort), a
    ld b, 16
.finish_command:
    push bc
    ld bc, FDC_MSR
    in a, (c)
    and #D0
    cp #90
    jr nz, .flush
    xor a
    call send_fdc
    pop bc
    djnz .finish_command
    jr .drain_results
.flush:
    pop bc
.drain_results:
    ld b, 16
.flush_result:
    push bc
    ld bc, FDC_MSR
    in a, (c)
    and #C0
    cp #C0
    jr nz, .flush_done
    inc c
    in a, (c)
    pop bc
    djnz .flush_result
    jr .specify
.flush_done:
    pop bc
.specify:
    call fdc_sis_drain
    ld a, #03
    call send_fdc
    ld a, #8F
    call send_fdc
    ld a, #1F
    call send_fdc
    call fdc_sis_drain
    ld a, #07
    call send_fdc
    xor a
    call send_fdc
    jp fdc_wait_seek

fdc_seek:
    ld a, (fdc_abort)
    or a
    ret nz
    call fdc_sis_drain
    ld a, #0F
    call send_fdc
    xor a
    call send_fdc
    xor a
    call send_fdc
    jp fdc_wait_seek

fdc_wait_seek:
    push de
    ld de, FDC_STO
.loop:
    ld a, (fdc_abort)
    or a
    jr nz, .done
    ld a, #08
    call send_fdc
    call recv_fdc
    ld b, a
    and #C0
    cp #C0
    jr z, .ready_change
    bit 5, b
    jr nz, .seek_end
    dec de
    ld a, d
    or e
    jr nz, .loop
    ld a, 1
    ld (fdc_abort), a
.done:
    pop de
    ret
.ready_change:
    call recv_fdc
    jr .loop
.seek_end:
    call recv_fdc
    pop de
    ret

fdc_sis_drain:
    ld b, 8
.loop:
    push bc
    ld a, #08
    call send_fdc
    call recv_fdc
    cp #80
    jr z, .done
    call recv_fdc
    pop bc
    djnz .loop
    ret
.done:
    pop bc
    ret

send_fdc:
    push af
    ld a, (fdc_abort)
    or a
    jr nz, .aborted
    push de
    ld de, FDC_TO
.wait:
    ld bc, FDC_MSR
    in a, (c)
    add a, a
    jr nc, .timeout
    jp m, .timeout
    pop de
    pop af
    inc c
    out (c), a
    ret
.timeout:
    dec de
    ld a, d
    or e
    jr nz, .wait
    ld a, 1
    ld (fdc_abort), a
    pop de
.aborted:
    pop af
    ret

recv_fdc:
    ld a, (fdc_abort)
    or a
    ret nz
    push de
    ld de, FDC_TO
.wait:
    ld bc, FDC_MSR
    in a, (c)
    add a, a
    jr nc, .timeout
    jp p, .timeout
    pop de
    inc c
    in a, (c)
    ret
.timeout:
    dec de
    ld a, d
    or e
    jr nz, .wait
    ld a, 1
    ld (fdc_abort), a
    pop de
    ret

fdc_motor_on:
    xor a
    ld (fdc_abort), a
    ld bc, FDC_MOTOR
    ld a, 1
    out (c), a
    ld de, #04B0
.outer:
    ld b, 0
.inner:
    djnz .inner
    dec de
    ld a, d
    or e
    jr nz, .outer
    ret

fdc_off:
    push af
    ld bc, FDC_MOTOR
    xor a
    out (c), a
    pop af
    ret

fdc_abort:  defb 0
hs_disk_ok: defb 0
fdc_st1:    defb 0
fdc_st2:    defb 0
fdc_rescnt: defb 0
disk_code_end:
