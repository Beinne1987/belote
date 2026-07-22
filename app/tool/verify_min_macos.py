#!/usr/bin/env python3
"""يفحص أدنى نسخةِ macOS التي تشترطها **كلُّ** ثنائيّةٍ داخل حزمة `.app`.

لماذا: مكتبةٌ واحدةٌ تشترط نسخةً أحدثَ من جهاز اللاعب تُميت التطبيقَ عند
الإقلاع — `dyld` يرفض تحميلَها قبل أن يُرسَم إطار. ولا يظهر ذلك في البناء ولا
في اختبار الإقلاع على مشغّلٍ حديث: مشغّلُ GitHub يعمل macOS 15، ومونتيري (12)
عند المالك يموت. حدث ذلك فعلًا في 2026-07-22 مع `objective_c.framework`
(min 13.0) الذي يبنيه Flutter برقمٍ ثابتٍ في أداته (`targetMacOSVersion = 13`)
متجاهلًا `MACOSX_DEPLOYMENT_TARGET` في المشروع.

يقرأ الملفّات مباشرةً (Mach-O fat وthin) فلا يحتاج أدواتِ Xcode ⇒ يعمل على
لينكس أيضًا لفحص حزمةٍ مفكوكةٍ من DMG.

الاستعمال:
    python3 tool/verify_min_macos.py <Belote.app> <أقصى نسخةٍ مسموحة>
مثال:
    python3 tool/verify_min_macos.py build/.../Belote.app 11.0
"""

import os
import struct
import sys

FAT, FAT64, MACHO64 = 0xCAFEBABE, 0xCAFEBABF, 0xFEEDFACF
LC_VERSION_MIN_MACOSX, LC_BUILD_VERSION = 0x24, 0x32
PLATFORM_MACOS = 1  # ما عداه (Catalyst/iOS) لا يحكم الإقلاعَ على ماك
CPUS = {0x1000007: "x86_64", 0x100000C: "arm64"}


def _ver(v):
    return (v >> 16, (v >> 8) & 0xFF, v & 0xFF)


def _fmt(t):
    return ".".join(str(x) for x in t)


def _slice_minos(data, off):
    """يردّ [(معماريّة, أدنى نسخة)] لشريحةٍ واحدة — منصّةَ macOS وحدَها."""
    _magic, cpu, _sub, _ft, ncmds, _scs, _fl, _res = struct.unpack_from(
        "<IIIIIIII", data, off
    )
    arch = CPUS.get(cpu, hex(cpu))
    pos, found = off + 32, []
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", data, pos)
        if cmd == LC_BUILD_VERSION:
            platform, minos, _sdk, _n = struct.unpack_from("<IIII", data, pos + 8)
            if platform == PLATFORM_MACOS:
                found.append((arch, _ver(minos)))
        elif cmd == LC_VERSION_MIN_MACOSX:
            minos, _sdk = struct.unpack_from("<II", data, pos + 8)
            found.append((arch, _ver(minos)))
        pos += size
    return found


def mach_o_minos(path):
    """يردّ [(معماريّة, أدنى نسخة)] للملفّ، أو [] إن لم يكن Mach-O."""
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 8:
        return []
    magic_be = struct.unpack_from(">I", data, 0)[0]
    offsets = []
    if magic_be in (FAT, FAT64):
        count = struct.unpack_from(">I", data, 4)[0]
        for i in range(count):
            if magic_be == FAT:
                _c, _s, off, _sz, _a = struct.unpack_from(">IIIII", data, 8 + i * 20)
            else:
                _c, _s, off, _sz, _a, _r = struct.unpack_from(
                    ">IIQQII", data, 8 + i * 32
                )
            offsets.append(off)
    elif struct.unpack_from("<I", data, 0)[0] == MACHO64:
        offsets = [0]
    else:
        return []
    out = []
    for off in offsets:
        out.extend(_slice_minos(data, off))
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    app, limit_s = sys.argv[1], sys.argv[2]
    limit = tuple(int(x) for x in limit_s.split("."))
    while len(limit) < 3:
        limit += (0,)

    rows, offenders = [], []
    for dirpath, _dirs, files in os.walk(app):
        for name in files:
            path = os.path.join(dirpath, name)
            if os.path.islink(path):
                continue
            try:
                for arch, minos in mach_o_minos(path):
                    rel = os.path.relpath(path, app)
                    rows.append((minos, arch, rel))
                    if minos > limit:
                        offenders.append((minos, arch, rel))
            except (OSError, struct.error):
                continue

    if not rows:
        print(f"::error::No Mach-O binaries found under {app}")
        return 1

    for minos, arch, rel in sorted(rows):
        print(f"  min {_fmt(minos):<9} {arch:<7} {rel}")

    if offenders:
        print()
        for minos, arch, rel in sorted(offenders):
            print(
                f"::error::{rel} ({arch}) requires macOS {_fmt(minos)} "
                f"> {limit_s} — Macs on older systems will crash at launch"
            )
        return 1

    print(f"\n✅ every binary runs on macOS {limit_s} or newer")
    return 0


if __name__ == "__main__":
    sys.exit(main())
