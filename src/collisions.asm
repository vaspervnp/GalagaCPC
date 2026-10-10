;; ============================================================================
;; Galaga CPC - Collision Detection & Scoring
;; ============================================================================

CheckCollisions:
    ;; 1. Check Missiles vs Enemies
    ld ix, missile_data
    ld d, MAX_MISSILES
.m_loop:
    ld a, (ix+0)
    or a
    jp z, .next_m

    ld a, (ix+1)
    ld (.mx + 1), a
    ld a, (ix+2)
    ld (.my + 1), a
    ld hl, enemy_data + 2   ; HL -> enemy X
    ld bc, ENEMY_SIZE
    ld e, ENEMY_COUNT
.e_loop:
    ;; Horizontal overlap check first (positions of dead enemies are stale)
.mx:
    ld a, 0
    sub (hl)
    cp 8
    jr nc, .next_e

    ;; Vertical overlap check
    inc hl
.my:
    ld a, 0
    sub (hl)
    dec hl
    add a, 3
    cp 19
    jr nc, .next_e

    dec hl
    dec hl
    ld a, (hl)              ; alive?
    inc hl
    inc hl
    or a
    jr nz, .enemy_hit
.next_e:
    add hl, bc
    dec e
    jp nz, .e_loop
    jp .enemies_done

.enemy_hit:
    push hl
    pop iy
    dec iy
    dec iy                  ; IY = the enemy hit

    ;; *** HIT ENEMY! ***
    ld hl, (shots_hit)
    inc hl
    ld (shots_hit), hl

    ;; Check HP (Boss Galaga takes 2 hits)
    ld a, (iy+9)            ; hp
    dec a
    ld (iy+9), a
    or a
    jr z, .kill_enemy

    ;; Boss Galaga damaged (Hit 1: turns blue)
    push ix                 ; Preserve missile_data pointer
    push de
    call DrawEnemyIY
    call PlaySoundBossDamage
    pop de
    push de
    call AddPoints50
    pop de
    pop ix
    jp .destroy_missile


.kill_enemy:
    ld (iy+0), 0            ; alive = 0

    ;; If tractor boss is killed during an active beam, cancel it.
    ;; EraseTractorBeam walks enemy_data with IX and DE: keep the loop's.
    push ix
    push de
    ld a, (tractor_beam_active)
    or a
    jr z, .no_tractor_kill
    ld a, (iy+1)
    cp 2
    jr nz, .no_tractor_kill
    ld a, (tractor_beam_active)
    cp 2
    jr nz, .cancel_tractor_beam
    ;; A destroyed captor releases a ship that is still being lifted.
    ld a, (player_x)
    ld b, a
    ld a, (player_y)
    ld c, a
    call ClearSprite16x16
    call EraseTractorBeam
    ld a, DEFAULT_PLAYER_Y
    ld (player_y), a
    ld (old_player_y), a
.cancel_tractor_beam:
    call EraseTractorBeam
    xor a
    ld (tractor_beam_active), a
    ld (capture_delay), a
.no_tractor_kill:
    pop de
    pop ix

    ;; Erase enemy
    push ix                 ; Preserve missile_data pointer
    push de
    ld b, (iy+2)
    ld c, (iy+3)
    call ClearSprite16x16
    pop de

    ;; Spawn Explosion at exact enemy coordinates
    push de
    ld b, (iy+2)
    ld c, (iy+3)
    call SpawnExplosion
    call PlaySoundExplosion
    pop de

    ;; Add Score based on enemy type and state (Arcade authentic scoring)
    push de
    ld a, (is_challenging_stage)
    or a
    jr z, .normal_scoring

    ;; In Challenging Stage: every hit awards 100 pts and increments hit counter
    ld a, (challenging_hits)
    inc a
    ld (challenging_hits), a
    call AddPoints100
    jp .score_done

