;; ===========================================================================
;; config.asm - Overscan geometry, derived from CRTC register values.
;; Amstrad CPC Mode 0 (192 x 272 pixels in overscan)
;; Proven architecture from LoukoumasCPC (https://github.com/vaspervnp/LoukoumasCPC)
;; ===========================================================================

;; --- CRTC register values --------------------------------------------------
CRTC_R0     EQU 63          ; Horizontal total - 64 chars = 64 us
CRTC_R1     EQU 48          ; Horizontal displayed - 48 chars = 96 bytes = 192 px (mode 0)
CRTC_R2     EQU 50          ; HSYNC position - re-centres the wider window
CRTC_R3     EQU #8E         ; Sync widths: HSYNC 14 chars, VSYNC 8 lines
CRTC_R4     EQU 38          ; Vertical total - 39 rows
CRTC_R5     EQU 0           ; Vertical total adjust
CRTC_R6     EQU 34          ; Vertical displayed - 34 rows = 272 lines
CRTC_R7     EQU 34          ; VSYNC position - vertical centring knob
CRTC_R8     EQU 0           ; Non-interlaced
CRTC_R9     EQU 7           ; 8 scanlines per character row
CRTC_R12    EQU #2C         ; Display start high - MA = #2C10
CRTC_R13    EQU #10         ; Display start low

FRAME_LINES EQU (CRTC_R4+1)*(CRTC_R9+1)+CRTC_R5

;; --- Screen geometry -------------------------------------------------------
BYTES_PER_LINE  EQU CRTC_R1*2           ; 96 bytes
DISPLAY_ROWS    EQU CRTC_R6             ; 34 character rows
DISPLAY_LINES   EQU DISPLAY_ROWS*8      ; 272 scanlines

;; MA starts at #2C10:
;;   Page 2 (#8000), character offset 16 -> byte offset 32 in each 2K slice (#8020).
;; Rows 0..20 are 21*48 = 1008 characters and run from offset 16 to 1023,
;; exactly filling the 1024-character window of page 2. Row 21 begins at
;; MA #3000, which flips MA12 and moves the fetch into page 3 (#C000) with
;; the character offset back at 0.
PAGE2_ROWS      EQU 21
PAGE2_BASE      EQU #8000+32
PAGE3_BASE      EQU #C000

;; --- Gameplay layout: playfield on the left, HUD column on the right -------
;; The playfield fills bytes 0..71 of every scanline; the HUD column (score,
;; high score, short banners, lives and stage badges) fills bytes 72..95.
;; Y coordinates are stored in one byte, so sprites live between scanline
;; PF_Y_TOP and SPRITE_Y_LIMIT (a 16-line sprite then ends at scanline 267).
PF_X0           EQU 0
PF_W            EQU 72                  ; 3/4 of the 96-byte overscan width
PF_X_CENTER     EQU PF_X0 + PF_W / 2    ; 36
HUD_X           EQU PF_X0 + PF_W        ; 72
HUD_W           EQU BYTES_PER_LINE - HUD_X ; 24 bytes = 8 characters

PF_Y_TOP        EQU 8                   ; Highest scanline a sprite may start
SPRITE_Y_LIMIT  EQU 252                 ; Sprites at Y >= this are off-screen

;; Playfield coordinate limits (left edge of a 16x16 sprite)
PLAY_X_MIN      EQU PF_X0 + 2           ; 2
PLAY_X_MAX      EQU PF_X0 + PF_W - 10   ; 62

;; The pre-column layout put the playfield 12 bytes further right and its top
;; at scanline 36; positions tied to the top of the playfield move by this.
PF_OLD_DX       EQU -12
PF_OLD_DY       EQU PF_Y_TOP - 36       ; -28

;; --- Title / initials screens keep the original top HUD --------------------
TITLE_HUD_Y0    EQU 6
TITLE_HUD_Y1    EQU 16

;; --- HUD column contents ----------------------------------------------------
;; Thin divider: right pixel of the last playfield byte, Pen 1 (blue). Sprites,
;; bullets and explosions never reach this byte, so nothing erases it.
HUD_DIVIDER_X    EQU HUD_X - 1
HUD_DIVIDER_BYTE EQU #40
HUD_TEXT_X      EQU HUD_X + 1
HUD_HIGH_Y      EQU 12                  ; "HIGH" / "SCORE" + high score on top
HUD_HIGH2_Y     EQU 22
HUD_HISCORE_Y   EQU 32
HUD_1UP_Y       EQU 46                  ; "1UP" + player 1 score below
HUD_SCORE_Y     EQU 56
HUD_2UP_Y       EQU 70                  ; "2UP" + player 2 score (2-player game)
HUD_SCORE2_Y    EQU 80
LIVES_X         EQU HUD_X + 4       ; Reserve ships: 2 x 2 grid (184..217)
LIVES_Y         EQU 184
;; Stage ribbons: two rows right below the reserve ships. Displays commonly
;; crop the lowest overscan lines, so the second row ends at scanline 255.
BADGES_Y        EQU 222             ; Row 1: 222..237
BADGES_Y2       EQU BADGES_Y + 18   ; Row 2: 240..255

;; Centre of the playfield for large text (GAME OVER, results)
PF_TEXT_Y       EQU 128                 ; On a character row: fast text
    assert (PF_TEXT_Y & 7) == 0
