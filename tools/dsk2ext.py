"""Convert a uniform, single-sided CPCEMU DSK to extended DSK format."""

import sys
from pathlib import Path


def convert(path: Path) -> None:
    disk = path.read_bytes()
    if disk[:8] == b"EXTENDED":
        return
    if disk[:8] != b"MV - CPC":
        raise ValueError(f"not a CPC DSK image: {disk[:16]!r}")

    tracks = disk[0x30]
    sides = disk[0x31]
    track_size = int.from_bytes(disk[0x32:0x34], "little")
    if sides != 1:
        raise ValueError("only single-sided DSK images are supported")
    if track_size < 256 or 256 + tracks * track_size > len(disk):
        raise ValueError("truncated or invalid DSK image")
    if track_size % 256:
        raise ValueError("track size must be a multiple of 256 bytes")

    header = bytearray(256)
    header[:34] = b"EXTENDED CPC DSK File\r\nDisk-Info\r\n"
    header[0x22:0x30] = b"GalagaDSK     "
    header[0x30] = tracks
    header[0x31] = sides
    for track in range(tracks):
        header[0x34 + track] = track_size >> 8

    output = bytearray(header)
    for track in range(tracks):
        start = 256 + track * track_size
        block = bytearray(disk[start:start + track_size])
        if block[:10] != b"Track-Info":
            raise ValueError(f"invalid track header at track {track}")
        for sector in range(block[0x15]):
            descriptor = 0x18 + sector * 8
            block[descriptor + 6] = 0
            block[descriptor + 7] = (128 << block[descriptor + 3]) >> 8
        output.extend(block)

    path.write_bytes(output)


if __name__ == "__main__":
    convert(Path(sys.argv[1]))
