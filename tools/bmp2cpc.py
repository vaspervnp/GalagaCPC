from PIL import Image
import os

def rgb_to_cpc_index(r, g, b):
    if r == 0 and g == 0 and b == 0:
        return 0  # Black (Pen 0)
    elif r == 255 and g == 255 and b == 255:
        return 15 # Bright White (Pen 15)
    elif r == 255 and g == 0 and b == 0:
        return 2  # Bright Red (Pen 2)
    elif r == 255 and g == 255 and b == 0:
        return 3  # Bright Yellow (Pen 3)
    elif r == 0 and g == 0 and b == 255:
        return 1  # Bright Blue (Pen 1)
    return 0 # Default to black

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

def convert():
    img = Image.open('assets/player.bmp').convert('RGB')
    width, height = img.size
    
    with open('src/player_sprite.asm', 'w') as f:
        f.write(";; Player Sprite (16x16 pixels, 8 bytes x 16 lines in Mode 0)\n")
        f.write("player_sprite:\n")
        
        for y in range(height):
            f.write("    defb ")
            bytes_row = []
            for x in range(0, width, 2):
                r0, g0, b0 = img.getpixel((x, y))
                r1, g1, b1 = img.getpixel((x+1, y))
                
                p0 = rgb_to_cpc_index(r0, g0, b0)
                p1 = rgb_to_cpc_index(r1, g1, b1)
                
                byte_val = encode_mode0_byte(p0, p1)
                bytes_row.append(f"#{byte_val:02X}")
                
            f.write(", ".join(bytes_row) + f"  ; Line {y}\n")
    print("Sprite converted and saved to src/player_sprite.asm")

if __name__ == "__main__":
    convert()
