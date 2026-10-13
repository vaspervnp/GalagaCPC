#!/bin/bash
# Galaga CPC for Linux (run in WSL or on Linux, after build.bat):
#   build/linux/GalagaCPC-x86_64.AppImage       one file: Caprice32 (the emulator), its ROMs
#                                               and the game's disk inside
#   build/linux/GalagaCPC-linux-x86_64.tar.gz   that AppImage, the manuals, how to play,
#                                               the licences
# Caprice32 has no Linux release, so it is built here from source - the commit its Windows
# release was made from - with SDL2, FreeType, libpng and zlib linked in. The compiler is
# Zig's clang, aimed at glibc 2.31 so that the emulator runs on distributions from about
# 2020 on; SDL2 loads X11, PulseAudio and ALSA itself when it starts, so the binary needs
# nothing but the C library. No root needed: the compiler, the sources and the X11 /
# PulseAudio / ALSA headers (Ubuntu's -dev packages, unpacked, not installed) are
# downloaded once into ~/.cache/galagacpc-linux, where the compiling is done.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$ROOT/build/linux
WORK=${GALAGA_LINUX_WORK:-$HOME/.cache/galagacpc-linux}
GLIBC=2.31
CAPRICE32=b5bf87c0ccd05b6d9324dbc7f6adc24ac9f3be35     # = cap32-win64.zip of 2025-02-14
JOBS=$(nproc)

DL=$WORK/dl SRC=$WORK/src PREFIX=$WORK/prefix SYSROOT=$WORK/sysroot BIN=$WORK/bin
mkdir -p "$DL" "$SRC" "$PREFIX" "$SYSROOT" "$BIN" "$OUT"

fetch() {   # fetch <file> <url> <sha256>
    if [ ! -f "$DL/$1" ]; then
        curl -fsSL -o "$DL/$1.part" "$2"
        mv "$DL/$1.part" "$DL/$1"
    fi
    echo "$3  $DL/$1" | sha256sum -c --quiet
}
unpack() {  # unpack <file> -> $SRC/<its top folder>, fresh
    local top
    top=$(tar -tf "$DL/$1" | head -1 | cut -d/ -f1)
    rm -rf "${SRC:?}/$top"
    tar -xf "$DL/$1" -C "$SRC"
    echo "$SRC/$top"
}

# --- The tools ---------------------------------------------------------------------------
fetch zig-0.14.1.tar.xz https://ziglang.org/download/0.14.1/zig-x86_64-linux-0.14.1.tar.xz \
    24aeeec8af16c381934a6cd7d95c807a8cb2cf7df9fa40d359aa884195c4716c
fetch appimagetool https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage \
    ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
fetch runtime-x86_64 https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64 \
    156f4bdbde9c52d01814600013e0a273f0118dc2de98975f3c8c63427ec79074   # "continuous": a new one needs this updated
ZIG=$WORK/zig-x86_64-linux-0.14.1/zig
[ -x "$ZIG" ] || tar -xf "$DL/zig-0.14.1.tar.xz" -C "$WORK"
chmod +x "$DL/appimagetool"
for t in "cc cc" "cxx c++" "ar ar" "ranlib ranlib"; do       # $BIN/zcc, zcxx, zar, zranlib
    set -- $t
    case $1 in cc|cxx) target="-target x86_64-linux-gnu.$GLIBC" ;; *) target= ;; esac
    printf '#!/bin/sh\nexec "%s" %s %s "$@"\n' "$ZIG" "$2" "$target" > "$BIN/z$1"
    chmod +x "$BIN/z$1"
done

