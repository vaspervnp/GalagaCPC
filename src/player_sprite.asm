;; Sprite: player_sprite (16x16, 8 bytes x 16 lines)
player_sprite:
    defb #00, #00, #00, #00, #AA, #00, #00, #00  ; Line 0
    defb #00, #00, #00, #00, #AA, #00, #00, #00  ; Line 1
    defb #00, #00, #00, #00, #AA, #00, #00, #00  ; Line 2
    defb #00, #00, #00, #55, #FF, #00, #00, #00  ; Line 3
    defb #00, #00, #00, #55, #FF, #00, #00, #00  ; Line 4
    defb #00, #00, #08, #55, #FF, #00, #08, #00  ; Line 5
    defb #00, #00, #08, #55, #FF, #00, #08, #00  ; Line 6
    defb #00, #00, #AA, #FF, #FF, #AA, #AA, #00  ; Line 7
    defb #04, #00, #EA, #FF, #5D, #EA, #AA, #04  ; Line 8
    defb #04, #00, #D5, #AE, #0C, #FF, #80, #04  ; Line 9
    defb #55, #00, #FF, #AE, #AE, #FF, #AA, #55  ; Line 10
    defb #55, #55, #FF, #FF, #FF, #FF, #FF, #55  ; Line 11
    defb #55, #FF, #FF, #5D, #FF, #5D, #FF, #FF  ; Line 12
    defb #55, #FF, #04, #5D, #FF, #0C, #55, #FF  ; Line 13
    defb #55, #AA, #04, #08, #AA, #0C, #00, #FF  ; Line 14
    defb #55, #00, #00, #00, #AA, #00, #00, #55  ; Line 15