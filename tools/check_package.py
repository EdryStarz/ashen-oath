"""Stage only distributable project files, then run universal-modder's package lint."""
import shutil
import hashlib
import subprocess
import sys
import uuid
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
stage = root / ".tools" / ("package-check-" + uuid.uuid4().hex[:12])
stage.mkdir(parents=True, exist_ok=True)
include_files = ("project.godot", "main.tscn", "export_presets.cfg", "README.md", "MODLOG.md", "THIRD_PARTY_NOTICES.md", ".gitignore")
include_dirs = ("assets", "scripts", "docs", "tests", "tools")
for name in include_files:
    source = root / name
    if source.is_file():
        shutil.copy2(source, stage / name)
for name in include_dirs:
    source = root / name
    if source.is_dir():
        shutil.copytree(source, stage / name, dirs_exist_ok=True, ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "private_maiden"))
python = root / ".tools" / "um-env" / "Scripts" / "python.exe"
result = subprocess.run([str(python), "-m", "um", "publish", "check", str(stage)], capture_output=True, text=True)
print(result.stdout, end="")
print(result.stderr, end="", file=sys.stderr)
(root / "artifacts").mkdir(exist_ok=True)
(root / "artifacts" / "modder-package-check.log").write_text(result.stdout + result.stderr, encoding="utf-8")
if "--archive" in sys.argv and result.returncode == 0 and result.stdout.startswith("PASS:"):
    archive_path = root / "artifacts" / "ashen-oath-source.zip"
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file in sorted(stage.rglob("*")):
            if file.is_file():
                archive.write(file, file.relative_to(stage).as_posix())
    with zipfile.ZipFile(archive_path) as archive:
        broken = archive.testzip()
        if broken:
            raise RuntimeError("Archive CRC failed: " + broken)
    checksum_files = (root / "artifacts" / "ashen-oath-debug.apk", archive_path)
    checksums = [hashlib.sha256(file.read_bytes()).hexdigest() + "  " + file.name for file in checksum_files if file.is_file()]
    (root / "artifacts" / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n", encoding="utf-8")
    print(f"Source archive: {archive_path}")
sys.exit(result.returncode)
