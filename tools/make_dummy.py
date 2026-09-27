from PIL import Image

# Create a 16x16 black image with a simple white and red triangle (Galaga ship placeholder)
img = Image.new('RGB', (16, 16), color='black')
pixels = img.load()

# White center
pixels[7, 8] = (255, 255, 255)
pixels[8, 8] = (255, 255, 255)
pixels[7, 9] = (255, 255, 255)
pixels[8, 9] = (255, 255, 255)
pixels[7, 7] = (255, 255, 255)
pixels[8, 7] = (255, 255, 255)

# Red wings
for x in range(4, 12):
    pixels[x, 10] = (255, 0, 0)
    pixels[x, 11] = (255, 0, 0)

img.save('assets/player.bmp')
print("Dummy player.bmp created!")
