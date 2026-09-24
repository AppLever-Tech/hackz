from pathlib import Path

IMPORT = "import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';"
OLD = "Center(child: CircularProgressIndicator())"
NEW = "Center(child: HkzProgressIndicator())"

for path in Path("lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    if OLD not in text:
        continue
    text = text.replace(OLD, NEW)
    if "hkz_progress_indicator.dart" not in text:
        needle = "import 'package:flutter/material.dart';"
        if needle in text:
            text = text.replace(needle, f"{needle}\n{IMPORT}", 1)
        else:
            text = f"{IMPORT}\n{text}"
    path.write_text(text, encoding="utf-8")
    print(f"updated {path}")
