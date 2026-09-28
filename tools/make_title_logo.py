from PIL import Image
import numpy as np

# Load arcade tuned 72x32 logo
im = Image.open('scratch/logo_arcade_72x32.png')

cpc_pal = {
    (0,0,0): 0,        # Pen 0: Black
    (0,0,255): 1,      # Pen 1: Blue
    (255,0,0): 2,      # Pen 2: Bright Red
    (255,255,0): 3,    # Pen 3: Bright Yellow
    (0,255,255): 4,    # Pen 4: Bright Cyan
    (255,0,255): 5,    # Pen 5: Magenta
    (0,255,0): 6,      # Pen 6: Green
    (255,255,255): 15  # Pen 15: White
}

def encode_mode0_byte(p0, p1):
    b7 = (p0 & 1) << 7
    b6 = (p1 & 1) << 6
    b5 = ((p0 >> 2) & 1) << 5
    b4 = ((p1 >> 2) & 1) << 4
    b3 = ((p0 >> 1) & 1) << 3
    b2 = ((p1 >> 1) & 1) << 2
    b1 = ((p0 >> 3) & 1) << 1
    b0 = ((p1 >> 3) & 1) << 0
    return b7 | b6 | b5 | b4 | b3 | b2 | b1 | b0

width = 72
height = 32

with open('src/title_logo.asm', 'w') as f:
    f.write(";; ============================================================================\n")
    f.write(";; Galaga CPC - Official Arcade Title Logo (36 bytes wide x 32 scanlines)\n")
    f.write(";; Mode 0 (72 Mode 0 pixels wide, Pen 0, 1, 2, 3, 4, 15)\n")
    f.write(";; ============================================================================\n\n")
    f.write("TITLE_LOGO_W    equ 36\n")
    f.write("TITLE_LOGO_H    equ 32\n\n")
    f.write("title_logo_data:\n")
    
    for y in range(height):
        bytes_row = []
        for x in range(0, width, 2):
            c0 = im.getpixel((x*2, y))
            c1 = im.getpixel(((x+1)*2, y))
            p0 = cpc_pal.get(c0[:3], 0)
            p1 = cpc_pal.get(c1[:3], 0)
            byte_val = encode_mode0_byte(p0, p1)
            bytes_row.append(f"#{byte_val:02X}")
        f.write("    defb " + ", ".join(bytes_row) + f"  ; Line {y}\n")

print("Created src/title_logo.asm successfully with 36x32 arcade logo!")
