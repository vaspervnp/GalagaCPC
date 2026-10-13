"""Galaga CPC for Windows (run after build.bat):
  build/win/GalagaCPC.exe          one file: the launcher, with Caprice32 (the emulator),
                                   its ROMs and the game's disk inside
  build/win/GalagaCPC-win64.zip    that exe, the manuals, how to play, the licences
The launcher (tools/windows/Launcher.cs) is compiled by the .NET Framework's csc.exe;
Caprice32's Windows release is downloaded once into build/win/.
"""
import os
import re
import shutil
import subprocess
import tempfile
import urllib.request
import zipfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = os.path.join(ROOT, 'build', 'win')
CAP_URL = 'https://github.com/ColinPitrat/caprice32/releases/download/latest/cap32-win64.zip'
CSC = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Microsoft.NET', 'Framework64',
                   'v4.0.30319', 'csc.exe')


def zip_dir(src, dest, prefix=''):
    with zipfile.ZipFile(dest, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for folder, dirs, files in os.walk(src):
            for d in sorted(dirs):                   # empty folders too (screenshots, snap)
                z.write(os.path.join(folder, d), os.path.join(prefix, os.path.relpath(os.path.join(folder, d), src)) + '/')
            for f in sorted(files):
                full = os.path.join(folder, f)
                z.write(full, os.path.join(prefix, os.path.relpath(full, src)))


def main():
    os.makedirs(B, exist_ok=True)
    cap_zip = os.path.join(B, 'cap32-win64.zip')
    if not os.path.exists(cap_zip):
        urllib.request.urlretrieve(CAP_URL, cap_zip)

    # The payload: Caprice32 as released, set up for the game, and the disk
    payload = os.path.join(B, 'payload')
    shutil.rmtree(payload, ignore_errors=True)
    with zipfile.ZipFile(cap_zip) as z:
        for name in z.namelist():
            parts = name.split('/')[1:]          # drop cap32-win64/
            if not parts or name.endswith('/'):
                continue
            dest = os.path.join(payload, *parts)
            os.makedirs(os.path.dirname(dest), exist_ok=True)
            with z.open(name) as src, open(dest, 'wb') as dst:
                shutil.copyfileobj(src, dst)
    shutil.rmtree(os.path.join(payload, 'resources', 'freedesktop'), ignore_errors=True)
    os.remove(os.path.join(payload, 'resources', 'Info.plist'))
    shutil.copyfile(os.path.join(ROOT, 'build', 'galaga.dsk'), os.path.join(payload, 'galaga.dsk'))
    for d in ('screenshots', 'snap'):                 # where F3 / Shift+F3 save
        os.makedirs(os.path.join(payload, d), exist_ok=True)
    shutil.copyfile(os.path.join(ROOT, 'tools', 'windows', 'README.txt'),
                    os.path.join(payload, 'GalagaCPC.txt'))
    cfg_path = os.path.join(payload, 'cap32.cfg')
    cfg = open(cfg_path, encoding='latin-1').read()
    for key, value in {
        'model': 2,                 # CPC6128: disk drive, RUN"GALAGA
        'scr_scale': 3,             # 1152x810 window
        'scr_fps': 0,               # no FPS counter over the game
        'scr_led': 0,
        'auto_pause': 1,            # pause while the window is in the background
    }.items():
        cfg, n = re.subn(rf'^{key}=.*$', f'{key}={value}', cfg, flags=re.M)
        assert n == 1, key
    open(cfg_path, 'w', encoding='latin-1', newline='\n').write(cfg)
    payload_zip = os.path.join(B, 'payload.zip')
    zip_dir(payload, payload_zip)

    # The icon: the player's fighter, from the game's own sprite
    icon = os.path.join(B, 'icon.ico')
    sprite = Image.open(os.path.join(ROOT, 'assets', 'player_sprite.bmp')).convert('RGB')
    ship = sprite.convert('RGBA')
    ship.putalpha(sprite.convert('L').point(lambda v: 255 if v else 0))   # black: see-through
    ship.resize((256, 256), Image.NEAREST).save(icon, sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])

    # Compile (csc wants local Windows paths)
    with tempfile.TemporaryDirectory(prefix='galaga-launcher') as tmp:
        for f in (os.path.join(ROOT, 'tools', 'windows', 'Launcher.cs'), payload_zip, icon):
            shutil.copy(f, tmp)
        subprocess.run([CSC, '/nologo', '/optimize', '/target:winexe', '/out:GalagaCPC.exe',
                        '/win32icon:icon.ico', '/resource:payload.zip,payload.zip',
                        '/r:System.IO.Compression.dll', '/r:System.IO.Compression.FileSystem.dll',
                        '/r:System.Windows.Forms.dll', 'Launcher.cs'], cwd=tmp, check=True)
        exe = os.path.join(B, 'GalagaCPC.exe')
        shutil.copyfile(os.path.join(tmp, 'GalagaCPC.exe'), exe)

    # The release zip
    release = os.path.join(B, 'release', 'GalagaCPC')
    shutil.rmtree(os.path.join(B, 'release'), ignore_errors=True)
    os.makedirs(os.path.join(release, 'licences'))
    for f in (exe, os.path.join(ROOT, 'tools', 'windows', 'README.txt'),
              os.path.join(ROOT, 'manual-en.pdf'), os.path.join(ROOT, 'manual-el.pdf')):
        shutil.copy(f, release)
    shutil.copyfile(os.path.join(payload, 'COPYING.txt'),
                    os.path.join(release, 'licences', 'Caprice32-GPL.txt'))
    for f in os.listdir(os.path.join(payload, 'licenses')):
        shutil.copy(os.path.join(payload, 'licenses', f), os.path.join(release, 'licences'))
    release_zip = os.path.join(B, 'GalagaCPC-win64.zip')
    zip_dir(os.path.dirname(release), release_zip)
    for f in (exe, release_zip):
        print(f'wrote {os.path.relpath(f, ROOT)} ({os.path.getsize(f) / 1e6:.1f} MB)')


if __name__ == '__main__':
    main()
