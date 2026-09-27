;; ============================================================================
;; Galaga CPC - AY-3-8912 Sound Effects Engine
;; Amstrad CPC 464 / 6128 PSG Sound Driver
;; ============================================================================

;; Current mixer settings (Reg 7, 0=enabled, 1=disabled)
;; Default: All tone and noise disabled (#3F)
ay_mixer_val:       defb #3F

;; Sound FX Timers & State
sfx_shot_timer:     defb 0
sfx_shot_pitch:     defb 0

sfx_exp_timer:      defb 0
sfx_exp_vol:        defb 0

sfx_dive_timer:     defb 0
sfx_dive_pitch:     defb 0

sfx_jingle_timer:   defb 0
sfx_jingle_step:    defb 0

;; ----------------------------------------------------------------------------
;; SoundInit: Silence all 3 AY channels and reset sound state
;; ----------------------------------------------------------------------------
SoundInit:
    xor a
    ld (sfx_shot_timer), a
    ld (sfx_exp_timer), a
    ld (sfx_dive_timer), a
    ld (sfx_jingle_timer), a


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
;; PlaySoundShot: Classic Galaga Laser Firing Chirp (Channel A)
;; ----------------------------------------------------------------------------
PlaySoundShot:
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

    ;; Enable Noise on Channel C (Bit 5 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11011111
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
;; PlaySoundDive: Alien Dive-bombing Warble (Channel B)
;; ----------------------------------------------------------------------------
PlaySoundDive:
    ld a, 18                ; 18 frames duration
    ld (sfx_dive_timer), a
    ld a, 120
    ld (sfx_dive_pitch), a

    ;; Enable Tone on Channel B (Bit 1 of Reg 7 = 0)
    ld a, (ay_mixer_val)
    and %11111101
    ld (ay_mixer_val), a
    ld e, a
    ld a, 7
    call WriteAY

    ;; Channel B Volume = 11
    ld a, 9
    ld e, 11
    call WriteAY
    ret

;; ----------------------------------------------------------------------------
;; PlaySoundTractor: Tractor Beam Pulsing Tone (Channel B)
;; ----------------------------------------------------------------------------
PlaySoundTractor:
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
;; PlaySoundRescue: Triumphant Dual Fighter Rescue Chime (Channel A)
;; ----------------------------------------------------------------------------
PlaySoundRescue:
    ld a, 30
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
;; PlaySoundExtraLife: High Ascending Fanfare (Channel A)
;; ----------------------------------------------------------------------------
PlaySoundExtraLife:
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
;; SoundUpdate: Called once per frame (50Hz) to advance envelopes and pitch
;; ----------------------------------------------------------------------------
SoundUpdate:
    ;; --- 0. Update Jingle / Fanfare (Channel A) ---
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
    jr .check_exp

.jingle_continue:
    ;; Step pitch upward
    ld a, (sfx_jingle_timer)
    and 7
    jr nz, .check_exp
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
    jr .check_exp

.check_shot:

    ;; --- 1. Update Laser Shot (Channel A) ---
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
    jr .check_exp

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
    jr z, .check_dive

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
    jr .check_dive

.exp_continue:
    ld a, (sfx_exp_vol)
    or a
    jr z, .check_dive
    dec a
    ld (sfx_exp_vol), a
    ld e, a
    ld a, 10                ; Reg 10: Channel C Volume
    call WriteAY

.check_dive:
    ;; --- 3. Update Dive Warble (Channel B) ---
    ld a, (sfx_dive_timer)
    or a
    ret z

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
    ret

.dive_continue:
    ;; Warble pitch back and forth
    and 3
    cp 2
    jr c, .dive_pitch_low
    ld a, 110
    jr .dive_apply_pitch
.dive_pitch_low:
    ld a, 160
.dive_apply_pitch:
    ld (sfx_dive_pitch), a
    ld e, a
    ld a, 2                 ; Reg 2: Channel B Fine Pitch
    call WriteAY
    ld a, 3                 ; Reg 3: Channel B Coarse Pitch = 0
    ld e, 0
    call WriteAY
    ret

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
