"""Fetch CC0 source data and derive a clothed, articulated anatomy mesh.
No MakeHuman program code is imported. Standard library only.
"""
import concurrent.futures
import hashlib
import json
import math
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADERS = {"User-Agent": "AshenOathDev/0.3 local game asset preparation"}
MATERIALS = {"ground": "forest_ground_04", "stone": "rock_boulder_dry", "leather": "brown_leather", "cloth": "denim_fabric", "bark": "bark_brown_02", "metal": "rusty_metal_02"}
FOLIAGE = ("pine_sapling_small", "fern_02", "grass_medium_01")


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=60).read()


def download_material(pair):
    name, source = pair
    meta = json.loads(get("https://api.polyhaven.com/files/" + source))
    folder = ROOT / "assets" / "materials" / name
    folder.mkdir(parents=True, exist_ok=True)
    manifest = []
    for kind, key in (("color", "Diffuse"), ("normal", "nor_gl"), ("roughness", "Rough")):
        fmt = "png" if kind == "normal" else "jpg"
        info = meta[key]["1k"][fmt]
        file = folder / (kind + "." + fmt)
        raw = file.read_bytes() if file.exists() else get(info["url"])
        if hashlib.md5(raw).hexdigest() != info["md5"]:
            raise RuntimeError("Source checksum mismatch: " + str(file))
        file.write_bytes(raw)
        manifest.append({"file": file.relative_to(ROOT).as_posix(), "url": info["url"], "md5": info["md5"], "sha256": hashlib.sha256(raw).hexdigest(), "asset": "https://polyhaven.com/a/" + source, "license": "CC0-1.0"})
    print("PBR", name, "verified")
    return manifest


def derive_body(raw):
    vertices, texcoords, groups = [], [], {}
    group = ""
    for line in raw.decode().splitlines():
        bits = line.split()
        if not bits:
            continue
        if bits[0] == "v": vertices.append(tuple(map(float, bits[1:4])))
        elif bits[0] == "vt": texcoords.append(tuple(map(float, bits[1:3])))
        elif bits[0] == "g": group = bits[1]; groups.setdefault(group, [])
        elif bits[0] == "f": groups[group].append([(int(p.split('/')[0]) - 1, int(p.split('/')[1]) - 1) for p in bits[1:]])
    def joint(name):
        indices = set(i for face in groups[name] for i, _ in face)
        return tuple(sum(vertices[i][k] for i in indices) / len(indices) for k in range(3))
    parts = {key: [] for key in ("head", "torso", "legs", "boots", "arm_left", "arm_right")}
    for face in groups["body"]:
        x, y, z = [sum(vertices[i][k] for i, _ in face) / len(face) for k in range(3)]
        if abs(x) > 1.45 and y > 2.0:
            # Fingers are replaced by a closed leather glove gripping the pole.
            if abs(x) > 3.85 or (z > 1.25 and y < 2.85 and abs(x) > 3.4): continue
            part = "arm_right" if x > 0 else "arm_left"
        elif y > 5.70: part = "head"
        elif y < -5.55: part = "boots"
        elif y < 0.95: part = "legs"
        else: part = "torso"
        parts[part].append(face)
    folder = ROOT / "assets" / "models" / "iara"
    folder.mkdir(parents=True, exist_ok=True)
    for name, faces in parts.items():
        coords = {}
        uv_indices = {}
        for face in faces:
            for i, uv in face:
                if i not in coords:
                    x, y, z = vertices[i]
                    if name.startswith("arm_"):
                        side = 1 if name == "arm_right" else -1
                        pivot = joint("joint-l-shoulder" if side > 0 else "joint-r-shoulder")
                        x, y, z = (x - pivot[0]) * .115, (y - pivot[1]) * .115, (z - pivot[2]) * .115
                        angle = -side * math.radians(35)
                        x, y = x * math.cos(angle) - y * math.sin(angle), x * math.sin(angle) + y * math.cos(angle)
                        x *= 1.06; z *= 1.06
                    else:
                        x, y, z = x * .115, (y + 8.183) * .115, z * .115
                        if name in ("head", "torso"): y -= .96
                        if name != "head":
                            # Closed cloth/leather shell, with restrained cloth folds.
                            x *= 1.055; z *= 1.06
                            if name in ("torso", "legs"):
                                x += math.sin(y * 44 + z * 13) * .0025
                                z += math.sin(y * 34 + x * 19) * .003
                    coords[i] = (x, y, z)
                uv_indices.setdefault(uv, len(uv_indices) + 1)
        vmap = {old: index + 1 for index, old in enumerate(coords)}
        out = ["# Clothed derivative of MakeHuman hm08 CC0 anatomy. Ashen Oath.", "o " + name]
        out += ["v %.6f %.6f %.6f" % p for p in coords.values()]
        out += ["vt %.6f %.6f" % texcoords[uv] for uv in uv_indices]
        out += ["s 1"]
        out += ["f " + " ".join(f"{vmap[i]}/{uv_indices[uv]}" for i, uv in face) for face in faces]
        (folder / (name + ".obj")).write_text("\n".join(out) + "\n", encoding="utf-8")
        print("MESH", name, "vertices", len(coords), "faces", len(faces))


def download_foliage(source):
    meta = json.loads(get("https://api.polyhaven.com/files/" + source))["gltf"]["1k"]["gltf"]
    folder = ROOT / "assets" / "models" / "foliage" / source
    records = []
    for relative, info in {"model.gltf": meta, **meta["include"]}.items():
        file = folder / relative
        file.parent.mkdir(parents=True, exist_ok=True)
        raw = file.read_bytes() if file.exists() else get(info["url"])
        if hashlib.md5(raw).hexdigest() != info["md5"]:
            raise RuntimeError("Model checksum mismatch: " + str(file))
        file.write_bytes(raw)
        records.append({"file": file.relative_to(ROOT).as_posix(), "url": info["url"], "md5": info["md5"], "sha256": hashlib.sha256(raw).hexdigest(), "asset": "https://polyhaven.com/a/" + source, "license": "CC0-1.0"})
    print("FOLIAGE", source, "verified")
    return records


if __name__ == "__main__":
    provenance = ROOT / "assets" / "provenance"
    provenance.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        records = [record for result in pool.map(download_material, MATERIALS.items()) for record in result]
        records += [record for result in pool.map(download_foliage, FOLIAGE) for record in result]
    commit = "3c701a8e52f09e69922e8b598d23be2d7dfc49e3"  # Pinned CC0 asset; see provenance manifest.
    base = "https://raw.githubusercontent.com/makehumancommunity/makehuman/" + commit
    url = base + "/makehuman/data/3dobjs/base.obj"
    raw = get(url)
    derive_body(raw)
    (provenance / "MakeHuman-CC0.txt").write_bytes(get(base + "/LICENSE.ASSETS.md"))
    records.append({"derived": "assets/models/iara/*.obj", "url": url, "sha256": hashlib.sha256(raw).hexdigest(), "commit": commit, "license": "CC0-1.0", "changes": "split anatomy, posed arms, clothed shell, fingers replaced; helpers discarded"})
    (provenance / "realistic-assets.json").write_text(json.dumps({"prepared": "2026-10-08", "sources": records}, indent=2) + "\n", encoding="utf-8")
