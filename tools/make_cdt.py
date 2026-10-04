"""Build build/galaga.cdt: a CPC 464 cassette image of the game.

The tape holds an ASCII BASIC loader, the REVIVE8B.SCR loading screen and
GALAGA.BIN, written as standard CPC firmware records (2 KB blocks, each a
header record and a data record with CRC-protected 256-byte segments).
A CDT file is a TZX file; every record is a TZX "turbo speed data" block
with CPC timings.

Usage: python tools/make_cdt.py [baud]     (default 2000, SPEED WRITE 1)
"""
import pathlib
import struct
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
TZX_CLOCK = 3500000
BLOCK = 2048
SYNC_HEADER = 0x2C
SYNC_DATA = 0x16
TYPE_BASIC_ASCII = 0x16
TYPE_BINARY = 0x02

# Tape loader: keep the pens black while the screen loads, show it while the
# game loads ("!" suppresses the cassette messages), then run the game.
LOADER = [
    '10 MODE 0:BORDER 0:FOR I=0 TO 15:INK I,0:NEXT:CALL &BD19',
    '20 LOAD "!REVIVE8B.SCR"',
    '30 INK 0,0:INK 1,13:INK 2,26:INK 3,15:INK 4,25:INK 5,10:INK 6,3:INK 7,1:'
    'INK 8,11:INK 9,23:INK 10,6:INK 11,24:INK 12,20:INK 13,16:INK 14,12:INK 15,4',
    '40 RUN "!GALAGA.BIN"',
]


def crc16(data):
    """CPC firmware tape CRC: CCITT polynomial, initial #FFFF, stored inverted."""
    crc = 0xFFFF
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if crc & 0x8000 else crc << 1
            crc &= 0xFFFF
    return crc ^ 0xFFFF


def record(sync, payload):
    """Sync byte, 256-byte segments each followed by its CRC (high byte
    first), then a 32-bit trailer of ones."""
    out = bytearray([sync])
    for i in range(0, len(payload), 256):
        seg = payload[i:i + 256].ljust(256, b'\0')
        out += seg + struct.pack('>H', crc16(seg))
    return out + b'\xFF' * 4


def turbo_block(data, baud, pause_ms):
    zero = round(TZX_CLOCK / (3 * baud))   # half period of a 0 bit
    one = 2 * zero
    return (b'\x11' + struct.pack('<6H', one, zero, zero, zero, one, 4096)
            + bytes([8]) + struct.pack('<H', pause_ms)
            + struct.pack('<I', len(data))[:3] + data)


def tape_file(name, ftype, data, load, entry):
    """The firmware records of one file as (record bytes, pause ms) pairs."""
    blocks = []
    count = max(1, -(-len(data) // BLOCK))
    for n in range(count):
        chunk = data[n * BLOCK:(n + 1) * BLOCK]
        hdr = bytearray(64)
        hdr[0:16] = name.upper().encode('ascii').ljust(16, b'\0')
        hdr[16] = n + 1
        hdr[17] = 0xFF if n == count - 1 else 0
        hdr[18] = ftype
        struct.pack_into('<H', hdr, 19, len(chunk))
        struct.pack_into('<H', hdr, 21, (load + n * BLOCK) & 0xFFFF)
        hdr[23] = 0xFF if n == 0 else 0
        struct.pack_into('<H', hdr, 24, len(data) if ftype != TYPE_BASIC_ASCII else 0)
        struct.pack_into('<H', hdr, 26, entry)
        blocks.append((record(SYNC_HEADER, bytes(hdr)), 20))
        blocks.append((record(SYNC_DATA, chunk), 2000 if n == count - 1 else 500))
    return blocks


def tape_records():
    """Every record on the tape: BASIC loader, loading screen, game."""
    loader = ('\r\n'.join(LOADER) + '\r\n').encode('ascii')
    screen = (REPO / 'assets' / 'revive8b.scr').read_bytes()
    game = (REPO / 'build' / 'galaga.bin').read_bytes()
    assert len(screen) == 16384, 'REVIVE8B.SCR must be a raw 16 KB screen'
    assert 0x0600 + len(game) <= 0x8000, 'GALAGA.BIN overlaps the screen'
    return (tape_file('GALAGA', TYPE_BASIC_ASCII, loader, 0x0170, 0)
            + tape_file('REVIVE8B.SCR', TYPE_BINARY, screen, 0xC000, 0)
            + tape_file('GALAGA.BIN', TYPE_BINARY, game, 0x0600, 0x0600))


def main():
    baud = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
    tzx = bytearray(b'ZXTape!\x1A\x01\x14')
    text = b'Galaga CPC - revive8bit 2026'
    tzx += b'\x30' + bytes([len(text)]) + text
    for rec, pause in tape_records():
        tzx += turbo_block(rec, baud, pause)
    out = REPO / 'build' / 'galaga.cdt'
    out.write_bytes(tzx)
    print(f'wrote {out.relative_to(REPO)} ({len(tzx)} bytes, {baud} baud)')


if __name__ == '__main__':
    main()