.normal_scoring:
    ld a, (iy+1)            ; Enemy Type
    cp 8
    jp z, .pts_galboss
    cp 7
    jp z, .pts_stingray
    cp 6
    jp z, .pts_sasori
    cp 2
    jp z, .pts_boss
    cp 1
    jp z, .pts_bf

    ;; Type 0: Bee (50 formation, 100 diving)
    ld a, (iy+8)            ; State
    cp 1
    jr z, .pts_bee_dive
    call AddPoints50
    jp .score_done
.pts_bee_dive:
    call AddPoints100
    jp .score_done

.pts_bf:
    ;; Type 1: Butterfly (80 formation, 160 diving)
    ld a, (iy+8)            ; State
    cp 1
    jr z, .pts_bf_dive
    call AddPoints80
    jp .score_done
.pts_bf_dive:
    call AddPoints160
    jp .score_done

.pts_boss:
    ;; Type 2: Boss Galaga (150 convoy, 400 alone, 800 w/ 1 escort, 1600 w/ 2 escorts)
    ;; Stop enemy firing for a short period (authentic arcade mechanic)
    ld a, 50
    ld (enemy_fire_freeze), a

    ;; If this Boss was holding captured fighter (in formation or diving), RESCUE IT!
    ld a, (captured_fighter_active)
    or a
    jr z, .no_held_rescue
    cp 3
    jr z, .no_held_rescue
    ;; Only the captor Boss releases the fighter (DE is saved on the stack).
    push iy
    pop hl
    ld de, (captor_boss_ptr)
    or a
    sbc hl, de
    jr nz, .no_held_rescue

    ;; RESCUE CAPTURED FIGHTER!
    ld a, 3
    ld (captured_fighter_active), a
    call PlaySoundRescue
    call AddPoints1000
    ld a, BONUS_1000
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.no_held_rescue:
    ld a, (iy+8)            ; State
    cp 1
    jr z, .boss_in_flight
    cp 4                    ; Tractor beam hover
    jr z, .boss_in_flight
    call AddPoints150
    ld a, BONUS_150
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.boss_in_flight:
    ld a, (iy+11)           ; Escort count (0, 1, or 2 Goeis)
    cp 2
    jr z, .boss_two_escorts
    cp 1
    jr z, .boss_one_escort
    call AddPoints400
    ld a, BONUS_400
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done
.boss_one_escort:
    call AddPoints800
    ld a, BONUS_800
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done
.boss_two_escorts:
    call AddPoints1600
    ld a, BONUS_1600
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.pts_sasori:
    call AddPoints160
    ld a, (transform_killed)
    inc a
    ld (transform_killed), a
    cp 3
    jp nz, .score_done
    xor a
    ld (transform_killed), a
    call AddPoints1000
    call PlaySoundExtraLife
    ld a, BONUS_1000
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.pts_stingray:
    call AddPoints160
    ld a, (transform_killed)
    inc a
    ld (transform_killed), a
    cp 3
    jp nz, .score_done
    xor a
    ld (transform_killed), a
    call AddPoints2000
    call PlaySoundExtraLife
    ld a, BONUS_2000
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.pts_galboss:
    call AddPoints160
    ld a, (transform_killed)
    inc a
    ld (transform_killed), a
    cp 3
    jp nz, .score_done
    xor a
    ld (transform_killed), a
    call AddPoints3000
    call PlaySoundExtraLife
    ld a, BONUS_3000
    ld b, (iy+2)
    ld c, (iy+3)
    call TriggerBonusScore
    jp .score_done

.score_done:
    pop de
    pop ix                  ; Restore missile_data pointer

.destroy_missile:
    push de
    ld a, (ix+5)
    or a
    jr z, .no_erase_m
    ld b, (ix+3)
    ld c, (ix+4)
    call EraseMissile
.no_erase_m:
    ld (ix+0), 0
    ld (ix+5), 0
    pop de
    jp .next_m

