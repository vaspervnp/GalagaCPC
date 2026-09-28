;; ============================================================================
;; Galaga CPC - Game Start Tune Data (from assets/game-start-tune.mid)
;; 3-Voice Polyphonic Arrangement: Ch A = Lead, Ch B = Harmony, Ch C = Bass
;; Format: defb duration_frames, defw period_a, period_b, period_c
;; ============================================================================

game_start_tune_data:
    defb 15 : defw #009F, #00BE, #027E  ; Step  0: Lead N67, Harm N64, Bass N43
    defb  5 : defw #0077, #013F, #027E  ; Step  1: Lead N72, Harm N55, Bass N43
    defb 15 : defw #006A, #00D5, #0238  ; Step  2: Lead N74, Harm N62, Bass N45
    defb  5 : defw #0059, #011C, #01DE  ; Step  3: Lead N77, Harm N57, Bass N48
    defb 15 : defw #005F, #00EF, #01FA  ; Step  4: Lead N76, Harm N60, Bass N47
    defb  5 : defw #0077, #013F, #01FA  ; Step  5: Lead N72, Harm N55, Bass N47
    defb 15 : defw #006A, #011C, #027E  ; Step  6: Lead N74, Harm N57, Bass N43
    defb  5 : defw #0047, #00FD, #027E  ; Step  7: Lead N81, Harm N59, Bass N43
    defb 15 : defw #0050, #00BE, #01DE  ; Step  8: Lead N79, Harm N64, Bass N48
    defb  5 : defw #0077, #013F, #01DE  ; Step  9: Lead N72, Harm N55, Bass N48
    defb 15 : defw #006A, #00D5, #01AA  ; Step 10: Lead N74, Harm N62, Bass N50
    defb  5 : defw #0059, #011C, #0166  ; Step 11: Lead N77, Harm N57, Bass N53
    defb 15 : defw #005F, #00EF, #017B  ; Step 12: Lead N76, Harm N60, Bass N52
    defb  5 : defw #0077, #013F, #017B  ; Step 13: Lead N72, Harm N55, Bass N52
    defb 15 : defw #0050, #00D5, #01AA  ; Step 14: Lead N79, Harm N62, Bass N50
    defb  5 : defw #003F, #009F, #01AA  ; Step 15: Lead N83, Harm N67, Bass N50
    defb 15 : defw #003C, #0096, #0192  ; Step 16: Lead N84, Harm N68, Bass N51
    defb  5 : defw #0043, #009F, #0192  ; Step 17: Lead N82, Harm N67, Bass N51
    defb 15 : defw #004B, #00B3, #01AA  ; Step 18: Lead N80, Harm N65, Bass N50
    defb  5 : defw #0050, #00C9, #01DE  ; Step 19: Lead N79, Harm N63, Bass N48
    defb 15 : defw #0059, #00D5, #0218  ; Step 20: Lead N77, Harm N62, Bass N46
    defb  5 : defw #0064, #00EF, #0218  ; Step 21: Lead N75, Harm N60, Bass N46
    defb 15 : defw #006A, #010C, #0192  ; Step 22: Lead N74, Harm N58, Bass N51
    defb  5 : defw #0086, #00D5, #0192  ; Step 23: Lead N70, Harm N62, Bass N51
    defb 15 : defw #0043, #00C9, #010C  ; Step 24: Lead N82, Harm N63, Bass N58
    defb  5 : defw #003C, #00B3, #010C  ; Step 25: Lead N84, Harm N65, Bass N58
    defb 15 : defw #0043, #00C9, #013F  ; Step 26: Lead N82, Harm N63, Bass N55
    defb  5 : defw #0050, #00EF, #013F  ; Step 27: Lead N79, Harm N60, Bass N55
    defb  8 : defw #0047, #00B3, #01AA  ; Step 28: Lead N81, Harm N65, Bass N50
    defb  8 : defw #0059, #00D5, #01AA  ; Step 29: Lead N77, Harm N62, Bass N50
    defb  8 : defw #006A, #011C, #01AA  ; Step 30: Lead N74, Harm N57, Bass N50
    defb  8 : defw #0050, #00D5, #013F  ; Step 31: Lead N79, Harm N62, Bass N55
    defb  8 : defw #005F, #00FD, #013F  ; Step 32: Lead N76, Harm N59, Bass N55
    defb  7 : defw #006A, #011C, #017B  ; Step 33: Lead N74, Harm N57, Bass N52
    defb 0  ; End of tune marker

