GALAGA CPC - for Linux
REVIVE8BIT - 2026 - VASPER

An Amstrad CPC game, with the emulator that runs it included.

TO PLAY
  GalagaCPC-x86_64.AppImage is the whole thing. Make it executable, then run it:
  double-click it, or in a terminal

    chmod +x GalagaCPC-x86_64.AppImage
    ./GalagaCPC-x86_64.AppImage

  (in most file managers: Properties, Permissions, "Allow executing file as program").
  Nothing is installed: the first time, it copies the emulator and the game to
  ~/.local/share/GalagaCPC (about 15 MB), then starts. The REVIVE8BIT screen comes
  first, then the game loads.

  It runs on 64-bit PC Linux from about 2020 on (glibc 2.31 or newer), under X11 or
  Wayland, with PulseAudio, PipeWire or ALSA for the sound. AppImages need FUSE: if it
  does not start and mentions FUSE, install your distribution's fuse package (libfuse2
  is not needed), or run it as ./GalagaCPC-x86_64.AppImage --appimage-extract-and-run

KEYS
  Cursor keys or O P       move left / right
  SPACE                    fire (on the title screen: start a 1-player game)
  1 / 2                    1-player / 2-player game (title screen)
  Left / Right             choose the difficulty (title screen)
  H                        pause
  A joystick works too (Fire 1 = SPACE).

  F1 opens the emulator's menu, F2 switches to full screen, F10 quits.

HIGH SCORES
  The Top 5 is written to the game's disk, but the emulator keeps the change only if the
  disk is saved: after entering your initials, press F1 and save the disk in drive A.
  If you quit with unsaved changes, the emulator asks first.

The manual: manual-en.pdf (English), manual-el.pdf (Greek).

THE EMULATOR
  Caprice32, https://github.com/ColinPitrat/caprice32 - free software under the GNU GPL,
  version 2 (licences/Caprice32-GPL.txt); its source code is at that address, and this
  build is commit b5bf87c, the one its Windows release of February 2025 was made from.
  It includes the Amstrad CPC system ROMs, which Amstrad allows to be distributed with
  emulators. Built in with it: SDL2 (zlib licence), FreeType (FreeType licence), libpng
  (libpng licence) and zlib (zlib licence) - their licences are in licences/ too.
