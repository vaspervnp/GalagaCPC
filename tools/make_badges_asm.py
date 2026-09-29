"""Generate the six Mode 0 stage badge sprites from assets/badgesMap.png."""

from pathlib import Path

from PIL import Image


BADGES = (
    ("badge_stage_1", (0, 3, 8, 17)),
    ("badge_stage_5", (11, 3, 19, 17)),
    ("badge_stage_10", (22, 3, 36, 17)),
    ("badge_stage_20", (39, 1, 55, 17)),
    ("badge_stage_30", (57, 1, 73, 17)),
    ("badge_stage_50", (75, 1, 91, 17)),
)

PIXEL_PENS = {
    (0, 0, 0): 0,
    (64, 64, 64): 0,
    (0, 0, 255): 1,
    (255, 0, 0): 2,
    (255, 255, 0): 3,
    (184, 0, 255): 5,
    (222, 222, 255): 15,
}


def encode_mode0(left: int, right: int) -> int:
    return (
        ((left & 1) << 7)
        | ((right & 1) << 6)
        | (((left >> 2) & 1) << 5)
        | (((right >> 2) & 1) << 4)
        | (((left >> 1) & 1) << 3)
        | (((right >> 1) & 1) << 2)
        | (((left >> 3) & 1) << 1)
        | ((right >> 3) & 1)
    )


def main() -> None:
    image = Image.open("assets/badgesMap.png").convert("RGB")
    if image.size != (92, 18):
        raise ValueError(f"Expected a 92x18 badge map, got {image.width}x{image.height}")
    lines = [";; Generated from assets/badgesMap.png; do not edit by hand.", ""]

    for label, box in BADGES:
        left, top, right, bottom = box
        crop = image.crop(box)
        if crop.width % 2:
            raise ValueError(f"{label} crop width must be even")

        lines.extend(
            [
                f"{label}_width equ {crop.width // 2}",
                f"{label}_height equ {crop.height}",
                f"{label}:",
            ]
        )
        for y in range(crop.height):
            row = []
            for x in range(0, crop.width, 2):
                pixels = []
                for pixel_x in (x, x + 1):
                    rgb = crop.getpixel((pixel_x, y))
                    try:
                        pixels.append(PIXEL_PENS[rgb])
                    except KeyError as error:
                        raise ValueError(
                            f"Unexpected RGB value {rgb} in {label} at "
                            f"({left + pixel_x}, {top + y})"
                        ) from error
                row.append(f"#{encode_mode0(*pixels):02X}")
            lines.append("    defb " + ", ".join(row))
        lines.append("")

    Path("src/badges.asm").write_text("\n".join(lines), encoding="ascii")


if __name__ == "__main__":
    main()
