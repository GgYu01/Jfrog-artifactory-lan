import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class ScriptBehaviorTests(unittest.TestCase):
    def copy_repo_files(self, destination_root: Path, relative_paths: list[str]) -> None:
        for relative_path in relative_paths:
            source_path = REPO_ROOT / relative_path
            target_path = destination_root / relative_path
            target_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, target_path)

    def test_prepare_host_renders_special_characters_in_admin_password(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            self.copy_repo_files(
                repo_root,
                [
                    "scripts/prepare-host.sh",
                    "scripts/lib/common.sh",
                    "config/artifactory/templates/bootstrap.creds.template",
                    "config/artifactory/var/etc/security/master.key",
                    "config/artifactory/var/etc/security/join.key",
                ],
            )

            password = "abc&123/xyz"
            env_text = "\n".join(
                [
                    "ARTIFACTORY_ADMIN_USER=admin",
                    f"ARTIFACTORY_ADMIN_PASSWORD={password}",
                    "PORTAL_PORT=8080",
                    "ARTIFACTORY_ADMIN_BIND_HOST=127.0.0.1",
                    "ARTIFACTORY_ADMIN_PORT=8082",
                ]
            ) + "\n"
            (repo_root / ".env").write_text(env_text, encoding="utf-8")
            (repo_root / ".env.example").write_text(env_text, encoding="utf-8")

            result = subprocess.run(
                ["bash", "scripts/prepare-host.sh"],
                cwd=repo_root,
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr or result.stdout)

            rendered = (
                repo_root / "data" / "artifactory" / "var" / "etc" / "access" / "bootstrap.creds"
            ).read_text(encoding="utf-8").strip()
            self.assertEqual(rendered, f"admin@*={password}")

    def test_status_survives_compose_ps_failure(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repo_root = Path(temp_dir)
            self.copy_repo_files(
                repo_root,
                [
                    "scripts/status.sh",
                    "scripts/lib/common.sh",
                ],
            )

            env_text = "\n".join(
                [
                    "PORTAL_PORT=8080",
                    "ARTIFACTORY_ADMIN_BIND_HOST=127.0.0.1",
                    "ARTIFACTORY_ADMIN_PORT=8082",
                ]
            ) + "\n"
            (repo_root / ".env").write_text(env_text, encoding="utf-8")
            (repo_root / ".env.example").write_text(env_text, encoding="utf-8")

            backup_dir = repo_root / "data" / "backups"
            backup_dir.mkdir(parents=True, exist_ok=True)
            (backup_dir / "artifactory-backup-20260420-120000.tar.gz").write_text("backup", encoding="utf-8")

            fake_bin = repo_root / "fake-bin"
            fake_bin.mkdir(parents=True, exist_ok=True)
            docker_stub = fake_bin / "docker"
            docker_stub.write_text(
                "\n".join(
                    [
                        "#!/usr/bin/env bash",
                        "set -euo pipefail",
                        'if [[ \"$1\" == \"compose\" && \"$2\" == \"version\" ]]; then',
                        "  exit 0",
                        "fi",
                        'if [[ \"$1\" == \"compose\" && \"$2\" == \"ps\" ]]; then',
                        '  echo \"Cannot connect to the Docker daemon\" >&2',
                        "  exit 1",
                        "fi",
                        "exit 1",
                        "",
                    ]
                ),
                encoding="utf-8",
            )
            docker_stub.chmod(docker_stub.stat().st_mode | stat.S_IXUSR)

            env = os.environ.copy()
            env["PATH"] = f"{fake_bin}:{env['PATH']}"

            result = subprocess.run(
                ["bash", "scripts/status.sh"],
                cwd=repo_root,
                text=True,
                capture_output=True,
                env=env,
            )
            combined_output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, msg=combined_output)
            self.assertIn("Configured portal URL (host-local): http://127.0.0.1:8080", combined_output)
            self.assertIn("Latest backup archive:", combined_output)
            self.assertIn("docker compose ps failed; continuing with static status output.", combined_output)


if __name__ == "__main__":
    unittest.main()
