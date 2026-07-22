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

ويفحص اختيارًا **سقفَ حزمة التطوير** (SDK) لما نبنيه نحن: نشحن لأجهزةٍ على
macOS 11–12، وأقدمُ مشغّلٍ في CI هو macOS 15 ⇒ البناءُ بأحدثِ حزمةِ تطويرٍ يفتح
بابَ سلوكٍ لا يكشفه أيُّ اختبارٍ عندنا. السقفُ يُمرَّر رقمًا صريحًا من المشغّل.

الاستعمال:
    python3 tool/verify_min_macos.py <Belote.app> <أقصى نسخةٍ مسموحة> [سقفُ SDK]
مثال:
    python3 tool/verify_min_macos.py build/.../Belote.app 11.0 16.0
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
    """يردّ [(معماريّة, أدنى نسخة, حزمةُ التطوير)] لشريحة — منصّةَ macOS وحدَها."""
    _magic, cpu, _sub, _ft, ncmds, _scs, _fl, _res = struct.unpack_from(
        "<IIIIIIII", data, off
    )
    arch = CPUS.get(cpu, hex(cpu))
    pos, found = off + 32, []
    for _ in range(ncmds):
        cmd, size = struct.unpack_from("<II", data, pos)
        if cmd == LC_BUILD_VERSION:
            platform, minos, sdk, _n = struct.unpack_from("<IIII", data, pos + 8)
            if platform == PLATFORM_MACOS:
                found.append((arch, _ver(minos), _ver(sdk)))
        elif cmd == LC_VERSION_MIN_MACOSX:
            minos, sdk = struct.unpack_from("<II", data, pos + 8)
            found.append((arch, _ver(minos), _ver(sdk)))
        pos += size
    return found


def mach_o_minos(path):
    """يردّ [(معماريّة, أدنى نسخة, حزمةُ التطوير)] للملفّ، أو [] إن لم يكن Mach-O."""
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
    if len(sys.argv) not in (3, 4):
        print(__doc__)
        return 2
    app, limit_s = sys.argv[1], sys.argv[2]
    max_sdk_s = sys.argv[3] if len(sys.argv) == 4 else None
    limit = tuple(int(x) for x in limit_s.split("."))
    while len(limit) < 3:
        limit += (0,)
    max_sdk = None
    if max_sdk_s:
        max_sdk = tuple(int(x) for x in max_sdk_s.split("."))
        while len(max_sdk) < 3:
            max_sdk += (0,)

    rows, offenders, sdk_offenders = [], [], []
    for dirpath, _dirs, files in os.walk(app):
        for name in files:
            path = os.path.join(dirpath, name)
            if os.path.islink(path):
                continue
            try:
                for arch, minos, sdk in mach_o_minos(path):
                    rel = os.path.relpath(path, app)
                    rows.append((minos, sdk, arch, rel))
                    if minos > limit:
                        offenders.append((minos, arch, rel))
                    # حزمةُ التطوير تُفحَص على ما **نبنيه نحن** وحدَه: الأطرُ
                    # الجاهزةُ (WebRTC مثلًا) تأتي مبنيّةً بحزمةِ صاحبها.
                    if max_sdk and sdk > max_sdk and rel.startswith("Contents/MacOS/"):
                        sdk_offenders.append((sdk, arch, rel))
            except (OSError, struct.error):
                continue

    if not rows:
        print(f"::error::No Mach-O binaries found under {app}")
        return 1

    for minos, sdk, arch, rel in sorted(rows):
        print(f"  min {_fmt(minos):<9} sdk {_fmt(sdk):<9} {arch:<7} {rel}")

    if offenders:
        print()
        for minos, arch, rel in sorted(offenders):
            print(
                f"::error::{rel} ({arch}) requires macOS {_fmt(minos)} "
                f"> {limit_s} — Macs on older systems will crash at launch"
            )
        return 1

    if sdk_offenders:
        print()
        for sdk, arch, rel in sorted(sdk_offenders):
            print(
                f"::error::{rel} ({arch}) was linked against the macOS "
                f"{_fmt(sdk)} SDK > {max_sdk_s} — pick an older Xcode: we ship "
                f"to macOS 11–12 and no CI runner is that old to catch it"
            )
        return 1

    tail = f" (linked SDK ≤ {max_sdk_s})" if max_sdk_s else ""
    print(f"\n✅ every binary runs on macOS {limit_s} or newer{tail}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
