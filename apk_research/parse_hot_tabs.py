import struct
import json
import sys

sys.stdout.reconfigure(encoding="utf-8")


def read_varint(data, pos):
    result = 0
    shift = 0
    while True:
        b = data[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, pos
        shift += 7


def parse_fields(data):
    fields = []
    pos = 0
    while pos < len(data):
        key, pos = read_varint(data, pos)
        fnum = key >> 3
        wire = key & 7
        if wire == 0:
            val, pos = read_varint(data, pos)
            fields.append((fnum, wire, val))
        elif wire == 2:
            ln, pos = read_varint(data, pos)
            val = data[pos:pos + ln]
            pos += ln
            fields.append((fnum, wire, val))
        else:
            break
    return fields


def get_field(fields, fnum):
    for f in fields:
        if f[0] == fnum:
            return f[2]
    return None


def get_fields(fields, fnum):
    return [f[2] for f in fields if f[0] == fnum]


def parse_entrance(data):
    fs = parse_fields(data)
    return {
        "icon": (get_field(fs, 1) or b"").decode("utf-8", "replace"),
        "title": (get_field(fs, 2) or b"").decode("utf-8", "replace"),
        "module_id": (get_field(fs, 3) or b"").decode("utf-8", "replace"),
        "uri": (get_field(fs, 4) or b"").decode("utf-8", "replace"),
        "entrance_id": get_field(fs, 6) or 0,
        "top_photo": (get_field(fs, 7) or b"").decode("utf-8", "replace"),
        "entrance_type": get_field(fs, 8) or 0,
    }


def parse_config(data):
    fs = parse_fields(data)
    out = {
        "item_title": (get_field(fs, 1) or b"").decode("utf-8", "replace"),
        "bottom_text": (get_field(fs, 2) or b"").decode("utf-8", "replace"),
        "head_image": (get_field(fs, 6) or b"").decode("utf-8", "replace"),
        "hit": get_field(fs, 8) or 0,
        "toast": (get_field(fs, 9) or b"").decode("utf-8", "replace"),
        "top_items": [],
        "page_items": [],
    }
    for raw in get_fields(fs, 5):
        out["top_items"].append(parse_entrance(raw))
    for raw in get_fields(fs, 7):
        out["page_items"].append(parse_entrance(raw))
    return out


data = open(r"C:\Users\memz2345\AppData\Local\Temp\opencode\testapk\hot_resp.bin", "rb").read()
frame_len = struct.unpack(">I", data[1:5])[0]
payload = data[5:5 + frame_len]
fs = parse_fields(payload)
cfg = parse_config(get_field(fs, 2))

lines = []
lines.append("ver=%s items=%d" % ((get_field(fs, 3) or b"").decode("utf-8", "replace"), len(get_fields(fs, 1))))
lines.append("item_title=%s" % cfg["item_title"])
lines.append("head_image=%s" % cfg["head_image"])
lines.append("toast=%s" % cfg["toast"])
lines.append("bottom_text=%s" % cfg["bottom_text"])
lines.append("")
lines.append("== top_items (field5) count=%d ==" % len(cfg["top_items"]))
for i, it in enumerate(cfg["top_items"]):
    lines.append("[%02d] %-8s id=%-4s icon=%s" % (i, it["title"], it["entrance_id"], it["icon"]))
    lines.append("     uri=%s" % it["uri"])
    if it["top_photo"]:
        lines.append("     top_photo=%s" % it["top_photo"])
lines.append("")
lines.append("== page_items (field7) count=%d ==" % len(cfg["page_items"]))
for i, it in enumerate(cfg["page_items"]):
    lines.append("[%02d] %-8s id=%-4s type=%d icon=%s" % (i, it["title"], it["entrance_id"], it["entrance_type"], it["icon"]))
    lines.append("     uri=%s" % it["uri"])
    if it["top_photo"]:
        lines.append("     top_photo=%s" % it["top_photo"])

out = "\n".join(lines)
open(r"C:\Users\memz2345\AppData\Local\Temp\opencode\testapk\hot_tabs.txt", "w", encoding="utf-8").write(out)
print(out)