.enemies_done:
    ;; Check if missile ix hits captured fighter (if active in formation, escort, or descending)
    ld a, (captured_fighter_active)
    or a
    jr z, .next_m
    cp 3
    jr z, .cap_visible
    ld a, (captured_old_x)
    or a
    jr z, .next_m           ; Hidden while its Boss is near the top
.cap_visible:

    ;; Horizontal overlap check
    ld a, (ix+1)            ; missile X
    ld hl, captured_fighter_x
    sub (hl)
    cp 8
    jr nc, .next_m

    ;; Vertical overlap check
    ld a, (ix+2)            ; missile Y
    ld hl, captured_fighter_y
    sub (hl)
    add a, 3
    cp 19
    jr nc, .next_m

    ;; *** HIT CAPTURED FIGHTER! ***
    ld hl, (shots_hit)
    inc hl
    ld (shots_hit), hl

    ;; Get coordinates before clearing
    ld a, (captured_fighter_x)
    ld b, a
    ld a, (captured_fighter_y)
    ld c, a

    ;; The sprite and score routines use IX and DE: keep the missile loop's.
    push ix
    push de
    push bc
    call ClearCapturedFighterSprite
    xor a
    ld (captured_fighter_active), a
    ld (captured_fighter_x), a
    ld (captured_fighter_y), a

    pop bc
    push bc
    call SpawnExplosion
    call PlaySoundCapturedDestroy
    call AddPoints1000
    pop bc
    ld a, BONUS_1000
    call TriggerBonusScore
    pop de
    pop ix
    jp .destroy_missile

.next_m:
    ld bc, MISSILE_SIZE
    add ix, bc
    dec d
    jp nz, .m_loop

    ;; 2. Check Enemy Bullets vs Player
    ld a, (game_over)
    or a
    ret nz

    ;; In Challenging Stage: NO DANGER! Enemies cannot fire or harm ship!
    ld a, (is_challenging_stage)
    or a
    ret nz

    ld a, (capture_delay)
    or a
    ret nz                  ; Immune while waiting for replacement ship!
    ld a, (respawn_wait)
    or a
    ret nz                  ; No fighter on screen after losing a life.

    ld a, (player_invincible_timer)
    or a
    ret nz                  ; Immune for 2 seconds after respawn!

    ld ix, ebullet_data
    ld b, MAX_EBULLETS
.eb_p_loop:
    ld a, (ix+0)
    or a
    jr z, .next_eb_chk

    ;; Check if bullet hits player
    ;; Width is 8 bytes for single fighter, 16 bytes for dual fighter
    ld a, (player_x)
    ld c, a
    ld a, (ix+1)
    sub c
    ld c, a
    ld a, (is_dual_fighter)
    or a
    jr nz, .dual_bullet_w
    ld a, c
    cp 8
    jr nc, .next_eb_chk
    jr .check_bullet_y
.dual_bullet_w:
    ld a, c
    cp 16
    jr nc, .next_eb_chk

.check_bullet_y:
    ld a, (player_y)
    ld c, a
    ld a, (ix+2)
    sub c
    cp 16
    jr nc, .next_eb_chk

    ;; Bullet hit Player!
    push bc
    push ix
    ld b, (ix+1)
    ld c, (ix+2)
    call EraseEBullet
    pop ix
    pop bc
    ld (ix+0), 0
    ld (ix+5), 0
    call HitPlayer
    ret

.next_eb_chk:
    ld de, EBULLET_SIZE
    add ix, de
    djnz .eb_p_loop

    ;; 3. Check Diving Enemies vs Player (Crash)
    ld ix, enemy_data
    ld b, ENEMY_COUNT
.crash_loop:
    ld a, (ix+0)
    or a
    jr z, .next_crash
    ld a, (ix+8)            ; only diving enemies
    cp 1
    jr nz, .next_crash

    ld a, (player_x)
    ld c, a
    ld a, (ix+2)
    sub c
    ld c, a
    ld a, (is_dual_fighter)
    or a
    jr nz, .dual_crash_w
    ld a, c
    add a, 6
    cp 13
    jr nc, .next_crash
    jr .check_crash_y
