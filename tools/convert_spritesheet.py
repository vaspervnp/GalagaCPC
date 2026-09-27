from PIL import Image
import os

img = Image.open('assets/galagaSpriteMap.png')
palette = img.getpalette()

# Extract tile from grid: col (0..24), row (0..11)
def extract_tile(col, row, rotate_deg=270):
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
    # Dark outline / Black
    elif r < 50 and g < 50 and b < 50:
        return 0  # Black outline (Pen 0)
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
            
            is_trans0 = (idx0 == 0)
            is_trans1 = (idx1 == 0)
            
            r0, g0, b0 = palette[idx0*3:idx0*3+3]
            r1, g1, b1 = palette[idx1*3:idx1*3+3]
            
            p0 = rgb_to_cpc_pen(r0, g0, b0, is_trans0)
            p1 = rgb_to_cpc_pen(r1, g1, b1, is_trans1)
            
            val = encode_mode0_byte(p0, p1)
            bytes_row.append(f"#{val:02X}")
        asm_lines.append("    defb " + ", ".join(bytes_row) + f"  ; Line {y}")
    return "\n".join(asm_lines)

# Sprites to extract:
sprites_map = [
    ("player_sprite", 0, 0, "Fighter"),
    ("zako_bee_1", 0, 2, "Zako Bee Frame 1"),
    ("zako_bee_2", 1, 2, "Zako Bee Frame 2"),
    ("goei_butterfly_1", 0, 3, "Goei Butterfly Frame 1"),
    ("goei_butterfly_2", 1, 3, "Goei Butterfly Frame 2"),
    ("boss_galaga_damaged", 0, 4, "Boss Galaga Damaged Frame 1"),
    ("boss_galaga_1", 0, 5, "Boss Galaga Green Frame 1"),
    ("boss_galaga_2", 1, 5, "Boss Galaga Green Frame 2"),
]

# Section 4: Authentic Galaga Enemy Explosions (32x32 boxes, center 16x16 extracted)
explosion_boxes = [
    ("explosion_1", 289, 1, 321, 33, "Small Explosion Frame 1 (Initial Burst)"),
    ("explosion_2", 323, 1, 355, 33, "Small Explosion Frame 2 (Expanding Ring)"),
    ("explosion_3", 357, 1, 389, 33, "Small Explosion Frame 3 (Full Burst)"),
    ("explosion_4", 391, 1, 423, 33, "Small Explosion Frame 4 (Fading Particles)"),
]

all_asm = [";; Auto-generated Galaga CPC sprites from assets/galagaSpriteMap.png\n"]

for label, col, row, desc in sprites_map:
    tile = extract_tile(col, row)
    
    # Save preview image in assets
    preview = Image.new('RGB', (16, 16))
    for y in range(16):
        for x in range(16):
            idx = tile.getpixel((x, y))
            if idx == 0:
                preview.putpixel((x, y), (0, 0, 0))
            else:
                r, g, b = palette[idx*3:idx*3+3]
                preview.putpixel((x, y), (r, g, b))
    preview.save(f"assets/{label}.bmp")
    
    asm_str = tile_to_cpc_asm(tile, label)
    all_asm.append(asm_str + "\n")

for label, x1, y1, x2, y2, desc in explosion_boxes:
    crop32 = img.crop((x1, y1, x2, y2)).rotate(270)
    tile = crop32.crop((8, 8, 24, 24))  # 16x16 center
    
    preview = Image.new('RGB', (16, 16))
    for y in range(16):
        for x in range(16):
            idx = tile.getpixel((x, y))
            r, g, b = palette[idx*3:idx*3+3]
            if (r, g, b) in [(64, 64, 64)]:
                preview.putpixel((x, y), (0, 0, 0))
            else:
                preview.putpixel((x, y), (r, g, b))
    preview.save(f"assets/{label}.bmp")
    
    asm_str = tile_to_cpc_asm(tile, label)
    all_asm.append(asm_str + "\n")

with open('src/sprites.asm', 'w') as f:
    f.write("\n".join(all_asm))

# Also update player_sprite.asm so existing code can use it immediately
player_tile = extract_tile(0, 0)
with open('src/player_sprite.asm', 'w') as f:
    f.write(tile_to_cpc_asm(player_tile, "player_sprite"))

print("Successfully extracted and generated authentic src/sprites.asm and src/player_sprite.asm!")

