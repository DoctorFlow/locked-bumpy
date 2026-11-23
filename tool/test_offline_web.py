"""Tests the offline packaging step without running a Flutter build."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class PackageTest(unittest.TestCase):
    def test_repeated_packaging_keeps_one_registration_and_changes_with_assets(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ["index.html", "flutter_bootstrap.js", "main.dart.js",
                         "canvaskit/canvaskit.wasm", "assets/assets/images/body-witch.png"]:
                file = root / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_bytes(name.encode())
            (root / "manifest.json").write_text(json.dumps({"name": "Little Bumpy"}))
            (root / "index.html").write_text("<html><head></head><body></body></html>")
            def package():
                subprocess.run([sys.executable, str(Path(__file__).with_name("prepare_offline_web.py")),
                                "--output", str(root)], check=True, capture_output=True)
                return (root / "bumpy-offline.js").read_bytes()
            first = package()
            self.assertEqual(first, package())
            self.assertEqual((root / "flutter_bootstrap.js").read_text().count('bumpy-offline.js'), 1)
            self.assertEqual((root / "index.html").read_text().count("Content-Security-Policy"), 1)
            self.assertIn(b'assets/assets/images/body-witch.png', first)
            (root / "assets/assets/images/body-witch.png").write_bytes(b"new cut")
            self.assertNotEqual(first, package())


if __name__ == "__main__":
    unittest.main()