.dual_crash_w:
    ld a, c
    add a, 6
    cp 21
    jr nc, .next_crash

.check_crash_y:
    ld a, (player_y)
    ld c, a
    ld a, (ix+3)
    sub c
    add a, 8
    cp 20
    jr nc, .next_crash

    ;; Crash into Player!
    ld (ix+0), 0
    push ix
    push bc
    ld b, (ix+4)
    ld c, (ix+5)
    call ClearSprite16x16
    pop bc
    pop ix
    call HitPlayer
    ret

.next_crash:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .crash_loop
    ret

AddPoints50:
    ld bc, 50
    jr apply_points
AddPoints80:
    ld bc, 80
    jr apply_points
AddPoints100:
    ld bc, 100
    jr apply_points
AddPoints150:
    ld bc, 150
    jr apply_points
AddPoints160:
    ld bc, 160
    jr apply_points
AddPoints400:
    ld bc, 400
    jr apply_points
AddPoints800:
    ld bc, 800
    jr apply_points
AddPoints1600:
    ld bc, 1600
    jr apply_points
AddPoints1000:
    ld bc, 1000
    jr apply_points
AddPoints2000:
    ld bc, 2000
    jr apply_points
AddPoints3000:
    ld bc, 3000
    jr apply_points

apply_points:
    ld hl, (player_score)
    add hl, bc
    ld (player_score), hl
    jr nc, .no_score_carry
    ld a, (player_score_hi)
    inc a
    ld (player_score_hi), a
.no_score_carry:
    call PrintScore

.check_extra_life:
    ;; Compare 24-bit player_score against next_extra_life
    ld a, (player_score_hi)
    ld hl, next_extra_life_hi
    cp (hl)
    jr c, .check_high_score     ; player_score_hi < next_extra_life_hi -> not reached
    jr nz, .extra_life_reached  ; player_score_hi > next_extra_life_hi -> reached!
    ;; High bytes equal: compare low 16 bits
    ld hl, (player_score)
    ld de, (next_extra_life_lo)
    or a                        ; Clear carry
    sbc hl, de
    jr c, .check_high_score     ; player_score < next_extra_life_lo -> not reached

.extra_life_reached:
    ld a, (extra_life_count)
    inc a
    ld (extra_life_count), a
    cp 1
    jr nz, .add_70k
    ;; 1st milestone (20,000) reached: set next to 70,000 (1 * 65536 + 4464)
    ld hl, 4464
    ld (next_extra_life_lo), hl
    ld a, 1
    ld (next_extra_life_hi), a
    jr .award_life

.add_70k:
    ;; 2nd and subsequent milestones: advance next by 70,000
    ld hl, (next_extra_life_lo)
    ld de, 4464
    add hl, de
    ld (next_extra_life_lo), hl
    ld a, (next_extra_life_hi)
    adc a, 1
    ld (next_extra_life_hi), a

.award_life:
    ;; Max 8 lives limit (arcade authentic)
    ld a, (player_lives)
    cp 8
    jr nc, .no_more_lives
    inc a
    ld (player_lives), a
    call DrawLivesHUD
.no_more_lives:
    call PlaySoundExtraLife

.check_high_score:
    ;; Check if new high score (24-bit comparison)
    ld a, (player_score_hi)
    ld hl, high_score_hi
    cp (hl)
    jr c, .no_high_update     ; player_score_hi < high_score_hi
    jr nz, .update_high_score ; player_score_hi > high_score_hi
    ;; High bytes equal: compare low 16 bits
    ld hl, (player_score)
    ld de, (high_score)
    or a                      ; Clear carry
    sbc hl, de
    jr c, .no_high_update     ; player_score < high_score
.update_high_score:
    ld hl, (player_score)
    ld (high_score), hl
    ld a, (player_score_hi)
    ld (high_score_hi), a
    call PrintHighScore
.no_high_update:
    ret
