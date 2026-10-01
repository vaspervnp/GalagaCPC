# Minimal Z80 core (documented behaviour only), used by tools/galaga_harness.py.
SF, ZF, YF, HF, XF, PF, NF, CF = 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01

PARITY = [0] * 256
for _i in range(256):
    PARITY[_i] = PF if bin(_i).count('1') % 2 == 0 else 0
SZP = [(_i & SF) | (ZF if _i == 0 else 0) | PARITY[_i] for _i in range(256)]
SZ = [(_i & SF) | (ZF if _i == 0 else 0) for _i in range(256)]


class Z80:
    def __init__(self, mem, io_in, io_out):
        self.m = mem
        self.io_in = io_in
        self.io_out = io_out
        self.a = self.f = self.b = self.c = self.d = self.e = self.h = self.l = 0
        self.a_ = self.f_ = self.b_ = self.c_ = self.d_ = self.e_ = self.h_ = self.l_ = 0
        self.ix = self.iy = 0
        self.sp = 0xFFFF
        self.pc = 0
        self.i = 0
        self.r = 0
        self.iff1 = self.iff2 = 0
        self.im = 0
        self.halted = False
        self.cycles = 0
        self.ei_delay = False

    # --- memory helpers
    def rb(self, a):
        return self.m[a & 0xFFFF]

    def wb(self, a, v):
        self.m[a & 0xFFFF] = v & 0xFF

    def rw(self, a):
        return self.m[a & 0xFFFF] | (self.m[(a + 1) & 0xFFFF] << 8)

    def ww(self, a, v):
        self.m[a & 0xFFFF] = v & 0xFF
        self.m[(a + 1) & 0xFFFF] = (v >> 8) & 0xFF

    def fetch(self):
        v = self.m[self.pc]
        self.pc = (self.pc + 1) & 0xFFFF
        return v

    def fetchw(self):
        v = self.m[self.pc] | (self.m[(self.pc + 1) & 0xFFFF] << 8)
        self.pc = (self.pc + 2) & 0xFFFF
        return v

    def fetchd(self):
        v = self.fetch()
        return v - 256 if v > 127 else v

    def push(self, v):
        self.sp = (self.sp - 2) & 0xFFFF
        self.ww(self.sp, v)

    def pop(self):
        v = self.rw(self.sp)
        self.sp = (self.sp + 2) & 0xFFFF
        return v

    # --- register pairs
    @property
    def bc(self): return (self.b << 8) | self.c
    @bc.setter
    def bc(self, v): self.b = (v >> 8) & 0xFF; self.c = v & 0xFF
    @property
    def de(self): return (self.d << 8) | self.e
    @de.setter
    def de(self, v): self.d = (v >> 8) & 0xFF; self.e = v & 0xFF
    @property
    def hl(self): return (self.h << 8) | self.l
    @hl.setter
    def hl(self, v): self.h = (v >> 8) & 0xFF; self.l = v & 0xFF
    @property
    def af(self): return (self.a << 8) | self.f
    @af.setter
    def af(self, v): self.a = (v >> 8) & 0xFF; self.f = v & 0xFF

    def get_rp(self, p, idx):
        if p == 0: return self.bc
        if p == 1: return self.de
        if p == 2: return self.hl if idx is None else (self.ix if idx == 'ix' else self.iy)
        return self.sp

    def set_rp(self, p, v, idx):
        v &= 0xFFFF
        if p == 0: self.bc = v
        elif p == 1: self.de = v
        elif p == 2:
            if idx is None: self.hl = v
            elif idx == 'ix': self.ix = v
            else: self.iy = v
        else: self.sp = v

    def get_rp2(self, p, idx):
        return self.af if p == 3 else self.get_rp(p, idx)

    def set_rp2(self, p, v, idx):
        if p == 3: self.af = v
        else: self.set_rp(p, v, idx)

    # 8-bit register access; idx in (None,'ix','iy'); addr for (HL)/(IX+d)
    def get_r(self, r, idx, addr):
        if r == 0: return self.b
        if r == 1: return self.c
        if r == 2: return self.d
        if r == 3: return self.e
        if r == 4:
            if idx is None: return self.h
            return ((self.ix if idx == 'ix' else self.iy) >> 8) & 0xFF
        if r == 5:
            if idx is None: return self.l
            return (self.ix if idx == 'ix' else self.iy) & 0xFF
        if r == 6: return self.rb(addr)
        return self.a

    def set_r(self, r, v, idx, addr):
        v &= 0xFF
        if r == 0: self.b = v
        elif r == 1: self.c = v
        elif r == 2: self.d = v
        elif r == 3: self.e = v
        elif r == 4:
            if idx is None: self.h = v
            elif idx == 'ix': self.ix = (self.ix & 0xFF) | (v << 8)
            else: self.iy = (self.iy & 0xFF) | (v << 8)
        elif r == 5:
            if idx is None: self.l = v
            elif idx == 'ix': self.ix = (self.ix & 0xFF00) | v
            else: self.iy = (self.iy & 0xFF00) | v
        elif r == 6: self.wb(addr, v)
        else: self.a = v

    def cond(self, y):
        f = self.f
        return [not f & ZF, f & ZF, not f & CF, f & CF,
                not f & PF, f & PF, not f & SF, f & SF][y]

    # --- ALU
    def alu(self, op, v):
        a = self.a
        if op in (0, 1):  # add / adc
            c = (self.f & CF) if op == 1 else 0
            r = a + v + c
            f = SZ[r & 0xFF] | (CF if r > 0xFF else 0) | ((a ^ v ^ r) & HF)
            if (~(a ^ v) & (a ^ r)) & 0x80: f |= PF
            self.a = r & 0xFF; self.f = f
        elif op in (2, 3, 7):  # sub / sbc / cp
            c = (self.f & CF) if op == 3 else 0
            r = a - v - c
            f = SZ[r & 0xFF] | NF | (CF if r < 0 else 0) | ((a ^ v ^ r) & HF)
            if ((a ^ v) & (a ^ r)) & 0x80: f |= PF
            self.f = f
            if op != 7: self.a = r & 0xFF
        elif op == 4:
            self.a = a & v; self.f = SZP[self.a] | HF
        elif op == 5:
            self.a = a ^ v; self.f = SZP[self.a]
        elif op == 6:
            self.a = a | v; self.f = SZP[self.a]

    def inc8(self, v):
        r = (v + 1) & 0xFF
        f = (self.f & CF) | SZ[r] | (HF if (v & 0xF) == 0xF else 0) | (PF if v == 0x7F else 0)
        self.f = f
        return r

    def dec8(self, v):
        r = (v - 1) & 0xFF
        f = (self.f & CF) | SZ[r] | NF | (HF if (v & 0xF) == 0 else 0) | (PF if v == 0x80 else 0)
        self.f = f
        return r

    def add16(self, a, b):
        r = a + b
        self.f = (self.f & (SF | ZF | PF)) | (CF if r > 0xFFFF else 0) | (((a ^ b ^ r) >> 8) & HF)
        return r & 0xFFFF

    def adc16(self, a, b):
        c = self.f & CF
        r = a + b + c
        f = (CF if r > 0xFFFF else 0) | (((a ^ b ^ r) >> 8) & HF)
        r &= 0xFFFF
        f |= (SF if r & 0x8000 else 0) | (ZF if r == 0 else 0)
        if (~(a ^ b) & (a ^ r)) & 0x8000: f |= PF
        self.f = f
        return r

    def sbc16(self, a, b):
        c = self.f & CF
        r = a - b - c
        f = NF | (CF if r < 0 else 0) | (((a ^ b ^ r) >> 8) & HF)
        r &= 0xFFFF
        f |= (SF if r & 0x8000 else 0) | (ZF if r == 0 else 0)
        if ((a ^ b) & (a ^ r)) & 0x8000: f |= PF
        self.f = f
        return r

    def rot(self, y, v):
        c = self.f & CF
        if y == 0: co = v >> 7; r = ((v << 1) | co) & 0xFF
        elif y == 1: co = v & 1; r = (v >> 1) | (co << 7)
        elif y == 2: co = v >> 7; r = ((v << 1) | c) & 0xFF
        elif y == 3: co = v & 1; r = (v >> 1) | (c << 7)
        elif y == 4: co = v >> 7; r = (v << 1) & 0xFF
        elif y == 5: co = v & 1; r = (v >> 1) | (v & 0x80)
        elif y == 6: co = v >> 7; r = ((v << 1) | 1) & 0xFF
        else: co = v & 1; r = v >> 1
        self.f = SZP[r] | (CF if co else 0)
        return r

    # --- interrupts
    def interrupt(self):
        if not self.iff1 or self.ei_delay:
            return False
        self.halted = False
        self.iff1 = self.iff2 = 0
        self.push(self.pc)
        if self.im == 2:
            self.pc = self.rw((self.i << 8) | 0xFF)
        else:
            self.pc = 0x38
        self.cycles += 13
        return True

    # --- execution
    def step(self):
        self.ei_delay = False
        if self.halted:
            self.cycles += 4
            return
        self.r = (self.r & 0x80) | ((self.r + 1) & 0x7F)
        op = self.fetch()
        idx = None
        while op in (0xDD, 0xFD):
            idx = 'ix' if op == 0xDD else 'iy'
            self.r = (self.r & 0x80) | ((self.r + 1) & 0x7F)
            op = self.fetch()
        if op == 0xCB:
            self.exec_cb(idx)
        elif op == 0xED:
            self.exec_ed()
        else:
            self.exec_main(op, idx)

    def idx_addr(self, idx):
        d = self.fetchd()
        base = self.ix if idx == 'ix' else self.iy
        return (base + d) & 0xFFFF

    def exec_main(self, op, idx):
        x = op >> 6; y = (op >> 3) & 7; z = op & 7; p = y >> 1; q = y & 1
        self.cycles += 4 if idx is None else 8
        if x == 1:
            if op == 0x76:
                self.halted = True
                return
            if y == 6 or z == 6:
                if idx is None:
                    addr = self.hl
                else:
                    addr = self.idx_addr(idx)
                # with (HL)/(IX+d) the other operand uses plain H/L
                if z == 6:
                    self.set_r(y, self.rb(addr), None, 0)
                else:
                    self.wb(addr, self.get_r(z, None, 0))
                self.cycles += 3
                return
            self.set_r(y, self.get_r(z, idx, 0), idx, 0)
            return
        if x == 2:
            if z == 6:
                addr = self.hl if idx is None else self.idx_addr(idx)
                v = self.rb(addr); self.cycles += 3
            else:
                v = self.get_r(z, idx, 0)
            self.alu(y, v)
            return
        if x == 0:
            if z == 0:
                if y == 0: return
                if y == 1:
                    self.af, (self.a_, self.f_) = (self.a_ << 8) | self.f_, (self.a, self.f)
                    return
                if y == 2:
                    d = self.fetchd()
                    self.b = (self.b - 1) & 0xFF
                    if self.b: self.pc = (self.pc + d) & 0xFFFF; self.cycles += 5
                    self.cycles += 4
                    return
                d = self.fetchd()
                if y == 3 or self.cond(y - 4):
                    self.pc = (self.pc + d) & 0xFFFF; self.cycles += 5
                self.cycles += 3
                return
            if z == 1:
                if q == 0:
                    self.set_rp(p, self.fetchw(), idx); self.cycles += 6
                else:
                    hl = self.get_rp(2, idx)
                    self.set_rp(2, self.add16(hl, self.get_rp(p, idx)), idx); self.cycles += 7
                return
            if z == 2:
                self.cycles += 6
                if q == 0:
                    if p == 0: self.wb(self.bc, self.a)
                    elif p == 1: self.wb(self.de, self.a)
                    elif p == 2: self.ww(self.fetchw(), self.get_rp(2, idx)); self.cycles += 6
                    else: self.wb(self.fetchw(), self.a); self.cycles += 3
                else:
                    if p == 0: self.a = self.rb(self.bc)
                    elif p == 1: self.a = self.rb(self.de)
                    elif p == 2: self.set_rp(2, self.rw(self.fetchw()), idx); self.cycles += 6
                    else: self.a = self.rb(self.fetchw()); self.cycles += 3
                return
            if z == 3:
                v = self.get_rp(p, idx)
                self.set_rp(p, v + (1 if q == 0 else -1), idx); self.cycles += 2
                return
            if z in (4, 5):
                if y == 6:
                    addr = self.hl if idx is None else self.idx_addr(idx)
                    v = self.rb(addr)
                    self.wb(addr, self.inc8(v) if z == 4 else self.dec8(v)); self.cycles += 7
                else:
                    v = self.get_r(y, idx, 0)
                    self.set_r(y, self.inc8(v) if z == 4 else self.dec8(v), idx, 0)
                return
            if z == 6:
                if y == 6:
                    addr = self.hl if idx is None else self.idx_addr(idx)
                    self.wb(addr, self.fetch()); self.cycles += 6
                else:
                    self.set_r(y, self.fetch(), idx, 0); self.cycles += 3
                return
            # z == 7
            a = self.a; f = self.f
            if y == 0:
                c = a >> 7; self.a = ((a << 1) | c) & 0xFF
                self.f = (f & (SF | ZF | PF)) | c
            elif y == 1:
                c = a & 1; self.a = (a >> 1) | (c << 7)
                self.f = (f & (SF | ZF | PF)) | c
            elif y == 2:
                c = a >> 7; self.a = ((a << 1) | (f & CF)) & 0xFF
                self.f = (f & (SF | ZF | PF)) | c
            elif y == 3:
                c = a & 1; self.a = (a >> 1) | ((f & CF) << 7)
                self.f = (f & (SF | ZF | PF)) | c
            elif y == 4:  # DAA
                corr = 0; c = f & CF
                if (f & HF) or (a & 0xF) > 9: corr |= 0x06
                if c or a > 0x99: corr |= 0x60; c = CF
                if f & NF:
                    h = HF if (f & HF) and (a & 0xF) < 6 else 0
                    r = (a - corr) & 0xFF
                else:
                    h = HF if (a & 0xF) > 9 else 0
                    r = (a + corr) & 0xFF
                self.a = r
                self.f = SZP[r] | (f & NF) | c | h
            elif y == 5:
                self.a = a ^ 0xFF; self.f = f | HF | NF
            elif y == 6:
                self.f = (f & (SF | ZF | PF)) | CF
            else:
                self.f = (f & (SF | ZF | PF)) | (HF if f & CF else 0) | (0 if f & CF else CF)
            return
        # x == 3
        if z == 0:
            if self.cond(y): self.pc = self.pop(); self.cycles += 6
            self.cycles += 1
            return
        if z == 1:
            if q == 0:
                self.set_rp2(p, self.pop(), idx); self.cycles += 6
                return
            if p == 0: self.pc = self.pop(); self.cycles += 6
            elif p == 1:
                self.bc, self.b_, self.c_ = (self.b_ << 8) | self.c_, self.b, self.c
                self.de, self.d_, self.e_ = (self.d_ << 8) | self.e_, self.d, self.e
                self.hl, self.h_, self.l_ = (self.h_ << 8) | self.l_, self.h, self.l
            elif p == 2: self.pc = self.get_rp(2, idx)
            else: self.sp = self.get_rp(2, idx); self.cycles += 2
            return
        if z == 2:
            a = self.fetchw(); self.cycles += 6
            if self.cond(y): self.pc = a
            return
        if z == 3:
            if y == 0: self.pc = self.fetchw(); self.cycles += 6
            elif y == 2: self.io_out((self.a << 8) | self.fetch(), self.a); self.cycles += 7
            elif y == 3: n = self.fetch(); self.a = self.io_in((self.a << 8) | n); self.cycles += 7
            elif y == 4:
                v = self.rw(self.sp); self.ww(self.sp, self.get_rp(2, idx)); self.set_rp(2, v, idx)
                self.cycles += 15
            elif y == 5:
                self.de, self.hl = self.hl, self.de
            elif y == 6: self.iff1 = self.iff2 = 0
            elif y == 7: self.iff1 = self.iff2 = 1; self.ei_delay = True
            return
        if z == 4:
            a = self.fetchw(); self.cycles += 6
            if self.cond(y): self.push(self.pc); self.pc = a; self.cycles += 7
            return
        if z == 5:
            if q == 0:
                self.push(self.get_rp2(p, idx)); self.cycles += 7
                return
            if p == 0:
                a = self.fetchw(); self.push(self.pc); self.pc = a; self.cycles += 13
            return
        if z == 6:
            self.alu(y, self.fetch()); self.cycles += 3
            return
        self.push(self.pc); self.pc = y * 8; self.cycles += 7

    def exec_cb(self, idx):
        if idx is not None:
            addr = self.idx_addr(idx)
            op = self.fetch()
            self.cycles += 19
        else:
            op = self.fetch()
            self.r = (self.r & 0x80) | ((self.r + 1) & 0x7F)
            addr = self.hl
            self.cycles += 8
        x = op >> 6; y = (op >> 3) & 7; z = op & 7
        if idx is not None:
            v = self.rb(addr)
        else:
            v = self.get_r(z, None, addr)
        if x == 0:
            r = self.rot(y, v)
        elif x == 1:
            f = (self.f & CF) | HF | (0 if v & (1 << y) else (ZF | PF))
            if y == 7 and v & 0x80: f |= SF
            self.f = f
            return
        elif x == 2:
            r = v & ~(1 << y) & 0xFF
        else:
            r = v | (1 << y)
        if idx is not None:
            self.wb(addr, r)
            if z != 6: self.set_r(z, r, None, 0)
        else:
            self.set_r(z, r, None, addr)

    def exec_ed(self):
        op = self.fetch()
        self.r = (self.r & 0x80) | ((self.r + 1) & 0x7F)
        self.cycles += 8
        x = op >> 6; y = (op >> 3) & 7; z = op & 7; p = y >> 1; q = y & 1
        if x == 1:
            if z == 0:
                v = self.io_in(self.bc)
                if y != 6: self.set_r(y, v, None, 0)
                self.f = (self.f & CF) | SZP[v]
            elif z == 1:
                self.io_out(self.bc, 0 if y == 6 else self.get_r(y, None, 0))
            elif z == 2:
                if q == 0: self.hl = self.sbc16(self.hl, self.get_rp(p, None))
                else: self.hl = self.adc16(self.hl, self.get_rp(p, None))
                self.cycles += 7
            elif z == 3:
                a = self.fetchw(); self.cycles += 12
                if q == 0: self.ww(a, self.get_rp(p, None))
                else: self.set_rp(p, self.rw(a), None)
            elif z == 4:
                v = self.a; self.a = 0; self.alu(2, v)
            elif z == 5:
                self.pc = self.pop(); self.iff1 = self.iff2; self.cycles += 6
            elif z == 6:
                self.im = [0, 0, 1, 2, 0, 0, 1, 2][y]
            else:
                if y == 0: self.i = self.a
                elif y == 1: self.r = self.a
                elif y == 2:
                    self.a = self.i; self.f = (self.f & CF) | SZ[self.a] | (PF if self.iff2 else 0)
                elif y == 3:
                    self.a = self.r; self.f = (self.f & CF) | SZ[self.a] | (PF if self.iff2 else 0)
                elif y == 4:  # RRD
                    m = self.rb(self.hl)
                    self.wb(self.hl, ((self.a << 4) | (m >> 4)) & 0xFF)
                    self.a = (self.a & 0xF0) | (m & 0x0F)
                    self.f = (self.f & CF) | SZP[self.a]
                elif y == 5:  # RLD
                    m = self.rb(self.hl)
                    self.wb(self.hl, ((m << 4) | (self.a & 0x0F)) & 0xFF)
                    self.a = (self.a & 0xF0) | (m >> 4)
                    self.f = (self.f & CF) | SZP[self.a]
            return
        if x == 2 and y >= 4 and z <= 3:
            inc = 1 if y in (4, 6) else -1
            rep = y >= 6
            while True:
                if z == 0:  # LDI/LDD
                    self.wb(self.de, self.rb(self.hl))
                    self.hl = (self.hl + inc) & 0xFFFF
                    self.de = (self.de + inc) & 0xFFFF
                    self.bc = (self.bc - 1) & 0xFFFF
                    self.f = (self.f & (SF | ZF | CF)) | (PF if self.bc else 0)
                    self.cycles += 16
                    if rep and self.bc: continue
                    break
                if z == 1:  # CPI/CPD
                    v = self.rb(self.hl); r = (self.a - v) & 0xFF
                    self.hl = (self.hl + inc) & 0xFFFF
                    self.bc = (self.bc - 1) & 0xFFFF
                    self.f = (self.f & CF) | SZ[r] | NF | ((self.a ^ v ^ r) & HF) | (PF if self.bc else 0)
                    self.cycles += 16
                    if rep and self.bc and r != 0: continue
                    break
                if z == 2:  # INI/IND
                    self.wb(self.hl, self.io_in(self.bc))
                    self.hl = (self.hl + inc) & 0xFFFF
                    self.b = (self.b - 1) & 0xFF
                    self.f = ZF | NF if self.b == 0 else NF
                    if rep and self.b: continue
                    break
                # OUTI/OUTD
                v = self.rb(self.hl)
                self.b = (self.b - 1) & 0xFF
                self.io_out(self.bc, v)
                self.hl = (self.hl + inc) & 0xFFFF
                self.f = ZF | NF if self.b == 0 else NF
                if rep and self.b: continue
                break
            return
        # other ED opcodes: NOP
