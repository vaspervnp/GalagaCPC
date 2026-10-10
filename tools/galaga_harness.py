"""Headless GalagaCPC runner.

Runs build/galaga.bin on a minimal Z80 core (tools/z80.py) with just enough
CPC hardware (PPI keyboard, VSYNC, 300 Hz interrupts) for the game loop. A
simple bot plays: it starts games from the title screen, follows the lowest
enemy and keeps firing. Every frame the harness checks enemy_data and stops
when an enemy stays alive outside the visible playfield (Y < PF_Y_TOP or
Y >= SPRITE_Y_LIMIT) for --stuck-frames frames, then dumps all enemy slots.

Disk access is skipped (HighScoreLoad returns, HighScoreSave reports no
disk). Timing is approximate, so this tests game logic, not raster timing.

Usage (build first, symbols come from build/galaga.sym):
    python tools/galaga_harness.py --seeds 1 2 3 --frames 15000
    python tools/galaga_harness.py --seeds 4 --invincible --difficulty 3
    python tools/galaga_harness.py --seeds 5 --players 2
Runs at roughly 30-50 emulated frames per second.
"""
import argparse
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80 import Z80

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAME_T = 79872
VSYNC_T = 2048
IRQ_T = 13312
SWAP_BUF = 0xC4E0      # PLAYER_SWAP_BUF: inactive player's state (2-player game)


def load_syms():
    syms = {}
    for line in open(REPO + '/build/galaga.sym'):
        parts = line.split()
        if len(parts) >= 2 and parts[1].startswith('#'):
            syms[parts[0].upper()] = int(parts[1][1:], 16)
    return syms


