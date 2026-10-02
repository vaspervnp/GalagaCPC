"""Build the cassette inlay (J-card): cover-tape.pdf and cover-tape.jpg.

Layout, left to right at actual size on A4 landscape: back flap, spine,
front, and an inside panel that folds behind the front. The arcade sprites
come from assets/*.bmp and the screenshot from assets/Screenshots.
Run from anywhere: python tools/make_tape_cover.py
"""
import base64
import io
import pathlib
import random
import subprocess
import tempfile

from PIL import Image

from make_manuals import find_browser

REPO = pathlib.Path(__file__).resolve().parent.parent
ASSETS = REPO / 'assets'
H = 101.6                                   # J-card height (mm)
FLAP, SPINE, FRONT, INSIDE = 15.9, 12.7, 63.5, 63.5


def sprite(name, scale=8):
    """16x16 sprite, black made transparent, as a data URI."""
    im = Image.open(ASSETS / name).convert('RGBA')
    im.putdata([(r, g, b, 0) if r + g + b < 40 else (r, g, b, 255) for r, g, b, _ in im.get_flattened_data()])
    im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    buf = io.BytesIO()
    im.save(buf, 'PNG')
    return 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()


def image(path):
    return 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()


def stars(w, h, n, seed):
    rnd = random.Random(seed)
    cols = ['#6ff', '#fff', '#ff6', '#f6f', '#6af']
    return ''.join(f'<circle cx="{rnd.uniform(0, w):.1f}" cy="{rnd.uniform(0, h):.1f}" '
                   f'r="{rnd.choice((0.15, 0.2, 0.3))}" fill="{rnd.choice(cols)}"/>' for _ in range(n))


def starfield(w, h, n, seed, rays=False):
    lines = ''
    if rays:
        cx, cy = w / 2, h * 0.52
        for i in range(36):
            import math
            a = i * math.pi / 18
            lines += (f'<line x1="{cx}" y1="{cy}" x2="{cx + 120 * math.cos(a):.1f}" '
                      f'y2="{cy + 120 * math.sin(a):.1f}" stroke="#1d2a7a" stroke-width="0.25"/>')
    return (f'<svg class="sky" viewBox="0 0 {w} {h}" preserveAspectRatio="none">'
            f'{lines}{stars(w, h, n, seed)}</svg>')


