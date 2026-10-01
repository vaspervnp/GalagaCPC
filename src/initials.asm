;; ============================================================================
;; Galaga CPC - Hall of Fame & High Score Initials Entry (Top 5)
;; Interactive 3-letter initials entry & Title Screen Hall of Fame Display
;; ============================================================================

rank_strings:
    defb "1ST", 0
    defb "2ND", 0
    defb "3RD", 0
    defb "4TH", 0
    defb "5TH", 0

str_top5_heroes_hdr:
    defw f_c_T, f_c_O, f_c_P, f_c_SPACE, f_c_5, f_c_SPACE, f_c_H, f_c_E, f_c_R, f_c_O, f_c_E, f_c_S, 0

str_hall_of_fame_hdr:
    defw f_c_H, f_c_A, f_c_L, f_c_L, f_c_SPACE, f_c_O, f_c_F, f_c_SPACE, f_c_F, f_c_A, f_c_M, f_c_E, 0

str_great_score:
    defb "GREAT SCORE!", 0

str_enter_initials:
    defb "ENTER INITIALS", 0

str_rank_label:
    defb "RANK  ", 0

str_score_label:
    defb "SCORE ", 0

str_registered:
    defb "REGISTERED!", 0

str_disk_save_failed:
    defb "DISK SAVE FAILED", 0

str_disk_protected:
    defb "WRITE PROTECTED", 0

str_disk_missing:
    defb "NO DISK FOUND", 0

;; ----------------------------------------------------------------------------
;; GetRankStringPtr: Return HL = pointer to "1ST", "2ND", etc. for rank A (0..4)
;; ----------------------------------------------------------------------------
GetRankStringPtr:
    and 7
    ld l, a
    ld h, 0
    add hl, hl          ; *2
    add hl, hl          ; *4 (each string is 4 bytes: 3 chars + null)
    ld de, rank_strings
    add hl, de
    ret

;; ----------------------------------------------------------------------------
;; ComparePlayerWithEntry
;; Input:  DE = pointer to 6-byte entry in top5_table (DE+0..1: lo word, DE+2: hi)
;; Output: Carry SET if player_score <= entry
;;         Carry CLEAR if player_score > entry
;; Destroys: AF, BC, HL
;; ----------------------------------------------------------------------------
ComparePlayerWithEntry:
    push de
    inc de
    inc de
    ld a, (de)                  ; entry high byte
    ld hl, player_score_hi
    cp (hl)                     ; entry_hi - player_hi
    jr c, .cp_entry_smaller     ; entry_hi < player_hi -> player strictly greater!
    jr nz, .cp_entry_larger     ; entry_hi > player_hi -> player strictly smaller!

    ;; High bytes equal, compare low 16 bits:
    dec de
    dec de
    ld a, (de)
    ld c, a
    inc de
    ld a, (de)
    ld b, a                     ; BC = entry low 16 bits
    ld hl, (player_score)
    or a
    sbc hl, bc                  ; player_score - entry_lo
    jr c, .cp_entry_larger
    jr z, .cp_entry_larger

.cp_entry_smaller:
    pop de
    or a                        ; Clear carry: player > entry
    ret

.cp_entry_larger:
    pop de
    scf                         ; Set carry: player <= entry
    ret

;; ----------------------------------------------------------------------------
;; CheckHighScoreQualify: Test if player qualifies for Top 5
;; Returns: Carry CLEAR if qualified, and qualify_rank has 0..4
;;          Carry SET if not qualified
;; ----------------------------------------------------------------------------
CheckHighScoreQualify:
    ;; 1. Compare against 5th place entry (top5_table + 24)
    ld de, top5_table + 24
    call ComparePlayerWithEntry
    ret c                       ; Carry set -> player <= 5th place, does not qualify

    ;; 2. Scan entries 0..4 to find the first entry player beat
    ld de, top5_table
    ld b, 5
    ld c, 0
