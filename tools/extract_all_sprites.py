from PIL import Image
import os

img = Image.open('assets/galagaSpriteMap.png')
palette = img.getpalette()

def extract_tile(col, row, rotate_deg=0):
    x = 1 + col * 18
    y = 1 + row * 18
    crop = img.crop((x, y, x+16, y+16))
    if rotate_deg:
        crop = crop.rotate(rotate_deg)
    return crop

def rgb_to_cpc_pen(r, g, b, is_transparent):
    if is_transparent:
        return 0  # Black / Transparent (Pen 0)
    # White
    if r > 200 and g > 200 and b > 200:
        return 15 # Bright White (Pen 15)
    # Red
    elif r > 180 and g < 100 and b < 100:
        return 2  # Bright Red (Pen 2)
    # Yellow
    elif r > 180 and g > 180 and b < 100:
        return 3  # Bright Yellow (Pen 3)
    # Cyan
    elif r < 100 and g > 180 and b > 180:
        return 4  # Bright Cyan (Pen 4)
    # Magenta / Violet
    elif r > 150 and g < 100 and b > 150:
        return 5  # Bright Magenta (Pen 5)
    # Green
    elif r < 100 and g > 180 and b < 100:
        return 6  # Bright Green (Pen 6)
    # Blue
    elif b > 180 and r < 120 and g < 150:
        return 1  # Bright Blue (Pen 1)
    # Dark outline / Black / Grid line
    elif (r, g, b) in [(0, 0, 0), (64, 64, 64)] or (r < 50 and g < 50 and b < 50):
        return 0  # Black (Pen 0)
    return 0

def encode_mode0_byte(p0, p1):
    # p0 = left pixel (0-15), p1 = right pixel (0-15)
    # CPC Mode 0 encoding:
    # Bit 7: p0 b0, Bit 6: p1 b0
    # Bit 5: p0 b2, Bit 4: p1 b2
    # Bit 3: p0 b1, Bit 2: p1 b1
    # Bit 1: p0 b3, Bit 0: p1 b3
    b7 = (p0 & 1) << 7
    b6 = (p1 & 1) << 6
    b5 = ((p0 >> 2) & 1) << 5
    b4 = ((p1 >> 2) & 1) << 4
    b3 = ((p0 >> 1) & 1) << 3
    b2 = ((p1 >> 1) & 1) << 2
    b1 = ((p0 >> 3) & 1) << 1
    b0 = ((p1 >> 3) & 1) << 0
    return b7 | b6 | b5 | b4 | b3 | b2 | b1 | b0

def tile_to_cpc_asm(tile, label):
    asm_lines = [f";; Sprite: {label} (16x16, 8 bytes x 16 lines)", f"{label}:"]
    for y in range(16):
        bytes_row = []
        for x in range(0, 16, 2):
            idx0 = tile.getpixel((x, y))
            idx1 = tile.getpixel((x+1, y))
            
            r0, g0, b0 = palette[idx0*3:idx0*3+3]
            r1, g1, b1 = palette[idx1*3:idx1*3+3]
            
            is_trans0 = (idx0 == 0 or (r0, g0, b0) in [(0,0,0), (64,64,64)])
            is_trans1 = (idx1 == 0 or (r1, g1, b1) in [(0,0,0), (64,64,64)])
            
            p0 = rgb_to_cpc_pen(r0, g0, b0, is_trans0)
            p1 = rgb_to_cpc_pen(r1, g1, b1, is_trans1)
            
            val = encode_mode0_byte(p0, p1)
            bytes_row.append(f"#{val:02X}")
        asm_lines.append("    defb " + ", ".join(bytes_row) + f"  ; Line {y}")
    return "\n".join(asm_lines)