# The X11 / OpenGL / PulseAudio / ALSA headers SDL2 is compiled against, from Ubuntu's packages
# (with the libraries, which SDL2's build reads the sonames from), and pkgconf to find them
if [ ! -e "$SYSROOT/.done" ]; then
    rm -rf "$SYSROOT" "$WORK/debs"; mkdir -p "$SYSROOT" "$WORK/debs"
    (cd "$WORK/debs" && apt-get download -q \
        libx11-dev libx11-6 libxext-dev libxext6 libxrandr-dev libxrandr2 libxi-dev libxi6 \
        libxcursor-dev libxcursor1 libxfixes-dev libxfixes3 libxrender-dev libxrender1 \
        libxss-dev libxss1 libxinerama-dev libxinerama1 libxcb1-dev libxcb1 libxau-dev \
        libxau6 libxdmcp-dev libxdmcp6 x11proto-dev libpulse-dev libpulse0 libasound2-dev \
        libasound2t64 libgl-dev libglx-dev mesa-common-dev pkgconf-bin libpkgconf7)
    for d in "$WORK"/debs/*.deb; do dpkg-deb -x "$d" "$SYSROOT"; done
    touch "$SYSROOT/.done"
fi
LIBDIR=$SYSROOT/usr/lib/x86_64-linux-gnu
printf '#!/bin/sh\nLD_LIBRARY_PATH="%s" exec "%s/usr/bin/pkgconf" "$@"\n' "$LIBDIR" "$SYSROOT" \
    > "$BIN/pkg-config"
chmod +x "$BIN/pkg-config"
export PATH=$BIN:$PATH PKG_CONFIG_SYSROOT_DIR=$SYSROOT
export PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig:$LIBDIR/pkgconfig:$SYSROOT/usr/share/pkgconfig
export CC=$BIN/zcc CXX=$BIN/zcxx AR=$BIN/zar RANLIB=$BIN/zranlib
CMAKE=(cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
       -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_AR="$BIN/zar" -DCMAKE_RANLIB="$BIN/zranlib"
       -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_SHARED_LIBS=OFF)

# --- The libraries, static ---------------------------------------------------------------
fetch zlib-1.3.1.tar.gz https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz \
    9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23
fetch libpng-1.6.50.tar.gz https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.50.tar.gz \
    71158e53cfdf2877bc99bcab33641d78df3f48e6e0daad030afe9cb8c031aa46
fetch freetype-2.13.3.tar.xz https://download.savannah.gnu.org/releases/freetype/freetype-2.13.3.tar.xz \
    0550350666d427c74daeb85d5ac7bb353acba5f76956395995311a9c6f063289
fetch SDL2-2.32.10.tar.gz https://github.com/libsdl-org/SDL/releases/download/release-2.32.10/SDL2-2.32.10.tar.gz \
    5f5993c530f084535c65a6879e9b26ad441169b3e25d789d83287040a9ca5165
if [ ! -e "$PREFIX/.done" ]; then
    rm -rf "$PREFIX"; mkdir -p "$PREFIX"
    s=$(unpack zlib-1.3.1.tar.gz)
    (cd "$s" && CFLAGS="-O2 -fPIC" ./configure --static --prefix="$PREFIX" >/dev/null && make -s -j"$JOBS" install)
    s=$(unpack libpng-1.6.50.tar.gz)
    "${CMAKE[@]}" -S "$s" -B "$s/b" -DPNG_SHARED=OFF -DPNG_TESTS=OFF -DPNG_TOOLS=OFF >/dev/null
    make -s -C "$s/b" -j"$JOBS" install >/dev/null
    s=$(unpack freetype-2.13.3.tar.xz)
    "${CMAKE[@]}" -S "$s" -B "$s/b" -DFT_DISABLE_ZLIB=ON -DFT_DISABLE_BZIP2=ON -DFT_DISABLE_PNG=ON \
        -DFT_DISABLE_HARFBUZZ=ON -DFT_DISABLE_BROTLI=ON >/dev/null
    make -s -C "$s/b" -j"$JOBS" install >/dev/null
    s=$(unpack SDL2-2.32.10.tar.gz)
    "${CMAKE[@]}" -S "$s" -B "$s/b" -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF \
        -DCMAKE_C_FLAGS="-isystem $SYSROOT/usr/include" -DCMAKE_LIBRARY_PATH="$LIBDIR" \
        -DCMAKE_INCLUDE_PATH="$SYSROOT/usr/include" \
        -DSDL_X11=ON -DSDL_X11_SHARED=ON -DSDL_WAYLAND=OFF -DSDL_KMSDRM=OFF -DSDL_VULKAN=OFF \
        -DSDL_PULSEAUDIO=ON -DSDL_PULSEAUDIO_SHARED=ON -DSDL_ALSA=ON -DSDL_ALSA_SHARED=ON \
        -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_DBUS=OFF -DSDL_IBUS=OFF \
        -DSDL_LIBUDEV=OFF -DSDL_HIDAPI_LIBUSB=OFF -DSDL_RPATH=OFF > "$s/cmake.log"
    make -s -C "$s/b" -j"$JOBS" install >/dev/null
    for need in VIDEO_DRIVER_X11 VIDEO_OPENGL AUDIO_DRIVER_PULSEAUDIO AUDIO_DRIVER_ALSA; do
        grep -q "#define SDL_$need 1" "$PREFIX/include/SDL2/SDL_config.h" \
            || { echo "SDL2 built without $need (see $s/cmake.log)"; exit 1; }
    done
    touch "$PREFIX/.done"
fi

# --- Caprice32 ---------------------------------------------------------------------------
CAP=$SRC/caprice32
if [ ! -x "$CAP/cap32" ] || [ "$(git -C "$CAP" rev-parse HEAD)" != "$CAPRICE32" ]; then
    [ -d "$CAP/.git" ] || git clone -q https://github.com/ColinPitrat/caprice32.git "$CAP"
    git -C "$CAP" fetch -q origin
    git -C "$CAP" checkout -q --force "$CAPRICE32"
    git -C "$CAP" clean -qfdx
    make -s -C "$CAP" -j"$JOBS" cap32 RELEASE=1 CXX="$BIN/zcxx" TEST_SOURCES= BENCH_SOURCES= \
        IPATHS="-Isrc/ \$(CAPS_INCLUDES) -Isrc/gui/includes -I$PREFIX/include -I$PREFIX/include/freetype2 -I$PREFIX/include/SDL2 -D_REENTRANT" \
        LIBS="-L$PREFIX/lib -lSDL2 -lfreetype -lpng16 -lz -lm -ldl -lpthread" \
        WARNINGS="-Wno-everything" > "$WORK/cap32-build.log" 2>&1 \
        || { tail -30 "$WORK/cap32-build.log"; exit 1; }
fi
glibc_max=$(objdump -T "$CAP/cap32" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1)
echo "cap32 needs: $(objdump -p "$CAP/cap32" | awk '/NEEDED/{printf "%s ", $2}')- up to $glibc_max"
[ "$(printf '%s\n' "GLIBC_$GLIBC" "$glibc_max" | sort -V | tail -1)" = "GLIBC_$GLIBC" ] \
    || { echo "cap32 needs a glibc newer than $GLIBC"; exit 1; }

# --- The AppImage ------------------------------------------------------------------------
APPDIR=$WORK/AppDir                 # staged on Linux's own file system (not /mnt/c, where
rm -rf "$APPDIR"                    # every file is rwxrwxrwx), for proper file modes
P=$APPDIR/payload
mkdir -p "$P/screenshots" "$P/snap"                 # where F3 / Shift+F3 save
cp "$CAP/cap32" "$CAP/COPYING.txt" "$CAP/README.md" "$CAP/cap32.cfg" "$P/"
cp -r "$CAP/rom" "$CAP/resources" "$CAP/licenses" "$P/"
rm -rf "$P/resources/freedesktop" "$P/resources/Info.plist"
install -m644 "$ROOT/build/galaga.dsk" "$P/"
install -m644 "$ROOT/tools/linux/README.txt" "$P/GalagaCPC.txt"
cfg=$P/cap32.cfg
for kv in model=2 scr_scale=3 scr_fps=0 scr_led=0 auto_pause=1; do   # as for Windows
    grep -q "^${kv%%=*}=" "$cfg" || { echo "no ${kv%%=*} in cap32.cfg"; exit 1; }
    sed -i "s/^${kv%%=*}=.*/$kv/" "$cfg"