def html():
    boss = sprite('galboss_flagship_1.bmp')
    fly = sprite('goei_butterfly_1.bmp')
    bee = sprite('zako_bee_1.bmp')
    ship = sprite('player_sprite.bmp')
    shot = image(ASSETS / 'Screenshots' / '07_captured.png')
    row = lambda img, n, cls: ''.join(f'<img class="{cls}" src="{img}">' for _ in range(n))
    total = FLAP + SPINE + FRONT + INSIDE
    return f'''<!doctype html><html><head><meta charset="utf-8"><style>
@page {{ size: A4 landscape; margin: 0; }}
* {{ box-sizing: border-box; margin: 0; padding: 0; }}
html, body {{ width: 297mm; height: 210mm; background: #f8f8f6; }}
body {{ font-family: Arial, Helvetica, sans-serif; color: #fff; position: relative; }}
.labels, .card, .foot {{ position: absolute; left: calc((297mm - {total}mm) / 2); width: {total}mm; }}
.labels {{ top: calc((210mm - {H}mm) / 2 - 7mm); display: flex; color: #555; font: bold 2.6mm Arial; }}
.labels div {{ text-align: center; }}
.foot {{ left: 0; width: 297mm; top: calc((210mm + {H}mm) / 2 + 4mm); text-align: center; color: #555; font: bold 2.6mm Arial; }}
.card {{ top: calc((210mm - {H}mm) / 2); height: {H}mm; display: flex; background: #0a0b3a;
         outline: 0.2mm solid #888; }}
.panel {{ position: relative; height: 100%; overflow: hidden; }}
.panel + .panel {{ border-left: 0.25mm dashed #9aa; }}
.sky {{ position: absolute; inset: 0; width: 100%; height: 100%; }}
.frame {{ position: absolute; inset: 1.6mm; border: 0.5mm solid #2ad4e8; outline: 0.25mm solid #2a7fe8;
          outline-offset: 0.6mm; }}
.frame::before {{ content: ""; position: absolute; left: 1.5mm; right: 1.5mm; top: 1.4mm;
                  border-top: 0.35mm solid #f5c400; }}
.cyan {{ color: #2ad4e8; }} .yellow {{ color: #ffd21f; }}
.logo {{ font: 18.5mm Impact, 'Arial Black', sans-serif; color: #ffd21f; letter-spacing: 0.2mm;
         -webkit-text-stroke: 0.9mm #c4161c; paint-order: stroke fill; line-height: 1;
         text-shadow: 0 0.5mm 0 #7a0a10; }}
/* front */
.front .content {{ position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; }}
.front .kicker {{ margin-top: 5.2mm; font: bold 2.7mm Arial; }}
.front .logo {{ margin-top: 1.2mm; }}
.front .sub {{ font: bold 2.9mm Arial; margin-top: 0.6mm; letter-spacing: 0.1mm; }}
.fleet {{ display: flex; justify-content: center; gap: 1.6mm; }}
.fleet img {{ image-rendering: pixelated; }}
.boss {{ width: 8mm; }} .fly {{ width: 7mm; }} .bee {{ width: 6mm; }}
.r1 {{ margin-top: 3.5mm; }} .r2, .r3 {{ margin-top: 0.8mm; }}
.beam {{ margin-top: 1.5mm; width: 0; height: 0; border-left: 7mm solid transparent; border-right: 7mm solid transparent;
         border-bottom: 8mm solid rgba(80, 160, 255, 0.28); }}
.ship {{ width: 11mm; image-rendering: pixelated; margin-top: -0.5mm; filter: drop-shadow(0 0 1.2mm #4af); }}
.badge {{ position: absolute; left: 7mm; right: 7mm; bottom: 5mm; border: 0.45mm solid #ffd21f; border-radius: 1.6mm;
          background: #0a0b2e; text-align: center; padding: 0.9mm 0 0.8mm; }}
.badge b {{ display: block; font: bold 3.6mm Arial; color: #ffd21f; }}
.badge span {{ font: bold 2.2mm Arial; color: #2ad4e8; letter-spacing: 0.2mm; }}
/* spine and flap: rotated text */
.spine {{ background: #6a2290; }}
.vert {{ position: absolute; left: 50%; top: 50%; white-space: nowrap; transform: translate(-50%, -50%) rotate(-90deg);
         font: bold 4mm Arial; letter-spacing: 0.3mm; }}
.vert .logo {{ font-size: 7.5mm; -webkit-text-stroke-width: 0.45mm; vertical-align: -1mm; margin-right: 2mm; }}
.flap .vert {{ font-size: 2.6mm; line-height: 1.45; text-align: center; white-space: normal; width: 90mm; }}
/* inside */
.inside .content {{ position: absolute; inset: 5.6mm 5mm 4mm 5mm; display: flex; flex-direction: column; }}
h1 {{ font: 4.15mm Impact, 'Arial Black', sans-serif; letter-spacing: 0.1mm; margin-top: 0.4mm; }}
h2 {{ font: bold 2.7mm Arial; color: #2ad4e8; margin-top: 0.5mm; }}
h3 {{ font: bold 2.9mm Arial; color: #ffd21f; margin-top: 1.8mm; border-top: 0.3mm solid #2ad4e8; padding-top: 1.2mm; }}
p {{ font-size: 2.05mm; line-height: 1.35; margin-top: 1mm; color: #e8ecff; }}
.shot {{ margin-top: 1.8mm; display: flex; gap: 2mm; align-items: center; }}
.shot img {{ width: 29mm; border: 0.5mm solid #c8962a; image-rendering: pixelated; }}
.shot ul {{ list-style: none; font: bold 2mm Arial; color: #2ad4e8; }}
.shot li {{ margin: 0.6mm 0; }}
.shot li::before {{ content: ""; display: inline-block; width: 1mm; height: 1mm; background: #ffd21f;
                    margin-right: 1.2mm; vertical-align: 0.2mm; }}
.load {{ font: bold 2.05mm Arial; line-height: 1.45; margin-top: 1mm; }}
.load code {{ font: bold 2.4mm Consolas, monospace; color: #ffd21f; }}
.keys {{ display: flex; gap: 1.2mm; margin-top: 1.2mm; }}
.keys div {{ flex: 1; white-space: nowrap; border: 0.3mm solid #2a7fe8; border-radius: 0.8mm; background: #10164a; padding: 0.8mm 1.2mm; }}
.keys i {{ display: block; font: bold 1.9mm Arial; color: #2ad4e8; font-style: normal; }}
.keys b {{ display: block; font: bold 2.2mm Arial; margin-top: 0.4mm; }}
.credits {{ margin-top: auto; font: bold 2.2mm Arial; color: #2ad4e8; }}
</style></head><body>
<div class="labels"><div style="width:{FLAP}mm">FLAP</div><div style="width:{SPINE}mm">SPINE</div>
<div style="width:{FRONT}mm">FRONT</div><div style="width:{INSIDE}mm">INSIDE (FOLDS BEHIND FRONT)</div></div>
<div class="card">
  <div class="panel flap" style="width:{FLAP}mm">{starfield(FLAP, H, 30, 1)}
    <div class="vert"><span class="yellow">LOADING:</span> TYPE <span class="yellow">RUN"</span> AND PRESS ENTER,
    THEN PLAY<br><span class="cyan">CPC 6128 / 664: TYPE |TAPE FIRST</span></div></div>
  <div class="panel spine" style="width:{SPINE}mm">
    <div class="vert"><span class="logo">GALAGA</span>AMSTRAD CPC 464 <span class="cyan">/ REVIVE8BIT</span></div></div>
  <div class="panel front" style="width:{FRONT}mm">{starfield(FRONT, H, 140, 2, rays=True)}<div class="frame"></div>
    <div class="content">
      <div class="kicker cyan">REVIVE8BIT &nbsp;/&nbsp; AMSTRAD CPC</div>
      <div class="logo">GALAGA</div>
      <div class="sub">THE ARCADE CLASSIC REBORN</div>
      <div class="fleet r1">{row(boss, 2, 'boss')}</div>
      <div class="fleet r2">{row(fly, 5, 'fly')}</div>
      <div class="fleet r3">{row(bee, 6, 'bee')}</div>
      <div class="beam"></div>
      <img class="ship" src="{ship}">
    </div>
    <div class="badge"><b>CPC 464 CASSETTE</b><span>1 OR 2 PLAYERS</span></div>
  </div>
  <div class="panel inside" style="width:{INSIDE}mm">{starfield(INSIDE, H, 90, 3)}<div class="frame"></div>
    <div class="content">
      <h1>THE GALAXY IS UNDER ATTACK!</h1>
      <h2>PILOT THE LAST LINE OF DEFENCE.</h2>
      <p>Blast through alien formations, dodge dive attacks and rescue your captured fighter
      for double firepower. Reach the challenging stages and chase the high score!</p>
      <div class="shot"><img src="{shot}"><ul><li>28-ENEMY WAVES</li><li>CHALLENGING STAGES</li>
      <li>CAPTURE &amp; RESCUE</li><li>1 OR 2 PLAYERS</li><li>4 DIFFICULTIES</li></ul></div>
      <h3>LOADING</h3>
      <div class="load">CPC 464: <code>RUN"</code> + ENTER, then PLAY and any key.<br>
      CPC 664 / 6128: <code>|TAPE</code> + ENTER first.<br>
      <span class="cyan">Loading takes about 4&frac12; minutes. Scores are not saved on tape.</span></div>
      <h3>TAKE CONTROL</h3>
      <div class="keys"><div style="flex:1.7"><i>MOVE</i><b>&larr; &rarr; / O P</b></div><div><i>FIRE</i><b>SPACE</b></div>
      <div><i>PAUSE</i><b>H</b></div><div><i>START</i><b>1 / 2</b></div></div>
      <div class="credits">REVIVE8BIT &nbsp;/&nbsp; 2026 &nbsp;/&nbsp; VASPER</div>
    </div>
  </div>
</div>
<div class="foot">A4 LANDSCAPE &nbsp;/&nbsp; CPC CASSETTE INLAY &nbsp;/&nbsp; PRINT AT 100% - ACTUAL SIZE &nbsp;/&nbsp;
CUT ALONG THE OUTER EDGE, FOLD ON THE DASHED LINES</div>
</body></html>'''


def main():
    browser = find_browser()
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / 'cover-tape.html'
        page.write_text(html(), encoding='utf-8')
        common = [browser, '--headless', '--disable-gpu', '--hide-scrollbars', f'--user-data-dir={tmp}/profile']
        subprocess.run(common + ['--no-pdf-header-footer', f'--print-to-pdf={REPO / "cover-tape.pdf"}',
                                 page.as_uri()], check=True, capture_output=True)
        png = pathlib.Path(tmp) / 'cover.png'
        # A4 at 96 CSS px per inch is 1123 x 794; scale to 300 dpi
        subprocess.run(common + ['--window-size=1123,794', '--force-device-scale-factor=3.125',
                                 f'--screenshot={png}', page.as_uri()], check=True, capture_output=True)
        Image.open(png).convert('RGB').save(REPO / 'cover-tape.jpg', quality=92, dpi=(300, 300))
    print('wrote cover-tape.pdf and cover-tape.jpg')


if __name__ == '__main__':
    main()
