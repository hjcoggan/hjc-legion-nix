"""Add non-Steam shortcuts to every local Steam user's shortcuts.vdf.

Run before Steam starts (see update.nix). Gaming Mode has no "Add a Non-Steam Game" button,
so this is how apps such as "Update System" show up in the Steam library.

Usage: steam-shortcuts.py shortcuts.json
Entries already present (matched by name) are left alone. Files that can't be parsed are
never touched.
"""
import glob
import json
import os
import sys
import zlib

import vdf


def main():
    with open(sys.argv[1]) as f:
        shortcuts = json.load(f)

    root = os.path.expanduser("~/.local/share/Steam/userdata")
    for cfg in glob.glob(os.path.join(root, "*", "config")):
        path = os.path.join(cfg, "shortcuts.vdf")
        data = {"shortcuts": {}}
        if os.path.exists(path) and os.path.getsize(path) > 0:
            try:
                with open(path, "rb") as f:
                    data = vdf.binary_load(f)
            except Exception as err:
                print("skipping unreadable", path, err)
                continue

        entries = data.setdefault("shortcuts", {})
        have = {e.get("AppName", e.get("appname")) for e in entries.values()}
        n = len(entries)
        changed = False
        for s in shortcuts:
            if s["name"] in have:
                continue
            exe = '"%s"' % s["exe"]
            appid = zlib.crc32((exe + s["name"]).encode()) | 0x80000000
            if appid >= 2**31:  # Steam stores the id as a signed 32-bit integer
                appid -= 2**32
            entries[str(n)] = {
                "appid": appid,
                "AppName": s["name"],
                "Exe": exe,
                "StartDir": '"/run/current-system/sw/bin/"',
                "icon": "",
                "ShortcutPath": "",
                "LaunchOptions": "",
                "IsHidden": 0,
                "AllowDesktopConfig": 1,
                "AllowOverlay": 1,
                "OpenVR": 0,
                "Devkit": 0,
                "DevkitGameID": "",
                "DevkitOverrideAppID": 0,
                "LastPlayTime": 0,
                "FlatpakAppID": "",
                "tags": {},
            }
            n += 1
            changed = True

        if changed:
            tmp = path + ".tmp"
            with open(tmp, "wb") as f:
                vdf.binary_dump(data, f)
            os.replace(tmp, path)
            print("added shortcuts to", path)


if __name__ == "__main__":
    main()
