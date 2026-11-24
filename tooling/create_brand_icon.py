"""Generate SneakerHub brand PNG assets with only Python's standard library.

Outputs a crisp acid-lime SH-inspired 'S' monogram. No external font or
copyrighted asset is used. Invoke BEFORE icon/splash Flutter generators.
"""
from pathlib import Path
import struct
import zlib

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'brand'
OUT.mkdir(parents=True, exist_ok=True)

LIME = (212, 244, 91, 255)
INK = (20, 20, 20, 255)


def png_chunk(name: bytes, data: bytes) -> bytes:
    payload = name + data
    return struct.pack('!I', len(data)) + payload + struct.pack(
        '!I', zlib.crc32(payload) & 0xffffffff)


def is_logo(x: float, y: float) -> bool:
    # Rounded, three-bar S made of clean intersecting geometric strokes.
    upper = .19 < x < .81 and .19 < y < .33
    left = .19 < x < .34 and .19 < y < .55
    middle = .19 < x < .81 and .435 < y < .565
    right = .66 < x < .81 and .45 < y < .81
    lower = .19 < x < .81 and .67 < y < .81
    return upper or left or middle or right or lower


def build(name: str, size: int, foreground: tuple, background: tuple) -> None:
    # A 2px-equivalent frame of the background avoids edge artifacts on
    # Android adaptive icons and Web favicons.
    scanlines = []
    for y in range(size):
        row = bytearray(b'\x00')
        fy = (y + .5) / size
        for x in range(size):
            fx = (x + .5) / size
            row.extend(foreground if is_logo(fx, fy) else background)
        scanlines.append(row)
    raw = b''.join(scanlines)
    png = (b'\x89PNG\r\n\x1a\n' +
        png_chunk(b'IHDR', struct.pack('!2I5B', size, size,
                                     8, 6, 0, 0, 0)) +
        png_chunk(b'IDAT', zlib.compress(raw, level=9)) +
        png_chunk(b'IEND', b''))
    (OUT / name).write_bytes(png)


if __name__ == '__main__':
    build('sneakerhub_icon.png', 512, INK, LIME)
    build('sneakerhub_splash.png', 1152, LIME, INK)
    print('Generated SneakerHub icon + splash PNGs in', OUT)
