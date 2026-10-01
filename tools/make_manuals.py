"""Build manual-en.pdf and manual-el.pdf from the Markdown manuals.

Converts each manual to HTML (Python-Markdown) and prints it to an A4 PDF
with headless Chrome or Edge. Run from anywhere: python tools/make_manuals.py
"""
import os
import pathlib
import subprocess
import sys
import tempfile

import markdown

REPO = pathlib.Path(__file__).resolve().parent.parent
BROWSERS = [
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'google-chrome', 'chromium', 'chrome',
]

CSS = """
@page { size: A4; margin: 16mm 18mm; }
body { font-family: 'Segoe UI', Arial, sans-serif; font-size: 10.5pt; line-height: 1.45; color: #111; }
h1 { font-size: 22pt; text-align: center; margin: 0 0 12pt; letter-spacing: 1pt; }
h2 { font-size: 14pt; border-bottom: 1.5pt solid #c00; padding-bottom: 2pt; margin: 16pt 0 6pt;
     break-after: avoid; }
p, li { margin: 4pt 0; }
table { border-collapse: collapse; margin: 6pt 0; }
th, td { border: 0.75pt solid #999; padding: 3pt 8pt; text-align: left; }
th { background: #eee; }
code { font-family: Consolas, monospace; background: #f2f2f2; padding: 0 2pt; }
p:has(> img:only-child) { text-align: center; margin: 8pt 0; break-inside: avoid; }
img { width: 62%; image-rendering: pixelated; border: 1pt solid #333; }
em { color: #444; }
"""


def find_browser():
    for b in BROWSERS:
        if os.path.isabs(b) and os.path.exists(b):
            return b
        if not os.path.isabs(b):
            from shutil import which
            if which(b):
                return which(b)
    sys.exit('Chrome or Edge not found')


def build(lang, browser):
    src = REPO / f'manual-{lang}.md'
    body = markdown.markdown(src.read_text(encoding='utf-8'), extensions=['tables'])
    html = (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8">'
            f'<base href="{REPO.as_uri()}/"><style>{CSS}</style></head><body>{body}</body></html>')
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / f'manual-{lang}.html'
        page.write_text(html, encoding='utf-8')
        out = REPO / f'manual-{lang}.pdf'
        subprocess.run([browser, '--headless', '--disable-gpu', '--no-pdf-header-footer',
                        '--allow-file-access-from-files', f'--user-data-dir={tmp}/profile',
                        f'--print-to-pdf={out}', page.as_uri()],
                       check=True, capture_output=True)
    print('wrote', out.name)


if __name__ == '__main__':
    browser = find_browser()
    for lang in ('en', 'el'):
        build(lang, browser)