;; ============================================================================
;; Challenging Stage Start Fanfare (from assets/challenging_stage_start.wav)
;; 3-Voice Polyphonic Fanfare: Plays when "CHALLENGING STAGE" banner is shown!
;; Duration: 48 frames (~0.96 seconds)
;; ============================================================================
challenging_start_tune_data:
    defb 11 : defw #0068, #008A, #00A5  ; Step 0: D chord (Lead 600Hz, Harm 451Hz, Bass 378Hz)
    defb  5 : defw #0000, #0000, #0000  ; Step 1: Rest (100ms)
    defb  5 : defw #0068, #008A, #00A5  ; Step 2: D chord
    defb  5 : defw #0062, #0083, #009C  ; Step 3: Eb chord (Lead 636Hz, Harm 478Hz, Bass 401Hz)
    defb  5 : defw #0057, #0075, #008B  ; Step 4: F chord (Lead 715Hz, Harm 536Hz, Bass 448Hz)
    defb 17 : defw #004E, #0068, #007B  ; Step 5: G chord (Lead 803Hz, Harm 601Hz, Bass 507Hz)
    defb  0                             ; End of tune marker


;; ============================================================================
;; Challenging Stage Results Theme (from assets/challenging_stage_results.wav)
;; 3-Voice Polyphonic: Plays on Results screen when hits < 40
;; ============================================================================
challenging_results_tune_data:
    defb 15 : defw #0050, #013F, #013F  ; Lead N79, Harm N55, Bass N55
    defb  5 : defw #003C, #0050, #00FD  ; Lead N84, Harm N79, Bass N59
    defb  3 : defw #0035, #0050, #00D5  ; Lead N86, Harm N79, Bass N62
    defb  5 : defw #0035, #0050, #011C  ; Lead N86, Harm N79, Bass N57
    defb  3 : defw #0035, #003C, #00E1  ; Lead N86, Harm N84, Bass N61
    defb  2 : defw #0035, #003C, #00E1  ; Lead N86, Harm N84, Bass N61
    defb  2 : defw #0035, #0050, #00D5  ; Lead N86, Harm N79, Bass N62
    defb 18 : defw #002D, #0050, #013F  ; Lead N89, Harm N79, Bass N55
    defb  2 : defw #002F, #0035, #00BE  ; Lead N88, Harm N86, Bass N64
    defb  4 : defw #002F, #0035, #00D5  ; Lead N88, Harm N86, Bass N62
    defb  3 : defw #002F, #0035, #00C9  ; Lead N88, Harm N86, Bass N63
    defb 11 : defw #002D, #0035, #00C9  ; Lead N89, Harm N86, Bass N63
    defb  4 : defw #002F, #0035, #00C9  ; Lead N88, Harm N86, Bass N63
    defb  6 : defw #002F, #0035, #00C9  ; Lead N88, Harm N86, Bass N63
    defb  5 : defw #0028, #003C, #00D5  ; Lead N91, Harm N84, Bass N62
    defb  4 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb  3 : defw #0028, #0035, #00E1  ; Lead N91, Harm N86, Bass N61
    defb  4 : defw #0028, #003C, #00E1  ; Lead N91, Harm N84, Bass N61
    defb  3 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb  4 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb  4 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb  7 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb 34 : defw #0028, #0035, #00E1  ; Lead N91, Harm N86, Bass N61
    defb  4 : defw #0028, #002F, #009F  ; Lead N91, Harm N88, Bass N67
    defb  3 : defw #0028, #002F, #009F  ; Lead N91, Harm N88, Bass N67
    defb  3 : defw #0028, #002F, #009F  ; Lead N91, Harm N88, Bass N67
    defb  4 : defw #0028, #0077, #00EF  ; Lead N91, Harm N72, Bass N60
    defb  6 : defw #0028, #0077, #0096  ; Lead N91, Harm N72, Bass N68
    defb 16 : defw #0028, #0077, #0096  ; Lead N91, Harm N72, Bass N68
    defb  2 : defw #0026, #008E, #008E  ; Lead N92, Harm N69, Bass N69
    defb 12 : defw #0026, #0086, #0086  ; Lead N92, Harm N70, Bass N70
    defb 10 : defw #0026, #002D, #009F  ; Lead N92, Harm N89, Bass N67
    defb  2 : defw #0026, #002D, #0096  ; Lead N92, Harm N89, Bass N68
    defb 31 : defw #0026, #002D, #00B3  ; Lead N92, Harm N89, Bass N65
    defb  9 : defw #0035, #0086, #00D5  ; Lead N86, Harm N70, Bass N62
    defb  3 : defw #0035, #0077, #00D5  ; Lead N86, Harm N72, Bass N62
    defb  5 : defw #0035, #0071, #00D5  ; Lead N86, Harm N73, Bass N62
    defb  8 : defw #0043, #0086, #00FD  ; Lead N82, Harm N70, Bass N59
    defb  8 : defw #0077, #0077, #0077  ; Lead N72, Harm N72, Bass N72
    defb  5 : defw #0086, #0086, #0086  ; Lead N70, Harm N70, Bass N70
    defb 15 : defw #0071, #008E, #008E  ; Lead N73, Harm N69, Bass N69
    defb  2 : defw #0028, #002D, #009F  ; Lead N91, Harm N89, Bass N67
    defb 12 : defw #0028, #002D, #00A9  ; Lead N91, Harm N89, Bass N66
    defb  7 : defw #0028, #002D, #00B3  ; Lead N91, Harm N89, Bass N65
    defb  3 : defw #002F, #0035, #00BE  ; Lead N88, Harm N86, Bass N64
    defb  2 : defw #002F, #0035, #00BE  ; Lead N88, Harm N86, Bass N64
    defb  8 : defw #0028, #0035, #00D5  ; Lead N91, Harm N86, Bass N62
    defb  2 : defw #002F, #00BE, #00BE  ; Lead N88, Harm N64, Bass N64
    defb  4 : defw #002F, #00B3, #00B3  ; Lead N88, Harm N65, Bass N65
    defb  7 : defw #0035, #00D5, #00D5  ; Lead N86, Harm N62, Bass N62
    defb  1 : defw #0000, #0000, #0000  ; Rest (20ms)
    defb  0  ; End marker


