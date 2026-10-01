;; ============================================================================
;; Galaga CPC - AY-3-8912 Sound Effects Engine
;; Amstrad CPC 464 / 6128 PSG Sound Driver
;; ============================================================================

;; Current mixer settings (Reg 7, 0=enabled, 1=disabled)
;; Default: All tone and noise disabled (#3F)
ay_mixer_val:       defb #3F

;; Sound FX Timers & State
sfx_shot_timer:         defb 0
sfx_shot_pitch:         defb 0

sfx_exp_timer:          defb 0
sfx_exp_vol:            defb 0

sfx_dive_timer:         defb 0
sfx_dive_pitch:         defb 0
sfx_dive_type:          defb 0  ; 0 = Flying enemy dive warble, 1 = Tractor pulse

sfx_jingle_timer:       defb 0
sfx_jingle_step:        defb 0

;; Extra Life Fanfare (6-Note Arpeggio on Channel A from assets/extend.wav)
sfx_extend_timer:       defb 0
extend_pitches:
    defw #002F, #0028, #0020, #001B, #0014, #0010 ; E6, G6, B6, D7, G7, B7

;; Boss Galaga Damage Chirp (9-Frame Upward Sweep on Channel A from assets/boss_damage.wav)
sfx_boss_dmg_timer:     defb 0
boss_damage_pitches:
    defw #009D, #0090, #0089, #0082, #007C, #0074, #006F, #006B, #0063

;; Captured Fighter Destroyed Warble (Channel B from assets/captured_ship_destroy.wav)
sfx_cap_destroy_timer:  defb 0
sfx_cap_destroy_pitch:  defb 0

;; Stage Background Drone State (Channel C)
drone_active:       defb 0  ; 0 = inactive, 1 = active
drone_step:         defb 0  ; Current note in pattern (0..3, bonus music 0..15)
drone_timer:        defb 0  ; Countdown for current step
drone_step_len:     defb 12 ; Length of step in frames (based on remaining enemies)
challenge_music_pitch: defw 0

drone_pitches:
    defb #53, #03   ; Note 0: D2 (73.4 Hz, period 851)
    defb #CC, #02   ; Note 1: F2 (87.3 Hz, period 716)
    defb #7E, #02   ; Note 2: G2 (98.0 Hz, period 638)
    defb #CC, #02   ; Note 3: F2 (87.3 Hz, period 716)

challenging_music_pitches:
    defw #006A, #005F, #0050, #005F
    defw #0077, #006A, #005F, #0047
    defw #0050, #0047, #003C, #0047
    defw #005F, #0050, #0047, #003C

;; 3-Voice Polyphonic Music Engine (Game Start Tune from assets/game-start-tune.mid)
music_playing:      defb 0
music_ptr:          defw 0
music_step_timer:   defb 0
sound_irq_divider:  defb 0
sound_clock_pending: defb 0

;; ----------------------------------------------------------------------------
;; SoundInit: Silence all 3 AY channels and reset sound state
;; ----------------------------------------------------------------------------
SoundInit:
    xor a
    ld (music_playing), a
    ld (music_step_timer), a
    ld (sfx_shot_timer), a
    ld (sfx_exp_timer), a
    ld (sfx_dive_timer), a
    ld (sfx_jingle_timer), a
    ld (sfx_extend_timer), a
    ld (sfx_boss_dmg_timer), a
    ld (sfx_cap_destroy_timer), a
    ld (drone_active), a
    ld (drone_timer), a
    ld (drone_step), a
    ld (sound_clock_pending), a

    ;; Set Reg 8, 9, 10 (Volumes) to 0
    ld a, 8
    ld e, 0
    call WriteAY
    ld a, 9
    ld e, 0
    call WriteAY
    ld a, 10
    ld e, 0
    call WriteAY

    ;; Set Reg 7 (Mixer) to #3F (all channels disabled)
    ld a, #3F
    ld (ay_mixer_val), a
    ld e, #3F
    ld a, 7
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; SoundMute: Silence all 3 AY channels during Pause
;; ----------------------------------------------------------------------------
SoundMute:
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, 9 : ld e, 0 : call WriteAY
    ld a, 10 : ld e, 0 : call WriteAY
    ld a, 7 : ld e, #3F : call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; SoundUnmute: Restore AY channel mixer after Pause
;; ----------------------------------------------------------------------------
SoundUnmute:
    ld a, (ay_mixer_val)
    ld e, a
    ld a, 7
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundShot: Classic Galaga Laser Firing Chirp (Channel A)
;; ----------------------------------------------------------------------------
PlaySoundShot:
    ;; Don't override extra life fanfare or boss damage chirp
    ld a, (sfx_extend_timer)
    or a
    ret nz
    ld a, (sfx_boss_dmg_timer)
    or a
    ret nz

    ld a, 8                 ; ~8 frames duration
    ld (sfx_shot_timer), a
    ld a, 25                ; Starting high pitch period
    ld (sfx_shot_pitch), a

    ;; Enable Tone on Channel A (Bit 0 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111110
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Initial Channel A Volume = 13
    ld a, 8
    ld e, 13
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundExplosion: Arcade Alien Destruction Crunch (Channel C Noise)
;; ----------------------------------------------------------------------------
PlaySoundExplosion:
    ld a, 14                ; 14 frames duration
    ld (sfx_exp_timer), a
    ld a, 14
    ld (sfx_exp_vol), a

    ;; Set Noise Period (Reg 6) = 22 (deep rumbling noise)
    ld a, 6
    ld e, 22
    call WriteAY

    ;; Enable Noise on Channel C (Bit 5 = 0), disable Tone on Channel C (Bit 2 = 1)
    ld a, (ay_mixer_val)
    and %11011111           ; Bit 5 = 0 (Noise C enabled)
    or  %00000100           ; Bit 2 = 1 (Tone C disabled during explosion)
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Set Channel C Volume = 14
    ld a, 10
    ld e, 14
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundDive: Authentic Galaga Flying Enemy Warble (Channel B)
;; (Transcribed directly from assets/dive.wav)
;; ----------------------------------------------------------------------------
PlaySoundDive:
    xor a
    ld (sfx_dive_type), a
    ld a, 80                ; 80 frames duration (~1.6 seconds)
    ld (sfx_dive_timer), a

    ;; Enable Tone on Channel B (Bit 1 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111101
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Channel B Volume = 12
    ld a, 9
    ld e, 12
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundTractor: Tractor Beam Pulsing Tone (Channel B)
;; ----------------------------------------------------------------------------
PlaySoundTractor:
    ld a, 1
    ld (sfx_dive_type), a
    ld a, 8
    ld (sfx_dive_timer), a
    ld a, 90
    ld (sfx_dive_pitch), a

    ld a, (ay_mixer_val)
    and %11111101
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ld a, 9
    ld e, 12
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundBossDamage: Fast Ascending Chirp Sweep (Channel A)
;; (Transcribed directly from assets/boss_damage.wav - 9 frames duration)
;; ----------------------------------------------------------------------------
PlaySoundBossDamage:
    ld a, (music_playing)
    or a
    ret nz
    ld a, (sfx_extend_timer)
    or a
    ret nz

    ld a, 9
    ld (sfx_boss_dmg_timer), a
    xor a
    ld (sfx_shot_timer), a  ; Override laser shot

    ;; Enable Tone on Channel A (Bit 0 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111110
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Initial Channel A Volume = 13
    ld a, 8
    ld e, 13
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundExtraLife: Authentic 6-Note Ascending Arpeggio (Channel A)
;; (Transcribed from assets/extend.wav - 30 frames duration, ~0.60 seconds)
;; Pitches: E6, G6, B6, D7, G7, B7
;; ----------------------------------------------------------------------------
PlaySoundExtraLife:
    ld a, 30
    ld (sfx_extend_timer), a
    xor a
    ld (sfx_shot_timer), a
    ld (sfx_boss_dmg_timer), a
    ld (sfx_jingle_timer), a

    ;; Enable Tone on Channel A (Bit 0 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111110
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ld a, 8
    ld e, 14
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundCapturedDestroy: Captured Fighter Destroyed SFX
;; (Explosion crunch on Channel C Noise + Sad descending tone glide on Channel B)
;; (Transcribed from assets/captured_ship_destroy.wav)
;; ----------------------------------------------------------------------------
PlaySoundCapturedDestroy:
    ;; 1. Channel C: Deep explosion crunch
    call PlaySoundExplosion

    ;; 2. Channel B: Descending mournful warble
    ld a, 50                ; 50 frames duration (~1.0s)
    ld (sfx_cap_destroy_timer), a
    ld a, 46                ; Initial high frequency period (~1350 Hz)
    ld (sfx_cap_destroy_pitch), a
    xor a
    ld (sfx_dive_timer), a  ; Override dive sound

    ;; Enable Tone on Channel B (Bit 1 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111101
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ld a, 9                 ; Initial Channel B Volume = 14
    ld e, 14
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlayMusicFighterCaptured: 3-Voice Fighter Captured Theme
;; (Transcribed from assets/fighter_captured.wav)
;; ----------------------------------------------------------------------------
PlayMusicFighterCaptured:
    ld hl, fighter_captured_tune_data
    jp PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlayMusicFighterRescued / PlaySoundRescue: 3-Voice Fighter Rescued Theme
;; (Transcribed from assets/fighter_rescued.wav)
;; ----------------------------------------------------------------------------
PlayMusicFighterRescued:
PlaySoundRescue:
    ;; If music is already playing, do not restart
    ld a, (music_playing)
    or a
    ret nz
    ld hl, fighter_rescued_tune_data
    jp PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlaySoundStageStart: Ascending Fanfare (Channel A)
;; ----------------------------------------------------------------------------
PlaySoundStageStart:
    ld a, 40
    ld (sfx_jingle_timer), a
    xor a
    ld (sfx_jingle_step), a

    ld a, (ay_mixer_val)
    and %11111110
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ld a, 8
    ld e, 14
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundGameOver: Descending Game Over tone (Channel B)
;; ----------------------------------------------------------------------------
PlaySoundGameOver:
    ld a, 50
    ld (sfx_dive_timer), a
    ld a, 180
    ld (sfx_dive_pitch), a

    ld a, (ay_mixer_val)
    and %11111101
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ld a, 9
    ld e, 14
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; SoundUpdate: Consume fixed 50Hz sound ticks accumulated by SoundInterrupt.
;; ----------------------------------------------------------------------------
SoundUpdate:
    ;; Consume 50 Hz ticks accumulated by the CPC's 300 Hz Gate Array IRQ.
    ;; PSG writes remain in the main loop rather than running in interrupt context.
    di
    ld a, (sound_clock_pending)
    ld b, a
    xor a
    ld (sound_clock_pending), a
    ei
    ld a, b
    or a
    ret z
.sound_tick_loop:
    push bc
    call SoundUpdateTick
    pop bc
    djnz .sound_tick_loop
    ret

;; Advance sound state by one fixed-clock tick.
SoundUpdateTick:
    ;; --- 0. Update Background Music (Game Start Tune, Rescue, Capture, etc.) ---
    ld a, (music_playing)
    or a
    jr z, .no_music

    call UpdateMusicPlayer
    ret

.no_music:
    ;; --- 1A. Update Extra Life Arpeggio (Channel A) ---
    ld a, (sfx_extend_timer)
    or a
    jr z, .check_boss_dmg

    dec a
    ld (sfx_extend_timer), a
    jr nz, .extend_continue

    ;; Finished: silence Channel A
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, (ay_mixer_val)
    or %00000001
    ld (ay_mixer_val), a
    ld e, a : ld a, 7 : call WriteAY
    jp .check_exp

.extend_continue:
    ;; Timer goes from 29 down to 1 (30 frames total)
    ;; Elapsed = 30 - timer (1..29)
    ld a, 30
    ld hl, sfx_extend_timer
    sub (hl)                ; A = 1..29
    ld b, a

    ;; 1-frame silence on every 5th frame for crisp staccato articulation
.ext_mod:
    cp 5
    jr c, .ext_mod_done
    sub 5
    jr .ext_mod
.ext_mod_done:
    or a
    jr nz, .ext_play_note
    ld a, 8 : ld e, 0 : call WriteAY
    jp .check_exp

.ext_play_note:
    ;; Note index = B / 5 (0..5)
    ld a, b
    ld c, 0
.ext_div:
    cp 5
    jr c, .ext_div_done
    sub 5
    inc c
    jr .ext_div
.ext_div_done:
    ld a, c
    cp 6
    jr c, .ext_idx_ok
    ld a, 5
.ext_idx_ok:
    add a, a
    ld e, a
    ld d, 0
    ld hl, extend_pitches
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld a, 0 : call WriteAY
    ld a, 1 : ld e, d : call WriteAY
    ld a, 8 : ld e, 14 : call WriteAY
    jp .check_exp

.check_boss_dmg:
    ;; --- 1B. Update Boss Damage Chirp (Channel A) ---
    ld a, (sfx_boss_dmg_timer)
    or a
    jr z, .check_jingle

    dec a
    ld (sfx_boss_dmg_timer), a
    jr nz, .boss_dmg_continue

    ;; Finished: silence Channel A
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, (ay_mixer_val)
    or %00000001
    ld (ay_mixer_val), a
    ld e, a : ld a, 7 : call WriteAY
    jp .check_exp

.boss_dmg_continue:
    ;; 9 frames total: index = 8 - a (0..8)
    ld b, a
    ld a, 8
    sub b
    add a, a
    ld e, a
    ld d, 0
    ld hl, boss_damage_pitches
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld a, 0 : call WriteAY
    ld a, 1 : ld e, d : call WriteAY
    ld a, 8 : ld e, 13 : call WriteAY
    jp .check_exp

.check_jingle:
    ;; --- 1C. Update Jingle / Fanfare (Channel A) ---
    ld a, (sfx_jingle_timer)
    or a
    jr z, .check_shot

    dec a
    ld (sfx_jingle_timer), a
    jr nz, .jingle_continue

    ;; Jingle finished: Silence Channel A
    ld a, 8
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00000001
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    jp .check_exp

.jingle_continue:
    ;; Step pitch upward
    ld a, (sfx_jingle_timer)
    and 7
    jp nz, .check_exp
    ld a, (sfx_jingle_step)
    inc a
    ld (sfx_jingle_step), a
    ;; Determine pitch from step
    cp 1
    ld e, 100
    jr z, .apply_jingle_pitch
    cp 2
    ld e, 75
    jr z, .apply_jingle_pitch
    cp 3
    ld e, 55
    jr z, .apply_jingle_pitch
    ld e, 40
.apply_jingle_pitch:
    ld a, 0                 ; Reg 0: Channel A Fine Pitch
    call WriteAY
    ld a, 1
    ld e, 0
    call WriteAY
    jp .check_exp

.check_shot:
    ;; --- 1D. Update Laser Shot (Channel A) ---
    ld a, (sfx_shot_timer)
    or a
    jr z, .check_exp

    dec a
    ld (sfx_shot_timer), a
    jr nz, .shot_continue

    ;; Shot finished: Silence Channel A
    ld a, 8
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00000001           ; Disable Tone A
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    jp .check_exp

.shot_continue:
    ;; Sweep pitch down (increase period by 14)
    ld a, (sfx_shot_pitch)
    add a, 14
    ld (sfx_shot_pitch), a
    ld e, a
    ld a, 0                 ; Reg 0: Channel A Fine Pitch
    call WriteAY
    ld a, 1                 ; Reg 1: Channel A Coarse Pitch = 0
    ld e, 0
    call WriteAY

    ;; Decay volume
    ld a, (sfx_shot_timer)
    add a, a                ; Volume proportional to timer
    cp 13
    jr c, .shot_vol_ok
    ld a, 13
.shot_vol_ok:
    ld e, a
    ld a, 8                 ; Reg 8: Channel A Volume
    call WriteAY

.check_exp:
    ;; --- 2. Update Explosion (Channel C) ---
    ld a, (sfx_exp_timer)
    or a
    jr z, .check_cap_destroy

    dec a
    ld (sfx_exp_timer), a
    jr nz, .exp_continue

    ;; Explosion finished: Silence Channel C
    ld a, 10
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00100000           ; Disable Noise C
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    jr .check_cap_destroy

.exp_continue:
    ld a, (sfx_exp_vol)
    or a
    jr z, .check_cap_destroy
    dec a
    ld (sfx_exp_vol), a
    ld e, a
    ld a, 10                ; Reg 10: Channel C Volume
    call WriteAY

.check_cap_destroy:
    ;; --- 3. Update Captured Fighter Destroy Mournful Warble (Channel B) ---
    ld a, (sfx_cap_destroy_timer)
    or a
    jr z, .check_dive

    dec a
    ld (sfx_cap_destroy_timer), a
    jr nz, .cap_destroy_continue

    ;; Finished: silence Channel B Tone
    ld a, 9 : ld e, 0 : call WriteAY
    ld a, (ay_mixer_val)
    or %00000010           ; Disable Tone B
    ld (ay_mixer_val), a
    ld e, a : ld a, 7 : call WriteAY
    jp .check_drone

.cap_destroy_continue:
    ;; Slide pitch downward: increase period by 4 each frame
    ld hl, sfx_cap_destroy_pitch
    ld a, (hl)
    add a, 4
    ld (hl), a
    ld e, a
    ld a, 2 : call WriteAY
    ld a, 3 : ld e, 0 : call WriteAY

    ;; Decay volume from 14 down to 0
    ld a, (sfx_cap_destroy_timer)
    srl a
    srl a                   ; timer / 4 (0..12)
    add a, 2                ; 2..14
    ld e, a
    ld a, 9 : call WriteAY
    jp .check_drone

.check_dive:
    ;; --- 4. Update Dive Warble (Channel B) ---
    ld a, (sfx_dive_timer)
    or a
    jr z, .check_drone

    dec a
    ld (sfx_dive_timer), a
    jr nz, .dive_continue

    ;; Dive finished: Silence Channel B
    ld a, 9
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00000010           ; Disable Tone B
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    jr .check_drone

.dive_continue:
    ld a, (sfx_dive_type)
    or a
    jr nz, .tractor_sound_update

    ;; --- Authentic Galaga Flying Enemy Dive Warble (from assets/dive.wav) ---
    ;; Elapsed frames = 80 - sfx_dive_timer (0..79)
    ld a, 80
    ld hl, sfx_dive_timer
    sub (hl)
    ld c, a                 ; C = elapsed frames (0..79)

    ;; Base pitch = 50 + C + (C/2) -> glides smoothly from 50 to 168
    srl a                   ; C / 2
    add a, c                ; 1.5 * C
    add a, 50               ; A = base period (50..168)
    ld c, a

    ;; Octave warble: alternate every 2 frames
    ld a, (sfx_dive_timer)
    bit 1, a
    jr z, .dive_apply_pitch
    srl c                   ; High octave: C = base / 2 (25..84)

.dive_apply_pitch:
    ld e, c
    ld a, 2                 ; Reg 2: Channel B Fine Pitch
    call WriteAY
    ld e, 0
    ld a, 3                 ; Reg 3: Channel B Coarse Pitch = 0
    call WriteAY
    jr .check_drone

.tractor_sound_update:
    ;; Tractor pulsing sound (alternating pitch)
    ld a, (sfx_dive_timer)
    and 3
    cp 2
    ld e, 90
    jr c, .apply_tractor_pitch
    ld e, 120
.apply_tractor_pitch:
    ld a, 2
    call WriteAY
    ld a, 3
    ld e, 0
    call WriteAY
    jr .check_drone

.check_drone:
    ;; --- 4. Update Stage Background Drone / Hum (Channel C) ---
    call UpdateDrone
    ret

;; Install an IM 1 handler. The CPC Gate Array interrupts at 300 Hz;
;; accumulate one sound tick for every six interrupts (50 Hz).
SoundInterruptInit:
    xor a
    ld (sound_irq_divider), a
    ld (sound_clock_pending), a
    ld a, #C3
    ld (#0038), a
    ld hl, SoundInterrupt
    ld (#0039), hl
    im 1
    ei
    ret

SoundInterrupt:
    push af
    push hl
    ld hl, sound_irq_divider
    inc (hl)
    ld a, (hl)
    cp 6
    jr c, .sound_irq_done
    xor a
    ld (hl), a
    ld hl, sound_clock_pending
    ld a, (hl)
    cp 8
    jr nc, .sound_irq_done
    inc (hl)
.sound_irq_done:
    pop hl
    pop af
    ei
    reti

;; ----------------------------------------------------------------------------
;; UpdateDrone: Authentic Galaga Stage Background Drone / Hum (Channel C)
;; Plays the classic 4-note bass motif (D2 -> F2 -> G2 -> F2)
;; Dynamically accelerates as enemies are destroyed!
;; ----------------------------------------------------------------------------
UpdateDrone:
    ;; 1. Check if Drone should be silent
    ld a, (is_title_screen)
    or a
    jp nz, .silence_drone

    ld a, (game_over)
    or a
    jp nz, .silence_drone

    ld a, (stage_intro_state)
    or a
    jp nz, .silence_drone

    ld a, (is_challenging_stage)
    or a
    jr z, .normal_stage_music
    ld a, (challenging_active)
    cp 1
    jp z, UpdateChallengingMusic
    jp .silence_drone

.normal_stage_music:

    ld a, (stage_clear_active)
    or a
    jp nz, .silence_drone

    ld a, (stage_phase)
    cp STAGE_PHASE_ATTACK
    jp nz, .silence_drone

    ;; Combat attack phase is active!
    ld a, 1
    ld (drone_active), a

    ;; If an explosion is currently playing on Channel C, advance timer in background
    ld a, (sfx_exp_timer)
    or a
    jp nz, .drone_exp_playing

    ;; Decrement step timer
    ld a, (drone_timer)
    or a
    jr z, .drone_next_step
    dec a
    ld (drone_timer), a

    ;; Check staccato feel: mute in last frame of step for punchy note separation
    cp 1
    jr nz, .drone_apply_hardware

    ld a, 10                ; Reg 10: Volume C = 0 for 1 frame
    ld e, 0
    call WriteAY
    ret

.drone_next_step:
    ;; Advance to next note in 4-note motif (0..3)
    ld a, (drone_step)
    inc a
    and 3
    ld (drone_step), a

    ;; If wrapped to 0 (new phrase), recalculate tempo based on remaining enemies!
    or a
    jr nz, .drone_step_tempo_ready

    ;; Count alive enemies (1..20)
    ld ix, enemy_data
    ld b, ENEMY_COUNT
    ld c, 0
.cnt_alive_loop:
    ld a, (ix+0)
    or a
    jr z, .cnt_next
    inc c
.cnt_next:
    ld de, ENEMY_SIZE
    add ix, de
    djnz .cnt_alive_loop

    ;; If no enemies left, silence
    ld a, c
    or a
    jp z, .silence_drone

    ;; Tempo scaling based on alive enemies count C:
    ;; C >= 20: 12 frames (~0.96s per 4-note motif)
    ;; 12 <= C < 20: 9 frames (~0.72s)
    ;; 6 <= C < 12: 6 frames (~0.48s)
    ;; C < 6: 4 frames (~0.32s rapid intense pulse!)
    cp 20
    ld a, 12
    jr nc, .set_step_len
    ld a, c
    cp 12
    ld a, 9
    jr nc, .set_step_len
    ld a, c
    cp 6
    ld a, 6
    jr nc, .set_step_len
    ld a, 4
.set_step_len:
    ld (drone_step_len), a

.drone_step_tempo_ready:
    ld a, (drone_step_len)
    ld (drone_timer), a

.drone_apply_hardware:
    ;; If explosion is playing on Channel C, do not touch registers
    ld a, (sfx_exp_timer)
    or a
    ret nz

    ;; Enable Tone on Channel C (Bit 2 = 0) and disable Noise on Channel C (Bit 5 = 1)
    ld a, (ay_mixer_val)
    and %11111011           ; Bit 2 = 0 (Tone C enabled)
    or  %00100000           ; Bit 5 = 1 (Noise C disabled)
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Fetch pitch for current drone_step
    ld a, (drone_step)
    add a, a                ; 2 bytes per pitch
    ld e, a
    ld d, 0
    ld hl, drone_pitches
    add hl, de

    ;; Channel C Fine Pitch (Reg 4)
    ld a, 4
    ld e, (hl)
    call WriteAY
    inc hl

    ;; Channel C Coarse Pitch (Reg 5)
    ld a, 5
    ld e, (hl)
    call WriteAY

    ;; Channel C Volume (Reg 10) = 8 (warm, rhythmic ambient bass)
    ld a, 10
    ld e, 8
    call WriteAY
    ret

.drone_exp_playing:
    ;; Advance timer in background so musical tempo stays synchronized
    ld a, (drone_timer)
    or a
    jp z, .drone_next_step
    dec a
    ld (drone_timer), a
    ret

.silence_drone:
    ld a, (drone_active)
    or a
    ret z                   ; Already silent

    xor a
    ld (drone_active), a
    ld (drone_timer), a
    ld (drone_step), a

    ;; If explosion is playing, let explosion handle Channel C
    ld a, (sfx_exp_timer)
    or a
    ret nz

    ;; Silence Channel C Tone
    ld a, 10
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00000100           ; Disable Tone C (Bit 2 = 1)
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    ret

;; Bonus-stage melody on Channel C. Channel A/B remain available for game SFX.
UpdateChallengingMusic:
    ld a, (drone_timer)
    or a
    jr z, .next_note
    dec a
    ld (drone_timer), a
    ret nz

.next_note:
    ld a, (drone_step)
    inc a
    and 15
    ld (drone_step), a
    add a, a
    ld e, a
    ld d, 0
    ld hl, challenging_music_pitches
    add hl, de
    ld e, (hl)
    inc hl
    ld d, (hl)
    ld (challenge_music_pitch), de
    ld a, 6
    ld (drone_timer), a

    ;; Let the explosion SFX use Channel C, then resume on the next note.
    ld a, (sfx_exp_timer)
    or a
    ret nz

    ld a, (ay_mixer_val)
    and %11111011
    or %00100000
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY
    ld de, (challenge_music_pitch)
    ld a, 4
    call WriteAY
    ld a, 5
    ld e, d
    call WriteAY
    ld a, 10
    ld e, 9
    call WriteAY
    ret

StopChallengingMusic:
    xor a
    ld (drone_active), a
    ld (drone_timer), a
    ld (drone_step), a
    ld a, (sfx_exp_timer)
    or a
    ret nz
    ld a, 10
    ld e, 0
    call WriteAY
    ld a, (ay_mixer_val)
    or %00000100
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    jp WriteAY

;; ----------------------------------------------------------------------------
;; WriteAY: Send byte E to AY-3-8912 register A
;; Input:  A = Register number (0..15), E = Data byte (0..255)
;; Preserves: HL, DE, BC
;; ----------------------------------------------------------------------------
WriteAY:
    push bc
    push af
    push de

    ;; 1. Send register number to 8255 Port A (#F400)
    ld b, #F4
    out (c), a

    ;; 2. Set Port C (#F600) to Latch Register (%11000000 = #C0)
    ld b, #F6
    in a, (c)
    and #3F
    or #C0
    out (c), a

    ;; 3. Return Port C to Inactive (%00000000)
    and #3F
    out (c), a

    ;; 4. Send data byte to 8255 Port A (#F400)
    pop de
    push de
    ld b, #F4
    ld a, e
    out (c), a

    ;; 5. Set Port C (#F600) to Write to PSG (%10000000 = #80)
    ld b, #F6
    in a, (c)
    and #3F
    or #80
    out (c), a

    ;; 6. Return Port C to Inactive (%00000000)
    and #3F
    out (c), a

    pop de
    pop af
    pop bc
    ret

;; ============================================================================
;; 3-Voice Polyphonic Music Player (Galaga Game Start Tune)
;; ============================================================================

;; ----------------------------------------------------------------------------
;; PlayMusicGameStart: Start authentic 3-voice Galaga Game Start Tune
;; (Transcribed from assets/game-start-tune.mid)
;; ----------------------------------------------------------------------------
PlayMusicGameStart:
    ld hl, game_start_tune_data
    jr PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlayMusicChallengingStart: Start 3-voice Challenging Stage Intro Fanfare
;; (Transcribed from assets/challenging_stage_start.wav)
;; ----------------------------------------------------------------------------
PlayMusicChallengingStart:
    ld hl, challenging_start_tune_data
    jr PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlayMusicChallengingResults: Start the 3-second Challenging Stage end tune
;; ----------------------------------------------------------------------------
PlayMusicChallengingResults:
    ld hl, challenging_end_tune_data
    jr PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlayMusicChallengingPerfect: Use the same end tune after a perfect stage
;; ----------------------------------------------------------------------------
PlayMusicChallengingPerfect:
    ld hl, challenging_end_tune_data
    jr PlayMusicFromHL

;; ----------------------------------------------------------------------------
;; PlayMusicFromHL: Generic 3-Voice Music Starter from (HL)
;; ----------------------------------------------------------------------------
PlayMusicFromHL:
    ;; Stop any running SFX
    xor a
    ld (sfx_shot_timer), a
    ld (sfx_exp_timer), a
    ld (sfx_dive_timer), a
    ld (sfx_jingle_timer), a
    ld (sfx_extend_timer), a
    ld (sfx_boss_dmg_timer), a
    ld (sfx_cap_destroy_timer), a

    ld a, 1
    ld (music_playing), a
    ld (music_step_timer), a    ; Step 0 triggers on next frame
    ld (music_ptr), hl

    ;; Set AY Mixer: Enable Tone on Channels A, B, C (bits 0, 1, 2 = 0)
    ;; Disable Noise on all channels (bits 3, 4, 5 = 1) -> #38
    ld a, #38
    ld (ay_mixer_val), a
    ld e, #38
    ld a, 7
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; StopMusic: Stop background music and silence all 3 channels
;; ----------------------------------------------------------------------------
StopMusic:
    xor a
    ld (music_playing), a
    ld (music_step_timer), a

    ;; Silence Volumes for Channels A, B, C
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, 9 : ld e, 0 : call WriteAY
    ld a, 10 : ld e, 0 : call WriteAY

    ;; Disable all Tones and Noise (#3F)
    ld a, #3F
    ld (ay_mixer_val), a
    ld e, #3F
    ld a, 7
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; UpdateMusicPlayer: Advance 3-channel music playback every frame (50Hz)
;; ----------------------------------------------------------------------------
UpdateMusicPlayer:
    ld a, (music_step_timer)
    dec a
    ld (music_step_timer), a
    jr z, .next_music_step

    ;; Check staccato cutoff on the very last frame of each note
    cp 1
    ret nz

    ;; 1-frame staccato articulation: silence volumes between notes
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, 9 : ld e, 0 : call WriteAY
    ld a, 10 : ld e, 0 : call WriteAY
    ret

.next_music_step:
    ld hl, (music_ptr)
    ld a, (hl)                  ; Duration byte
    or a
    jp z, StopMusic             ; 0 = End of song!

    ld (music_step_timer), a
    inc hl

    ;; Channel A Period (Reg 0 = fine, Reg 1 = coarse)
    ld e, (hl) : inc hl
    ld d, (hl) : inc hl
    ld a, e
    or d
    jr z, .music_step_rest      ; If Period A == 0, this step is a REST!

    ld a, 0 : call WriteAY
    ld e, d
    ld a, 1 : call WriteAY

    ;; Channel B Period (Reg 2 = fine, Reg 3 = coarse)
    ld e, (hl) : inc hl
    ld a, 2 : call WriteAY
    ld e, (hl) : inc hl
    ld a, 3 : call WriteAY

    ;; Channel C Period (Reg 4 = fine, Reg 5 = coarse)
    ld e, (hl) : inc hl
    ld a, 4 : call WriteAY
    ld e, (hl) : inc hl
    ld a, 5 : call WriteAY

    ;; Save updated music_ptr for next step
    ld (music_ptr), hl

    ;; Restore Tone mixer settings (#38 = Tone A, B, C enabled)
    ld a, (ay_mixer_val)
    and %11111000
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Set Channel Volumes (Lead=13, Harmony=10, Bass=13)
    ld a, 8 : ld e, 13 : call WriteAY
    ld a, 9 : ld e, 10 : call WriteAY
    ld a, 10 : ld e, 13 : call WriteAY
    ret

.music_step_rest:
    inc hl                      ; Skip Reg 2
    inc hl                      ; Skip Reg 3
    inc hl                      ; Skip Reg 4
    inc hl                      ; Skip Reg 5
    ld (music_ptr), hl

    ;; Silence Volumes for Channels A, B, C during rest
    ld a, 8 : ld e, 0 : call WriteAY
    ld a, 9 : ld e, 0 : call WriteAY
    ld a, 10 : ld e, 0 : call WriteAY
    ret

    include "tune_data.asm"
