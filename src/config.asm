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

;; --- Layout of Upper Border, Playfield, and Lower Border --------------------
;; Upper Border: Scanlines 0..31 (Rows 0..3: 32 scanlines) -> HUD
HUD_Y0          EQU 6
HUD_Y1          EQU 16

;; Main Playfield: Scanlines 32..231 (Rows 4..28: 200 scanlines, 80 bytes wide)
INNER_X0        EQU (CRTC_R2-46)*2      ; 8 bytes
INNER_W         EQU 80                  ; 80 bytes (160 px Mode 0)
INNER_Y0        EQU (CRTC_R7-30)*8      ; 32 scanlines
INNER_H         EQU 200                 ; 200 scanlines

;; Playfield coordinate limits
PLAY_X_MIN      EQU INNER_X0 + 2        ; 10
PLAY_X_MAX      EQU INNER_X0 + INNER_W - 10 ; 78
PLAY_Y_MIN      EQU INNER_Y0            ; 32
PLAY_Y_MAX      EQU INNER_Y0 + INNER_H - 16 ; 216

;; Lower Border: Scanlines 232..271 (Rows 29..33: 40 scanlines) -> Lives & Badges
LOWER_BORDER_Y  EQU 232
LIVES_Y         EQU 244
BADGES_Y        EQU 244