# All Spaceship & Enemy Sprites (strictly 16x16 pixels on black background)
sprites_16x16 = [
    ("player_sprite", 0, 0, 270, "Player Fighter"),
    ("captured_player_sprite", 0, 1, 270, "Captured Red Fighter"),
    ("zako_bee_1", 0, 2, 270, "Zako Bee Frame 1 (Wings Open)"),
    ("zako_bee_2", 1, 2, 270, "Zako Bee Frame 2 (Wings Closed)"),
    ("goei_butterfly_1", 0, 3, 270, "Goei Butterfly Frame 1 (Wings Open)"),
    ("goei_butterfly_2", 1, 3, 270, "Goei Butterfly Frame 2 (Wings Closed)"),
    ("boss_galaga_damaged", 0, 4, 270, "Boss Galaga Damaged Frame 1 (Blue)"),
    ("boss_galaga_damaged_2", 1, 4, 270, "Boss Galaga Damaged Frame 2 (Blue)"),
    ("boss_galaga_1", 0, 5, 270, "Boss Galaga Frame 1 (Green)"),
    ("boss_galaga_2", 1, 5, 270, "Boss Galaga Frame 2 (Green)"),
    ("tonbo_dragonfly", 0, 6, 270, "Tonbo Dragonfly (Bonus/Challenge Target)"),
    ("momiji_satellite", 0, 7, 270, "Momiji Satellite (Bonus/Challenge Target)"),
    ("enterprise_bonus", 0, 8, 270, "Enterprise Flagship (Bonus/Challenge Target)"),
    ("sasori_scorpion", 0, 9, 270, "Sasori Scorpion (Transform Stage 4-6)"),
    ("midori_stingray_1", 8, 10, 0, "Midori Stingray Frame 1 (Transform Stage 7-9)"),
    ("midori_stingray_2", 9, 10, 0, "Midori Stingray Frame 2 (Transform Stage 7-9)"),
    ("galboss_flagship_1", 0, 11, 270, "Galboss Galaxian Flagship Frame 1 (Transform Stage 10-12)"),
    ("galboss_flagship_2", 1, 11, 270, "Galboss Galaxian Flagship Frame 2 (Transform Stage 10-12)"),
]

# 4 Authentic Arcade Explosions (16x16 center extracted from 32x32 boxes)
explosion_boxes = [
    ("explosion_1", 289, 1, 321, 33, "Explosion Frame 1"),
    ("explosion_2", 323, 1, 355, 33, "Explosion Frame 2"),
    ("explosion_3", 357, 1, 389, 33, "Explosion Frame 3"),
    ("explosion_4", 391, 1, 423, 33, "Explosion Frame 4"),
]

all_asm = [";; ============================================================================",
           ";; Galaga CPC - Complete Authentic Spritesheet",
           ";; Auto-generated from assets/galagaSpriteMap.png",
           ";; Strictly 16x16 pixels per tile on Pure Black Background",
           ";; ============================================================================\n"]

# 1. Convert Spaceships & Enemies
all_asm.append(";; --- Spaceships & Enemies (16x16) ---")
for label, col, row, rot, desc in sprites_16x16:
    tile = extract_tile(col, row, rot)
    preview = Image.new('RGB', (16, 16), (0, 0, 0))
    for y in range(16):
        for x in range(16):
            idx = tile.getpixel((x, y))
            r, g, b = palette[idx*3:idx*3+3]
            if (r, g, b) not in [(0,0,0), (64,64,64)]:
                preview.putpixel((x, y), (r, g, b))
    preview.save(f"assets/{label}.bmp")
    all_asm.append(tile_to_cpc_asm(tile, label) + "\n")

# 2. Convert Explosions
all_asm.append(";; --- Enemy Explosions (16x16) ---")
for label, x1, y1, x2, y2, desc in explosion_boxes:
    crop32 = img.crop((x1, y1, x2, y2)).rotate(270)
    tile = crop32.crop((8, 8, 24, 24))  # 16x16 center
    preview = Image.new('RGB', (16, 16), (0, 0, 0))
    for y in range(16):
        for x in range(16):
            idx = tile.getpixel((x, y))
            r, g, b = palette[idx*3:idx*3+3]
            if (r, g, b) not in [(0,0,0), (64,64,64)]:
                preview.putpixel((x, y), (r, g, b))
    preview.save(f"assets/{label}.bmp")
    all_asm.append(tile_to_cpc_asm(tile, label) + "\n")

with open('src/sprites.asm', 'w') as f:
    f.write("\n".join(all_asm))

# Also update player_sprite.asm
player_tile = extract_tile(0, 0, 270)
with open('src/player_sprite.asm', 'w') as f:
    f.write(tile_to_cpc_asm(player_tile, "player_sprite"))

print("SUCCESS: Generated src/sprites.asm with all 16x16 sprites!")
