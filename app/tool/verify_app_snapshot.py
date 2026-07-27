#!/usr/bin/env python3
"""يفحص أنّ لقطةَ Dart في `App.framework` **يراها `dyld`** في كلّ معماريّة.

لماذا: محرّكُ Flutter يطلب من `App.framework` أربعةَ رموزٍ عند الإقلاع
(`kDartVmSnapshotData` وأخواتها). طلبُها يمرّ بجدول تصدير `dyld`، لا بجدول
الرموز الساكن (`SYMTAB`) — فمكتبةٌ فيها الرموزُ ساكنةً وحدَها تبدو سليمةً لكلّ
أداةٍ تنظر إلى `nm`، ويردّ عليها المحرّكُ بـ:

    [ERROR:flutter/runtime/dart_vm_data.cc] Isolate snapshot invalid …
    [ERROR:flutter/runtime/dart_vm_lifecycle.cc] Could not create Dart VM instance
    Segmentation fault

حدث هذا فعلًا في 2026-07-26: Flutter 3.44.0 استبدل ربطَ `clang` بكاتبِ Mach-O
داخلَ `gen_snapshot` (‏`--snapshot_kind=app-aot-macho-dylib`)، فخرجت المكتبةُ
بلا `LC_DYLD_INFO_ONLY` ولا `LC_DYLD_EXPORTS_TRIE` أصلًا. الحزمةُ مرّت بكلّ
فحوصنا آنذاك — الوجود، والمعماريّتان، والتوقيع، وأدنى نسخةِ نظام — وماتت على
Big Sur قبل أن تُرسم بكسل. المقارنةُ التي كشفت العلّة كانت مع حزمةِ hisabi
العاملة: عندها `LC_DYLD_INFO_ONLY`، وعندنا لا شيء.

يقرأ الملفّ مباشرةً (Mach-O fat وthin) فلا يحتاج أدواتِ Xcode ⇒ يعمل على لينكس
أيضًا لفحص حزمةٍ مفكوكةٍ من DMG.

الاستعمال:
    python3 tool/verify_app_snapshot.py <Belote.app>
"""

import os
import struct
import sys

FAT, FAT64, MACHO64 = 0xCAFEBABE, 0xCAFEBABF, 0xFEEDFACF
LC_SYMTAB = 0x2
LC_DYLD_INFO_ONLY = 0x80000022
LC_DYLD_EXPORTS_TRIE = 0x80000033
LC_DYLD_CHAINED_FIXUPS = 0x80000034
N_EXT = 0x01  # الرمزُ خارجيّ (مرشَّحٌ للتصدير)
CPUS = {0x1000007: "x86_64", 0x100000C: "arm64"}

NEEDED = (
    "_kDartVmSnapshotData",
    "_kDartVmSnapshotInstructions",
    "_kDartIsolateSnapshotData",
    "_kDartIsolateSnapshotInstructions",
)


def _slice_report(data, off):
    """يردّ (معماريّة, هل يوجد جدولُ تصديرٍ لـdyld, الرموزُ الخارجيّةُ الموجودة)."""
    _magic, cpu, _sub, _ft, ncmds, _scs, _fl, _res = struct.unpack_from(
        "<IIIIIIII", data, off
    )
    arch = CPUS.get(cpu, hex(cpu))
    pos, dyld_info, ext = off + 32, False, set()
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", data, pos)
        if cmd in (LC_DYLD_INFO_ONLY, LC_DYLD_EXPORTS_TRIE, LC_DYLD_CHAINED_FIXUPS):
            dyld_info = True
        elif cmd == LC_SYMTAB:
            symoff, nsyms, stroff, strsize = struct.unpack_from("<IIII", data, pos + 8)
            strs = data[off + stroff : off + stroff + strsize]
            for i in range(nsyms):
                strx, ntype, _sect, _desc = struct.unpack_from(
                    "<IBBH", data, off + symoff + i * 16
                )
                end = strs.find(b"\0", strx)
                name = strs[strx:end].decode("utf-8", "replace")
                if name in NEEDED and ntype & N_EXT:
                    ext.add(name)
        pos += size
    return arch, dyld_info, ext


def slices(path):
    with open(path, "rb") as fh:
        data = fh.read()
    magic_be = struct.unpack_from(">I", data, 0)[0]
    offsets = []
    if magic_be in (FAT, FAT64):
        count = struct.unpack_from(">I", data, 4)[0]
        for i in range(count):
            if magic_be == FAT:
                _c, _s, off, _sz, _a = struct.unpack_from(">IIIII", data, 8 + i * 20)
            else:
                _c, _s, off, _sz, _a, _r = struct.unpack_from(">IIQQII", data, 8 + i * 32)
            offsets.append(off)
    elif struct.unpack_from("<I", data, 0)[0] == MACHO64:
        offsets = [0]
    else:
        return None
    return [_slice_report(data, off) for off in offsets]


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    app = sys.argv[1]
    binary = os.path.join(app, "Contents/Frameworks/App.framework/Versions/A/App")
    if not os.path.isfile(binary):
        print(f"::error::App.framework binary missing at {binary}")
        return 1

    reports = slices(binary)
    if not reports:
        print(f"::error::{binary} is not a Mach-O file")
        return 1

    bad = False
    for arch, dyld_info, ext in reports:
        missing = [s for s in NEEDED if s not in ext]
        print(f"  {arch:<7} dyld-exports={'yes' if dyld_info else 'NO'} "
              f"snapshot-symbols={len(ext)}/{len(NEEDED)}")
        if not dyld_info:
            print(f"::error::App.framework [{arch}] has no dyld export table — "
                  "the engine cannot find the Dart snapshot (Flutter ≥ 3.44.0 "
                  "writes the dylib with gen_snapshot instead of linking it)")
            bad = True
        if missing:
            print(f"::error::App.framework [{arch}] missing external symbols: "
                  + ", ".join(missing))
            bad = True

    archs = {arch for arch, _d, _e in reports}
    if "x86_64" not in archs:
        print(f"::error::App.framework has no x86_64 slice (found {sorted(archs)})")
        bad = True

    if bad:
        return 1
    print("✅ Dart snapshot is reachable by dyld in every slice")
    return 0


if __name__ == "__main__":
    sys.exit(main())