done
(cd "$P" && find . -type f ! -name .id -print0 | sort -z | xargs -0 sha1sum | sha1sum | cut -c1-12 | tr a-f A-F) > "$P/.id"
install -m755 "$ROOT/tools/linux/AppRun" "$APPDIR/"
install -m644 "$ROOT/tools/linux/GalagaCPC.desktop" "$APPDIR/"
python3 - "$ROOT/assets/player_sprite.bmp" "$APPDIR/galagacpc.png" <<'EOF'
import sys
from PIL import Image                   # the player's fighter, as for the Windows icon
sprite = Image.open(sys.argv[1]).convert('RGB')
ship = sprite.convert('RGBA')
ship.putalpha(sprite.convert('L').point(lambda v: 255 if v else 0))   # black: see-through
ship.resize((256, 256), Image.NEAREST).save(sys.argv[2])
EOF
ln -sf galagacpc.png "$APPDIR/.DirIcon"
IMAGE=$OUT/GalagaCPC-x86_64.AppImage
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$DL/appimagetool" -n --runtime-file "$DL/runtime-x86_64" \
    "$APPDIR" "$IMAGE" >/dev/null 2>"$WORK/appimagetool.log" \
    || { cat "$WORK/appimagetool.log"; exit 1; }

# --- The release archive -----------------------------------------------------------------
R=$WORK/release/GalagaCPC
rm -rf "$WORK/release"
mkdir -p "$R/licences"
install -m755 "$IMAGE" "$R/"
install -m644 "$ROOT/tools/linux/README.txt" "$ROOT/manual-en.pdf" "$ROOT/manual-el.pdf" "$R/"
cp "$CAP/COPYING.txt" "$R/licences/Caprice32-GPL.txt"
cp "$CAP"/licenses/* "$R/licences/"
cp "$SRC"/SDL2-2.32.10/LICENSE.txt "$R/licences/SDL2-zlib.txt"
cp "$SRC"/freetype-2.13.3/docs/FTL.TXT "$R/licences/FreeType-FTL.txt"
cp "$SRC"/libpng-1.6.50/LICENSE "$R/licences/libpng.txt"
cp "$SRC"/zlib-1.3.1/LICENSE "$R/licences/zlib.txt"
TARBALL=$OUT/GalagaCPC-linux-x86_64.tar.gz
tar -czf "$TARBALL" -C "$WORK/release" --owner=0 --group=0 GalagaCPC
for f in "$IMAGE" "$TARBALL"; do
    printf 'wrote %s (%s MB)\n' "${f#"$ROOT"/}" "$(awk "BEGIN{printf \"%.1f\", $(stat -c %s "$f")/1e6}")"
done