class Machine:
    def __init__(self, seed=1, invincible=False, difficulty=None, max_frames=20000, verbose=True,
                 stuck_frames=150, players=1):
        self.S = load_syms()
        self.mem = bytearray(65536)
        binary = open(REPO + '/build/galaga.bin', 'rb').read()
        self.mem[0x0600:0x0600 + len(binary)] = binary
        self.cpu = Z80(self.mem, self.io_in, self.io_out)
        self.cpu.pc = 0x0600
        self.cpu.r = seed & 0x7F
        self.rng = random.Random(seed)
        self.port_a = 0
        self.port_c = 0
        self.psg_reg = 0
        self.keys = [0xFF] * 10
        self.frame = 0
        self.invincible = invincible
        self.difficulty = difficulty
        self.max_frames = max_frames
        self.verbose = verbose
        self.stuck_frames = stuck_frames
        self.players = players
        self.last_player = None
        self.last_game_over = 0
        self.games = 0
        self.invisible = {}
        self.last_stage = None
        self.events = []
        self.fire_toggle = 0
        self.target_x = None
        self.found = None
        self.next_irq = IRQ_T
        self.hooks = {}
        S = self.S
        self.hooks[S['WAITVSYNC']] = self.on_vsync
        for name in ('HIGHSCORELOAD',):
            if name in S:
                self.hooks[S[name]] = self.ret_hook
        if 'HIGHSCORESAVE' in S:
            self.hooks[S['HIGHSCORESAVE']] = self.save_hook
        if invincible:
            self.hooks[S['HITPLAYER']] = self.ret_hook

    # --- hardware
    def io_in(self, port):
        hi = port >> 8
        if hi == 0xF4:
            if (self.port_c & 0xC0) == 0x40 and self.psg_reg == 14:
                line = self.port_c & 0x0F
                return self.keys[line] if line < 10 else 0xFF
            return 0xFF
        if hi == 0xF5:
            vs = 1 if (self.cpu.cycles % FRAME_T) < VSYNC_T else 0
            return 0x1E | vs
        if hi == 0xFB:
            return 0x80
        return 0xFF

    def io_out(self, port, val):
        hi = port >> 8
        if hi == 0xF4:
            self.port_a = val
        elif hi == 0xF6:
            self.port_c = val
            if (val & 0xC0) == 0xC0:
                self.psg_reg = self.port_a

    def ret_hook(self):
        self.cpu.pc = self.cpu.pop()

    def save_hook(self):
        self.cpu.a = 2
        self.cpu.f |= 1
        self.cpu.pc = self.cpu.pop()

    def b(self, name, off=0):
        return self.mem[self.S[name] + off]

    # --- bot + checks, once per frame
    def on_vsync(self):
        self.frame += 1
        S = self.S
        self.keys = [0xFF] * 10
        title = self.b('IS_TITLE_SCREEN')
        if title:
            if self.difficulty is not None:
                self.mem[S['DIFFICULTY_LEVEL']] = self.difficulty
            if self.frame % 40 == 20:
                if self.players == 2:
                    self.keys[8] &= ~0x02  # '2'
                else:
                    self.keys[5] &= ~0x80  # space
        else:
            self.play()
            self.check()
        # Skip the busy-wait: jump to the next VSYNC edge
        c = self.cpu.cycles
        nxt = (c // FRAME_T + 1) * FRAME_T
        self.cpu.cycles = nxt
        self.next_irq = nxt + IRQ_T
        self.cpu.pc = self.cpu.pop()       # return from WaitVSync

    def play(self):
        S = self.S
        px = self.b('PLAYER_X')
        # pick a target: lowest alive enemy
        best = None
        base = S['ENEMY_DATA']
        for i in range(self.S['ENEMY_COUNT']):
            e = base + i * self.S['ENEMY_SIZE']
            if self.mem[e] and 8 <= self.mem[e + 3] < 252:
                y = self.mem[e + 3]
                if best is None or y > best[1]:
                    best = (self.mem[e + 2], y)
        if best is not None and self.rng.random() < 0.9:
            tx = best[0]
            if tx > px + 1:
                self.keys[0] &= ~0x02  # right
            elif tx < px - 1:
                self.keys[1] &= ~0x01  # left
        elif self.rng.random() < 0.5:
            self.keys[1 if self.rng.random() < 0.5 else 0] &= ~(0x01 if self.rng.random() < 0.5 else 0x02)
        self.fire_toggle ^= 1
        if self.fire_toggle and self.rng.random() < 0.8:
            self.keys[5] &= ~0x80

    def enemy(self, i):
        e = self.S['ENEMY_DATA'] + i * self.S['ENEMY_SIZE']
        return list(self.mem[e:e + self.S['ENEMY_SIZE']])

    def check(self):
        S = self.S
        player = self.b('ACTIVE_PLAYER')
        if player != self.last_player:
            self.last_player = player
            self.last_stage = None
            self.invisible.clear()
            if self.verbose and self.b('TWO_PLAYER'):
                other = SWAP_BUF - S['PLAYER_STATE']
                print(f'  frame {self.frame}: player {player + 1} up, lives {self.b("PLAYER_LIVES")}'
                      f' / other {self.mem[S["PLAYER_LIVES"] + other]}', flush=True)
        game_over = self.b('GAME_OVER')
        if game_over != self.last_game_over:
            self.last_game_over = game_over
            if game_over:
                self.games += 1
                if self.verbose:
                    print(f'  frame {self.frame}: game over', flush=True)
        stage = self.b('CURRENT_STAGE')
        if stage != self.last_stage:
            self.last_stage = stage
            self.invisible.clear()
            if self.verbose:
                print(f'  frame {self.frame}: player {player + 1} stage {stage}', flush=True)
        if self.b('GAME_OVER'):
            return
        for i in range(self.S['ENEMY_COUNT']):
            en = self.enemy(i)
            if not en[0]:
                self.invisible.pop(i, None)
                continue
            y = en[3]
            if y < 8 or y >= 252:
                self.invisible[i] = self.invisible.get(i, 0) + 1
                if self.invisible[i] == self.stuck_frames and self.found is None:
                    self.found = (self.frame, i, en)
            else:
                self.invisible.pop(i, None)

    def run(self):
        cpu = self.cpu
        hooks = self.hooks
        t0 = time.time()
        while self.frame < self.max_frames and self.found is None:
            h = hooks.get(cpu.pc)
            if h:
                h()
                continue
            cpu.step()
            if cpu.cycles >= self.next_irq:
                self.next_irq += IRQ_T
                cpu.interrupt()
        return self.found, time.time() - t0


def dump(m):
    S = m.S
    names = ['STAGE_PHASE', 'CURRENT_STAGE', 'IS_CHALLENGING_STAGE', 'TRACTOR_BEAM_ACTIVE',
             'CAPTURE_DELAY', 'RESPAWN_WAIT', 'CAPTURED_FIGHTER_ACTIVE', 'ENTRY_SPAWN_IDX',
             'STAGE_ENEMY_TOTAL', 'PLAYER_LIVES', 'IS_DUAL_FIGHTER']
    print('   ', ', '.join(f'{n.lower()}={m.b(n)}' for n in names if n in S))
    for i in range(m.S['ENEMY_COUNT']):
        en = m.enemy(i)
        if en[0]:
            print(f'    slot {i:2}: alive={en[0]} type={en[1]} x={en[2]} y={en[3]} old=({en[4]},{en[5]}) '
                  f'base=({en[7]},{en[10]}) state={en[8]} hp={en[9]} b11={en[11]:#04x} '
                  f'spd={en[12]} lane={en[13]:#04x}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--seeds', type=int, nargs='+', default=[1])
    ap.add_argument('--frames', type=int, default=15000)
    ap.add_argument('--invincible', action='store_true', help='the player cannot be hit')
    ap.add_argument('--difficulty', type=int, choices=range(4),
                    help='0..3; default varies with the seed')
    ap.add_argument('--players', type=int, choices=(1, 2), default=1,
                    help="start games with '1'/FIRE or '2'")
    ap.add_argument('--stuck-frames', type=int, default=150,
                    help='report an enemy off screen for this many frames (the in-game '
                         'watchdog removes them after 250)')
    args = ap.parse_args()
    stuck = 0
    for seed in args.seeds:
        diff = args.difficulty if args.difficulty is not None else seed % 4
        m = Machine(seed=seed, invincible=args.invincible, difficulty=diff,
                    max_frames=args.frames, stuck_frames=args.stuck_frames, players=args.players)
        print(f'seed {seed} invincible={args.invincible} difficulty={diff}', flush=True)
        found, dt = m.run()
        print(f'  ran {m.frame} frames in {dt:.0f}s')
        if found:
            stuck += 1
            print(f'  STUCK enemy at frame {found[0]} slot {found[1]}: {found[2]}')
            dump(m)
    sys.exit(1 if stuck else 0)
