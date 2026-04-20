import unittest
from pathlib import Path
import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]


class RepoLayoutTests(unittest.TestCase):
    def test_env_example_contains_required_keys(self):
        env_text = (REPO_ROOT / ".env.example").read_text(encoding="utf-8")
        for key in [
            "ARTIFACTORY_VERSION=",
            "ARTIFACTORY_ADMIN_PASSWORD=",
            "PORTAL_USERNAME=",
            "PORTAL_PASSWORD=",
            "CONTENT_REPOSITORY_KEY=",
        ]:
            self.assertIn(key, env_text)
        self.assertIn("ARTIFACTORY_ADMIN_BIND_HOST=0.0.0.0", env_text)
        self.assertIn("ARTIFACTORY_ADMIN_PASSWORD=CHANGE_ME_BEFORE_STARTING", env_text)

    def test_bootstrap_creds_matches_required_admin_default(self):
        creds = (
            REPO_ROOT
            / "config"
            / "artifactory"
            / "templates"
            / "bootstrap.creds.template"
        ).read_text(encoding="utf-8").strip()
        self.assertEqual(creds, "__ARTIFACTORY_ADMIN_USER__@*=__ARTIFACTORY_ADMIN_PASSWORD__")

    def test_compose_has_expected_services(self):
        payload = yaml.safe_load((REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8"))
        self.assertEqual(sorted(payload["services"].keys()), ["artifactory", "portal", "postgres"])
        artifactory_volumes = payload["services"]["artifactory"]["volumes"]
        self.assertIn("./data/artifactory/var:/var/opt/jfrog/artifactory", artifactory_volumes)
        self.assertIn(
            "${ARTIFACTORY_ADMIN_BIND_HOST}:${ARTIFACTORY_ADMIN_PORT}:${ARTIFACTORY_ADMIN_PORT}",
            payload["services"]["artifactory"]["ports"],
        )

    def test_prepare_host_bootstrap_security_path_is_copied(self):
        script_text = (REPO_ROOT / "scripts" / "prepare-host.sh").read_text(encoding="utf-8")
        self.assertIn("var/bootstrap/access/etc/security/master.key", script_text)
        self.assertIn("var/bootstrap/access/etc/security/join.key", script_text)

    def test_admin_scripts_do_not_hardcode_localhost_for_bind_host(self):
        for relative_path in [
            "scripts/wait-artifactory.sh",
            "scripts/bootstrap-artifactory.sh",
        ]:
            script_text = (REPO_ROOT / relative_path).read_text(encoding="utf-8")
            self.assertNotIn("http://localhost:${ARTIFACTORY_ADMIN_PORT}", script_text)
            self.assertIn("admin_probe_base_url", script_text)

    def test_harness_standards_shelf_exists(self):
        for relative_path in [
            "docs/harness_sources/README.md",
            "docs/harness_sources/2026-04-20-openai-anthropic-meta-harness.md",
            "docs/harness_standards/local_normative_baseline.md",
            "docs/harness_standards/project_mapping.md",
            "docs/harness_standards/refresh_runbook.md",
            "scripts/refresh_harness_sources.sh",
        ]:
            self.assertTrue((REPO_ROOT / relative_path).exists(), relative_path)


if __name__ == "__main__":
    unittest.main()
