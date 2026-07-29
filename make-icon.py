#!/usr/bin/env python3
"""Generate a simple 1024x1024 app icon for the IPA build."""
import struct
import zlib
from pathlib import Path

W, H = 1024, 1024
BG = (18, 18, 22)
FG = (255, 255, 255)

rows = []
for y in range(H):
    row = b"\x00"
    for x in range(W):
        cx, cy = W // 2, H // 2
        dx = abs(x - cx)
        dy = abs(y - cy)
        # Simple "M" block shape in center
        in_m = (
            250 <= dx <= 420
            and 300 <= y <= 720
            and not (320 <= dx <= 350 and 420 <= y <= 720)
            and not (320 <= dx <= 350 and 300 <= y <= 520 and x > cx)
        ) or (
            dx <= 80 and 300 <= y <= 720
        )
        color = FG if in_m else BG
        row += bytes(color)
    rows.append(row)

raw = b"".join(rows)
compressed = zlib.compress(raw, 9)

def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", compressed)
png += chunk(b"IEND", b"")

out = Path(__file__).resolve().parent / "M4cNikApp" / "Assets.xcassets" / "AppIcon.appiconset" / "icon-1024.png"
out.write_bytes(png)
contents = out.parent / "Contents.json"
contents.write_text(
    """{
  "images": [
    {
      "filename": "icon-1024.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
""",
    encoding="utf-8",
)
print("Wrote", out)