;; ============================================================================
;; Challenging Stage Perfect Victory Fanfare (from assets/challenging_stage_perfect.wav)
;; 3-Voice Polyphonic: Plays on Results screen when 40/40 hits (SPECIAL 10000 PTS)
;; ============================================================================
challenging_perfect_tune_data:
    defb  2 : defw #002F, #0050, #00E1  ; Lead N88, Harm N79, Bass N61
    defb 10 : defw #002F, #0050, #00E1  ; Lead N88, Harm N79, Bass N61
    defb 13 : defw #0028, #0050, #00E1  ; Lead N91, Harm N79, Bass N61
    defb  4 : defw #002D, #003F, #013F  ; Lead N89, Harm N83, Bass N55
    defb  4 : defw #0028, #0035, #013F  ; Lead N91, Harm N86, Bass N55
    defb  7 : defw #002F, #0050, #00E1  ; Lead N88, Harm N79, Bass N61
    defb  3 : defw #002F, #0050, #00EF  ; Lead N88, Harm N79, Bass N60
    defb  4 : defw #002F, #0050, #00EF  ; Lead N88, Harm N79, Bass N60
    defb 11 : defw #0028, #0035, #00EF  ; Lead N91, Harm N86, Bass N60
    defb  4 : defw #002D, #003F, #013F  ; Lead N89, Harm N83, Bass N55
    defb  2 : defw #0028, #0035, #013F  ; Lead N91, Harm N86, Bass N55
    defb 16 : defw #0028, #003F, #013F  ; Lead N91, Harm N83, Bass N55
    defb  7 : defw #0028, #0050, #00E1  ; Lead N91, Harm N79, Bass N61
    defb  2 : defw #002D, #0059, #013F  ; Lead N89, Harm N77, Bass N55
    defb  6 : defw #002D, #006A, #013F  ; Lead N89, Harm N74, Bass N55
    defb 10 : defw #0028, #003F, #013F  ; Lead N91, Harm N83, Bass N55
    defb  6 : defw #002F, #003F, #00E1  ; Lead N88, Harm N83, Bass N61
    defb 11 : defw #0028, #0050, #00EF  ; Lead N91, Harm N79, Bass N60
    defb  6 : defw #002D, #006A, #013F  ; Lead N89, Harm N74, Bass N55
    defb  4 : defw #0028, #003F, #013F  ; Lead N91, Harm N83, Bass N55
    defb  2 : defw #0026, #003C, #012D  ; Lead N92, Harm N84, Bass N56
    defb  2 : defw #0000, #0000, #0000  ; Rest (40ms)
    defb  3 : defw #0026, #003C, #012D  ; Lead N92, Harm N84, Bass N56
    defb  5 : defw #0000, #0000, #0000  ; Rest (100ms)
    defb  3 : defw #0026, #003C, #012D  ; Lead N92, Harm N84, Bass N56
    defb  5 : defw #0000, #0000, #0000  ; Rest (100ms)
    defb  3 : defw #0026, #003C, #012D  ; Lead N92, Harm N84, Bass N56
    defb  4 : defw #0000, #0000, #0000  ; Rest (80ms)
    defb  4 : defw #0000, #0000, #0000  ; Rest (80ms)
    defb  9 : defw #0000, #0000, #0000  ; Rest (180ms)
    defb  8 : defw #0000, #0000, #0000  ; Rest (160ms)
    defb  8 : defw #0000, #0000, #0000  ; Rest (160ms)
    defb  8 : defw #0000, #0000, #0000  ; Rest (160ms)
    defb  2 : defw #0000, #0000, #0000  ; Rest (40ms)
    defb  2 : defw #003C, #0047, #00B3  ; Lead N84, Harm N81, Bass N65
    defb  2 : defw #003C, #0059, #00B3  ; Lead N84, Harm N77, Bass N65
    defb  2 : defw #002F, #0047, #008E  ; Lead N88, Harm N81, Bass N69
    defb  2 : defw #002F, #0059, #008E  ; Lead N88, Harm N77, Bass N69
    defb  5 : defw #0028, #0059, #0077  ; Lead N91, Harm N77, Bass N72
    defb  4 : defw #0047, #0059, #0059  ; Lead N81, Harm N77, Bass N77
    defb  4 : defw #0028, #0047, #0077  ; Lead N91, Harm N81, Bass N72
    defb  2 : defw #0028, #0047, #0077  ; Lead N91, Harm N81, Bass N72
    defb  2 : defw #0028, #0077, #0077  ; Lead N91, Harm N72, Bass N72
    defb  4 : defw #002F, #0047, #00B3  ; Lead N88, Harm N81, Bass N65
    defb  2 : defw #003C, #0047, #00B3  ; Lead N84, Harm N81, Bass N65
    defb  3 : defw #003C, #00B3, #00B3  ; Lead N84, Harm N65, Bass N65
    defb  9 : defw #0000, #0000, #0000  ; Rest (180ms)
    defb  3 : defw #0026, #0026, #0026  ; Lead N92, Harm N92, Bass N92
    defb  2 : defw #0028, #0028, #0028  ; Lead N91, Harm N91, Bass N91
    defb  3 : defw #002A, #002A, #002A  ; Lead N90, Harm N90, Bass N90
    defb  2 : defw #002D, #002D, #002D  ; Lead N89, Harm N89, Bass N89
    defb  3 : defw #002F, #002F, #002F  ; Lead N88, Harm N88, Bass N88
    defb  2 : defw #0032, #0032, #0032  ; Lead N87, Harm N87, Bass N87
    defb  3 : defw #0035, #0035, #0035  ; Lead N86, Harm N86, Bass N86
    defb  2 : defw #0038, #0038, #0038  ; Lead N85, Harm N85, Bass N85
    defb  3 : defw #003C, #003C, #003C  ; Lead N84, Harm N84, Bass N84
    defb  2 : defw #003F, #003F, #003F  ; Lead N83, Harm N83, Bass N83
    defb  3 : defw #0043, #0043, #0043  ; Lead N82, Harm N82, Bass N82
    defb  2 : defw #0047, #0047, #0047  ; Lead N81, Harm N81, Bass N81
    defb  3 : defw #0026, #004B, #004B  ; Lead N92, Harm N80, Bass N80
    defb  2 : defw #0028, #0050, #0050  ; Lead N91, Harm N79, Bass N79
    defb  3 : defw #002A, #0054, #0054  ; Lead N90, Harm N78, Bass N78
    defb  2 : defw #002D, #0059, #0059  ; Lead N89, Harm N77, Bass N77
    defb  2 : defw #002F, #005F, #005F  ; Lead N88, Harm N76, Bass N76
    defb  3 : defw #0032, #0064, #0064  ; Lead N87, Harm N75, Bass N75
    defb  2 : defw #0035, #006A, #006A  ; Lead N86, Harm N74, Bass N74
    defb  3 : defw #0026, #0038, #0071  ; Lead N92, Harm N85, Bass N73
    defb  2 : defw #0028, #003C, #0077  ; Lead N91, Harm N84, Bass N72
    defb  3 : defw #002A, #003F, #007F  ; Lead N90, Harm N83, Bass N71
    defb  2 : defw #002D, #0043, #0086  ; Lead N89, Harm N82, Bass N70
    defb  3 : defw #002F, #0047, #008E  ; Lead N88, Harm N81, Bass N69
    defb  3 : defw #0032, #004B, #0096  ; Lead N87, Harm N80, Bass N68
    defb  2 : defw #0035, #0050, #009F  ; Lead N86, Harm N79, Bass N67
    defb  2 : defw #0038, #0054, #009F  ; Lead N85, Harm N78, Bass N67
    defb  3 : defw #003C, #0059, #00B3  ; Lead N84, Harm N77, Bass N65
    defb  2 : defw #0026, #003F, #00BE  ; Lead N92, Harm N83, Bass N64
    defb  3 : defw #0028, #0043, #00C9  ; Lead N91, Harm N82, Bass N63
    defb  2 : defw #002A, #0047, #00D5  ; Lead N90, Harm N81, Bass N62
    defb  3 : defw #0026, #004B, #00E1  ; Lead N92, Harm N80, Bass N61
    defb  2 : defw #0028, #0050, #00E1  ; Lead N91, Harm N79, Bass N61
    defb  5 : defw #002A, #0054, #00FD  ; Lead N90, Harm N78, Bass N59
    defb  3 : defw #002F, #005F, #011C  ; Lead N88, Harm N76, Bass N57
    defb  3 : defw #0000, #0000, #0000  ; Rest (60ms)
    defb  0  ; End marker

