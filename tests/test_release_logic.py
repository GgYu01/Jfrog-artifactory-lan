import unittest
from pathlib import Path
import importlib.util


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "lib" / "releases.py"
SPEC = importlib.util.spec_from_file_location("releases", MODULE_PATH)
RELEASES = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(RELEASES)


class ReleaseLogicTests(unittest.TestCase):
    def test_parse_versions_sorts_numerically(self):
        html = """
        <a href="7.133.18/">7.133.18/</a>
        <a href="7.146.7/">7.146.7/</a>
        <a href="7.111.12/">7.111.12/</a>
        """
        self.assertEqual(
            RELEASES.parse_versions(html),
            ["7.111.12", "7.133.18", "7.146.7"],
        )

    def test_latest_version_returns_highest_entry(self):
        html = """
        <a href="7.125.12/">7.125.12/</a>
        <a href="7.146.7/">7.146.7/</a>
        """
        self.assertEqual(RELEASES.latest_version(html), "7.146.7")


if __name__ == "__main__":
    unittest.main()

