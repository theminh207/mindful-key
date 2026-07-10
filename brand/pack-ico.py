#!/usr/bin/env python3
# Đóng nhiều PNG thành 1 file .ico (nhúng PNG — hợp lệ Windows Vista+). Không cần Pillow.
# Dùng: python3 pack-ico.py out.ico 16.png 32.png 48.png 256.png
import struct, sys

out, pngs = sys.argv[1], sys.argv[2:]
imgs = []
for p in pngs:
    data = open(p, "rb").read()
    w = struct.unpack(">I", data[16:20])[0]
    h = struct.unpack(">I", data[20:24])[0]
    imgs.append((w, h, data))

n = len(imgs)
header = struct.pack("<HHH", 0, 1, n)
offset = 6 + 16 * n
entries, blob = b"", b""
for w, h, data in imgs:
    bw = 0 if w >= 256 else w
    bh = 0 if h >= 256 else h
    entries += struct.pack("<BBBBHHII", bw, bh, 0, 0, 1, 32, len(data), offset)
    offset += len(data)
    blob += data

open(out, "wb").write(header + entries + blob)
print("Wrote", out, "(%d images)" % n)