.csq_scan:
    push bc
    call ComparePlayerWithEntry
    pop bc
    jr nc, .csq_found           ; Carry clear -> player > entry, found rank!
    inc c
    ld a, 6
    add a, e
    ld e, a
    jr nc, .csq_de_nc
    inc d
.csq_de_nc:
    djnz .csq_scan
    ld c, 4

.csq_found:
    ld a, c
    ld (qualify_rank), a
    or a                        ; Clear carry
    ret

;; ----------------------------------------------------------------------------
;; InsertTop5Entry: Insert player_score + entered_initials at qualify_rank (0..4)
;; ----------------------------------------------------------------------------
InsertTop5Entry:
    ld a, (qualify_rank)
    cp 4
    jr z, .ite_no_shift         ; Rank 5: no entries need shifting

    ;; Shift entries from (qualify_rank) down to 3 by 1 slot (6 bytes)
    ;; Number of entries to shift = 4 - qualify_rank
    ld b, a
    ld a, 4
    sub b                       ; A = entries to shift (1..4)
    ld l, a
    ld h, 0
    ld e, 6
    call .mult_l_by_e           ; HL = entries * 6 bytes

    ld b, h
    ld c, l                     ; BC = byte count
    ld hl, top5_table + 24 - 1  ; HL = source end
    ld de, top5_table + 30 - 1  ; DE = destination end
    lddr

.ite_no_shift:
    ;; Compute destination address for new entry: top5_table + qualify_rank * 6
    ld a, (qualify_rank)
    ld l, a
    ld h, 0
    ld e, 6
    call .mult_l_by_e
    ld de, top5_table
    add hl, de
    ex de, hl                   ; DE = insertion pointer

    ;; Copy score (lo word, then hi byte)
    ld hl, (player_score)
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a
    inc de
    ld a, (player_score_hi)
    ld (de), a
    inc de

    ;; Copy 3 initials
    ld hl, entered_initials
    ldi
    ldi
    ldi

    ;; If rank 0, also update global high_score and high_score_hi
    ld a, (qualify_rank)
    or a
    ret nz
    ld hl, (player_score)
    ld (high_score), hl
    ld a, (player_score_hi)
    ld (high_score_hi), a
    ret

.mult_l_by_e:
    ld h, 0
    ld d, 0
    add hl, hl                  ; *2
    ld a, l : ld c, a
    ld a, h : ld b, a           ; BC = *2
    add hl, hl                  ; *4
    add hl, bc                  ; *6
    ret

;; ----------------------------------------------------------------------------
;; EnterInitialsScreen: Name entry UI & interactive input loop
;; ----------------------------------------------------------------------------
EnterInitialsScreen:
    ;; 1. Clear screen and re-init HUD
    call ClearScreenOverscan
    call InitTitleHUD

    ;; 2. Reset entered initials to "AAA"
    ld a, 'A'
    ld (entered_initials+0), a
    ld (entered_initials+1), a
    ld (entered_initials+2), a
    xor a
    ld (current_slot), a
    ld (entry_blink), a
    ld (ctl_now), a
    ld (ctl_last), a
    ld (ctl_pressed), a

    ;; 3. Render Header & Player Statistics
    ld b, 30
    ld c, 52
    ld hl, str_hall_of_fame_hdr
    call DrawGlyphString

    ld b, 30
    ld c, 72
    ld hl, str_great_score
    call DrawStringWhite

    ;; "RANK  1ST" at X=36, Y=96
    ld b, 36
    ld c, 96
    ld hl, str_rank_label
    call DrawStringWhite
    ld a, (qualify_rank)
    call GetRankStringPtr
    call DrawStringWhite

    ;; "SCORE 123450" at X=30, Y=116
    ld b, 30
    ld c, 116
    ld hl, str_score_label
    call DrawStringWhite
    ld hl, (player_score)
    ld a, (player_score_hi)
    ld b, 48
    ld c, 116
    call Print6Digits

    ;; "ENTER INITIALS" at X=27, Y=144
    ld b, 27
    ld c, 144
    ld hl, str_enter_initials
    call DrawStringWhite

