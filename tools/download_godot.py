"""Download official portable Godot and matching templates; verify SHA-512."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import shutil
import time
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.7.2-stable"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}"
CACHE = ROOT / ".tools" / "downloads"
ENGINE = ROOT / ".tools" / "godot"


def fetch(name: str) -> Path:
    CACHE.mkdir(parents=True, exist_ok=True)
    target = CACHE / name
    sums = urllib.request.urlopen(f"{BASE}/SHA512-SUMS.txt", timeout=30).read().decode()
    (CACHE / "SHA512-SUMS.txt").write_text(sums, encoding="utf-8")
    expected = next(line.split()[0] for line in sums.splitlines() if line.endswith(name))
    if target.exists():
        with target.open("rb") as file:
            cached_hash = hashlib.file_digest(file, "sha512").hexdigest()
        if cached_hash == expected:
            print(f"Verified cached {name}", flush=True)
            return target
    # Bounded byte ranges recover cleanly on links that stall large downloads.
    probe = urllib.request.Request(f"{BASE}/{name}", headers={"Range": "bytes=0-0"})
    with urllib.request.urlopen(probe, timeout=30) as source:
        total = int(source.headers["Content-Range"].split("/")[-1])
    chunk_size = 1 << 20

    def read_range(start: int) -> tuple[int, bytes]:
        end = min(start + chunk_size, total) - 1
        for attempt in range(4):
            try:
                request = urllib.request.Request(f"{BASE}/{name}", headers={"Range": f"bytes={start}-{end}"})
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = response.read()
                if len(data) != end - start + 1:
                    raise RuntimeError(f"Incomplete range {start}-{end}")
                return start, data
            except Exception:
                if attempt == 3:
                    raise
                time.sleep(attempt + 1)
        raise AssertionError("unreachable")

    with target.open("wb") as output, concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        output.truncate(total)
        received = 0
        last_progress = 0
        pending = {pool.submit(read_range, start) for start in range(0, total, chunk_size)}
        for task in concurrent.futures.as_completed(pending):
            start, data = task.result()
            pending.remove(task)
            output.seek(start)
            output.write(data)
            received += len(data)
            if received - last_progress >= 16 << 20:
                print(f"{name}: {received >> 20}/{total >> 20} MiB", flush=True)
                last_progress = received
    with target.open("rb") as file:
        actual = hashlib.file_digest(file, "sha512").hexdigest()
    if actual != expected:
        raise RuntimeError(f"SHA-512 mismatch: {name}")
    print(f"SHA-512 verified: {name}", flush=True)
    return target


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("part", choices=["editor", "templates", "all"], default="all", nargs="?")
    args = parser.parse_args()
    ENGINE.mkdir(parents=True, exist_ok=True)
    (ENGINE / "_sc_").touch()
    if args.part in ("editor", "all"):
        with zipfile.ZipFile(fetch(f"Godot_v{VERSION}_win64.exe.zip")) as archive:
            archive.extractall(ENGINE)
    if args.part in ("templates", "all"):
        destination = ENGINE / "editor_data" / "export_templates" / VERSION.replace("-", ".")
        destination.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(fetch(f"Godot_v{VERSION}_export_templates.tpz")) as archive:
            for name in ("android_debug.apk", "android_release.apk", "windows_debug_x86_64.exe", "windows_release_x86_64.exe", "version.txt"):
                with archive.open(f"templates/{name}") as source, (destination / name).open("wb") as output:
                    shutil.copyfileobj(source, output)
                print(f"Installed {name}", flush=True)


if __name__ == "__main__":
    main()

