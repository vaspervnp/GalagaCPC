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

    ld iy, enemy_data
    ld e, ENEMY_COUNT
.e_loop:
    ld a, (iy+0)
    or a
    jp z, .next_e

    ;; Horizontal overlap check
    ld a, (ix+1)
    ld c, (iy+2)
    sub c
    cp 8
    jp nc, .next_e

    ;; Vertical overlap check
    ld a, (ix+2)
    ld c, (iy+3)
    sub c
    add a, 3
    cp 19
    jp nc, .next_e

    ;; *** HIT ENEMY! ***
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
    pop de
    push de
    call AddPoints50
    pop de
    pop ix
    jp .destroy_missile


.kill_enemy:
    ld (iy+0), 0            ; alive = 0

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

    ;; Add Score based on enemy type and state (StrategyWiki authentic scoring)
    push de
    ld a, (is_challenging_stage)
    or a
    jr z, .normal_scoring

    ;; In Challenging Stage: every hit awards 100 pts and increments hit counter
    ld a, (challenging_hits)
    inc a
    ld (challenging_hits), a
    call AddPoints100
    jr .score_done

.normal_scoring:
    ld a, (iy+1)            ; Enemy Type
    cp 8
    jr z, .pts_galboss
    cp 7
    jr z, .pts_stingray
    cp 6
    jr z, .pts_sasori
    cp 2
    jr z, .pts_boss
    cp 1
    jr z, .pts_bf

    ;; Type 0: Bee (50 formation, 100 diving)
    ld a, (iy+8)            ; State
    cp 1
    jr z, .pts_bee_dive
    call AddPoints50
    jr .score_done
.pts_bee_dive:
    call AddPoints100
    jr .score_done

.pts_bf:
    ;; Type 1: Butterfly (80 formation, 160 diving)
    ld a, (iy+8)            ; State
    cp 1
    jr z, .pts_bf_dive
    call AddPoints80
    jr .score_done
.pts_bf_dive:
    call AddPoints160
    jr .score_done

.pts_boss:
    ;; Type 2: Boss Galaga (150 formation, 400 diving, 1000 + rescue with escort)
    ld a, (iy+8)            ; State
    cp 1
    jr z, .boss_in_flight
    cp 4                    ; Tractor beam hover
    jr z, .boss_in_flight
    call AddPoints150
    jr .score_done

.boss_in_flight:
    ;; Check if Boss Galaga was escorting captured fighter
    ld a, (captured_fighter_active)
    cp 2
    jr nz, .boss_single_dive

    ;; RESCUE CAPTURED FIGHTER!
    ld a, 3
    ld (captured_fighter_active), a
    call PlaySoundRescue
    call AddPoints1000
    jr .score_done

.boss_single_dive:
    call AddPoints400
    jr .score_done

.pts_sasori:
    call AddPoints1000
    jr .score_done

.pts_stingray:
    call AddPoints2000
    jr .score_done

.pts_galboss:
    call AddPoints3000
    jr .score_done

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

.next_e:
    ld bc, ENEMY_SIZE
    add iy, bc
    dec e
    jp nz, .e_loop

.next_m:
    ld bc, MISSILE_SIZE
    add ix, bc
    dec d
    jp nz, .m_loop

    ;; 2. Check Enemy Bullets vs Player
    ld a, (game_over)
    or a
    ret nz

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
    ld (ix+0), 0
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
    call PrintScore

    ;; Check extra life at 20,000 points
    ld a, (extra_life_awarded)
    or a
    jr nz, .check_high_score
    ld de, 20000
    push hl
    or a
    sbc hl, de
    pop hl
    jr c, .check_high_score

    ;; 1st Extra Life milestone reached!
    ld a, 1
    ld (extra_life_awarded), a
    ld a, (player_lives)
    cp 8
    jr nc, .no_more_lives
    inc a
    ld (player_lives), a
    call DrawLivesHUD
.no_more_lives:
    call PlaySoundExtraLife

.check_high_score:
    ;; Check if new high score
    ld de, (high_score)
    or a                    ; Clear carry
    sbc hl, de
    jr c, .no_high_update
    ld hl, (player_score)
    ld (high_score), hl
    call PrintHighScore
.no_high_update:
    ret

