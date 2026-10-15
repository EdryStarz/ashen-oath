"""Install a checksum-verified, portable FFmpeg for universal-modder capture."""
import concurrent.futures
import hashlib
import json
import time
import urllib.request
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
api = "https://api.github.com/repos/BtbN/FFmpeg-Builds/releases/latest"
request = urllib.request.Request(api, headers={"User-Agent": "AshenOath-local-build"})
release = json.load(urllib.request.urlopen(request, timeout=30))
asset = next(a for a in release["assets"] if a["name"] == "ffmpeg-master-latest-win64-lgpl-shared.zip")
expected = asset["digest"].removeprefix("sha256:")
target = root / ".tools" / "downloads" / asset["name"]
target.parent.mkdir(parents=True, exist_ok=True)
total = asset["size"]


def read_range(start):
    end = min(start + (1 << 20), total) - 1
    for attempt in range(4):
        try:
            request = urllib.request.Request(asset["browser_download_url"], headers={"Range": f"bytes={start}-{end}"})
            with urllib.request.urlopen(request, timeout=30) as response:
                data = response.read()
            if len(data) != end - start + 1:
                raise RuntimeError("Incomplete byte range")
            return start, data
        except Exception:
            if attempt == 3:
                raise
            time.sleep(attempt + 1)


with target.open("wb") as file, concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    file.truncate(total)
    tasks = [pool.submit(read_range, start) for start in range(0, total, 1 << 20)]
    received = 0
    for task in concurrent.futures.as_completed(tasks):
        start, data = task.result()
        file.seek(start)
        file.write(data)
        received += len(data)
        if received % (16 << 20) == 0:
            print(f"FFmpeg {received >> 20}/{total >> 20} MiB", flush=True)
with target.open("rb") as file:
    if hashlib.file_digest(file, "sha256").hexdigest() != expected:
        raise RuntimeError("FFmpeg SHA-256 mismatch")
destination = root / ".tools" / "ffmpeg"
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(target) as archive:
    for info in archive.infolist():
        if "/bin/" in info.filename and not info.is_dir():
            (destination / Path(info.filename).name).write_bytes(archive.read(info))
        elif Path(info.filename).name in ("LICENSE.txt", "LICENSE"):
            (destination / "LICENSE.txt").write_bytes(archive.read(info))
(destination / "source.json").write_text(json.dumps({"release": release["html_url"], "asset": asset["browser_download_url"], "sha256": expected}, indent=2))
print(f"Verified FFmpeg installed: {destination}", flush=True)
