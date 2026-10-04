"""Build build/galaga.wav: the cassette as audio, for a real tape.

Play it into the CPC 464 through a cassette lead, or record it onto a
cassette. It holds the same firmware records as build/galaga.cdt: for each
record a leader of 2048 one bits, a zero sync bit, the record bytes (most
significant bit first) and a pause of silence. Each bit is two half
periods of a square wave; a one is twice as long as a zero.

Usage: python tools/make_tape_wav.py [baud] [sample rate]
       (default 2000 baud = SPEED WRITE 1, 44100 Hz)
"""
import pathlib
import sys
import wave

from make_cdt import REPO, tape_records

HIGH, LOW, SILENCE = 0xE0, 0x20, 0x80     # 8-bit unsigned samples


class Square:
    """Square-wave writer that keeps time in microseconds, so rounding to
    whole samples never accumulates."""

    def __init__(self, rate):
        self.rate = rate
        self.out = bytearray()
        self.t = 0.0
        self.level = LOW

    def _fill(self, us, value):
        self.t += us
        end = round(self.t * self.rate / 1e6)
        self.out += bytes([value]) * (end - len(self.out))

    def pulse(self, us):
        self.level = HIGH if self.level == LOW else LOW
        self._fill(us, self.level)

    def silence(self, ms):
        self._fill(ms * 1000, SILENCE)
        self.level = LOW


def main():
    baud = int(sys.argv[1]) if len(sys.argv) > 1 else 2000
    rate = int(sys.argv[2]) if len(sys.argv) > 2 else 44100
    zero = 1e6 / (3 * baud)                # half period of a 0 bit (us)
    one = 2 * zero
    sq = Square(rate)
    sq.silence(1000)
    for rec, pause in tape_records():
        for _ in range(4096):              # leader: 2048 one bits
            sq.pulse(one)
        sq.pulse(zero)                     # sync: one zero bit
        sq.pulse(zero)
        for byte in rec:
            for bit in range(7, -1, -1):
                half = one if byte >> bit & 1 else zero
                sq.pulse(half)
                sq.pulse(half)
        sq.silence(pause)
    sq.silence(1000)
    out = REPO / 'build' / 'galaga.wav'
    with wave.open(str(out), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(rate)
        w.writeframes(bytes(sq.out))
    secs = len(sq.out) / rate
    print(f'wrote {out.relative_to(REPO)} ({len(sq.out) / 1e6:.1f} MB, {baud} baud, '
          f'{rate} Hz, {int(secs // 60)}:{int(secs % 60):02d})')


if __name__ == '__main__':
    main()