.initials_loop:
    call WaitVSync
    call SoundUpdate

    ;; Update blink timer
    ld a, (entry_blink)
    inc a
    ld (entry_blink), a

    ;; Render 3 initials slots at X=42, 48, 54, Y=168
    call RenderInitialsSlots

    ;; Read user controls
    call read_controls
    ld a, (ctl_pressed)

    ;; Left or Down: Previous Letter
    bit CTL_LEFT, a
    jr nz, .prev_letter
    bit CTL_DOWN, a
    jr nz, .prev_letter

    ;; Right or Up: Next Letter
    bit CTL_RIGHT, a
    jr nz, .next_letter
    bit CTL_UP, a
    jr nz, .next_letter

    ;; Fire: Confirm letter and advance slot
    bit CTL_FIRE, a
    jr nz, .confirm_letter

    jr .initials_loop

.prev_letter:
    call GetCurrentSlotChar
    dec a
    cp 'A'
    jr nc, .pl_ok
    ld a, 'Z'
.pl_ok:
    call SetCurrentSlotChar
    call PlaySoundShot
    jr .initials_loop

.next_letter:
    call GetCurrentSlotChar
    inc a
    cp 'Z' + 1
    jr c, .nl_ok
    ld a, 'A'
.nl_ok:
    call SetCurrentSlotChar
    call PlaySoundShot
    jr .initials_loop

.confirm_letter:
    call PlaySoundShot
    ld a, (current_slot)
    inc a
    ld (current_slot), a
    cp 3
    jr c, .initials_loop

    ;; All 3 letters confirmed! Lock them in solid
    ld a, 3
    ld (current_slot), a
    call RenderInitialsSlots

    ;; Insert new record into top5_table!
    call InsertTop5Entry
    call HighScoreSave
    jr nc, .disk_save_ok

    ld c, 214
    cp HS_SAVE_PROTECTED
    jr z, .disk_protected
    cp HS_SAVE_NO_DISK
    jr z, .disk_missing
    ld b, 22
    ld hl, str_disk_save_failed
    jr .draw_disk_error
.disk_protected:
    ld b, 24
    ld hl, str_disk_protected
    jr .draw_disk_error
.disk_missing:
    ld b, 27
    ld hl, str_disk_missing
.draw_disk_error:
    call DrawStringWhite
.disk_save_ok:

    ;; Display "REGISTERED!" at X=32, Y=196
    ld b, 32
    ld c, 196
    ld hl, str_registered
    call DrawStringWhite

    ;; Congratulatory delay: ~150 frames (3 seconds) or until Fire pressed
    ld b, 150
.reg_wait:
    push bc
    call WaitVSync
    call SoundUpdate
    call read_controls
    ld a, (ctl_pressed)
    bit CTL_FIRE, a
    pop bc
    jr nz, .reg_done
    djnz .reg_wait

.reg_done:
    jp ShowTitleScreen

;; ----------------------------------------------------------------------------
;; GetCurrentSlotChar / SetCurrentSlotChar
;; ----------------------------------------------------------------------------
GetCurrentSlotChar:
    ld a, (current_slot)
    and 3
    ld e, a
    ld d, 0
    ld hl, entered_initials
    add hl, de
    ld a, (hl)
    ret

SetCurrentSlotChar:
    push af
    ld a, (current_slot)
    and 3
    ld e, a
    ld d, 0
    ld hl, entered_initials
    add hl, de
    pop af
    ld (hl), a
    ret

