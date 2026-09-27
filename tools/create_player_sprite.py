from PIL import Image

# Colors:
# '.' = Black (0, 0, 0)
# 'W' = White (255, 255, 255)
# 'R' = Bright Red (255, 0, 0)
# 'Y' = Bright Yellow (255, 255, 0)
# 'B' = Bright Blue (0, 0, 255)

sprite_art = [
    ".......WW.......",
    ".......WW.......",
    "......WWWW......",
    "......WWWW......",
    ".....WWYYWW.....",
    ".....WWYYWW.....",
    "....WWYYYYWW....",
    "...WWWWWWWWWW...",
    "..WW.WWRRWW.WW..",
    ".WW..WRRRRW..WW.",
    ".W...RRRRRR...W.",
    ".W...RRRRRR...W.",
    ".....RR..RR.....",
    "....RR....RR....",
    "....R......R....",
    "................"
]

color_map = {
    '.': (0, 0, 0),
    'W': (255, 255, 255),
    'R': (255, 0, 0),
    'Y': (255, 255, 0),
    'B': (0, 0, 255)
}

img = Image.new('RGB', (16, 16), color=(0, 0, 0))
for y, row in enumerate(sprite_art):
    for x, ch in enumerate(row):
        img.putpixel((x, y), color_map.get(ch, (0, 0, 0)))

img.save('assets/player.bmp')
print("Saved assets/player.bmp successfully!")