;; ----------------------------------------------------------------------------
;; RenderInitialsSlots: Draw the 3 letters at X=42, 48, 54, Y=168
;; Active slot blinks every 16 frames; confirmed/inactive slots are solid
;; ----------------------------------------------------------------------------
RenderInitialsSlots:
    ;; Slot 0 at X=42
    ld b, 42
    ld c, 168
    ld a, 0
    call .draw_one_slot

    ;; Slot 1 at X=48
    ld b, 48
    ld c, 168
    ld a, 1
    call .draw_one_slot

    ;; Slot 2 at X=54
    ld b, 54
    ld c, 168
    ld a, 2
    call .draw_one_slot

    ;; Render cursor dashes at Y=178
    ld c, 178
    ld b, 42
    ld a, (current_slot)
    cp 0
    call .draw_cursor_dash

    ld b, 48
    ld a, (current_slot)
    cp 1
    call .draw_cursor_dash

    ld b, 54
    ld a, (current_slot)
    cp 2
    call .draw_cursor_dash
    ret

.draw_cursor_dash:
    jr z, .is_active_dash
    ld a, ' '
    jp DrawCharWhite
.is_active_dash:
    ld a, '-'
    jp DrawCharWhite

.draw_one_slot:
    push bc
    ld e, a                     ; E = slot index
    ld a, (current_slot)
    cp e
    jr nz, .solid_draw          ; Inactive slot: draw solid

    ;; Active slot: check blink phase (bit 4: 16 frames on, 16 frames off)
    ld a, (entry_blink)
    and 16
    jr z, .solid_draw

    ;; Blink phase off: draw blank space
    pop bc
    ld a, ' '
    jp DrawCharWhite

.solid_draw:
    ld d, 0
    ld hl, entered_initials
    add hl, de
    ld a, (hl)
    pop bc
    jp DrawCharWhite

;; ----------------------------------------------------------------------------
;; DrawTitleHallOfFame: Draw Top 5 Table in Title Screen Attract Mode
;; ----------------------------------------------------------------------------
DrawTitleHallOfFame:
    ;; 1. Header: "TOP 5 HEROES" at X=30, Y=106
    ld b, 30
    ld c, 106
    ld hl, str_top5_heroes_hdr
    call DrawGlyphString

    ;; 2. Render 5 Entries
    ld ix, top5_table
    ld c, 126                   ; Initial Y
    ld d, 0                     ; Rank index 0..4
.t5_entry_loop:
    push de
    push bc                     ; Save Y in C

    ;; A. Draw Rank at X=24, Y=C
    ld b, 24
    ld a, d
    call GetRankStringPtr       ; HL = ptr to "1ST" / "2ND" / ...
    call DrawStringWhite

    ;; B. Draw Score (6 digits) at X=36, Y=C
    pop bc
    push bc
    ld l, (ix+0)
    ld h, (ix+1)
    ld a, (ix+2)
    ld b, 36
    push ix
    call Print6Digits
    pop ix

    ;; C. Draw Initials (3 chars) at X=60, Y=C
    pop bc
    push bc
    ld b, 60
    ld a, (ix+3)
    call DrawCharWhite
    ld b, 63
    ld a, (ix+4)
    call DrawCharWhite
    ld b, 66
    ld a, (ix+5)
    call DrawCharWhite

    ;; Advance to next entry
    pop bc
    pop de
    ld a, c
    add a, 18                   ; Next row Y (+18 scanlines: 126, 144, 162, 180, 198)
    ld c, a
    ld a, 6                     ; 6 bytes per entry
    add a, ixl
    ld ixl, a
    jr nc, .t5_ix_nc
    inc ixh
.t5_ix_nc:
    inc d
    ld a, d
    cp 5
    jr c, .t5_entry_loop
    ret

;; ----------------------------------------------------------------------------
;; ClearTitleMiddle: Clear middle area between Y=104 and Y=214 (X=20..84)
;; ----------------------------------------------------------------------------
ClearTitleMiddle:
    ld c, 104
    ld a, 110                   ; 110 scanlines
.ctm_row:
    push af
    push bc
    ld b, 20
    call GetScreenAddr
    ld b, 64                    ; 64 bytes wide (covers X=20..83)
    xor a
.ctm_byte:
    ld (hl), a
    inc hl
    djnz .ctm_byte
    pop bc
    pop af
    inc c
    dec a
    jr nz, .ctm_row
    ret
