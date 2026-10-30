"""Run with python3 github/compare/test_host_isolation.py (requires gh, jq, Node, and openssl).

Exercises the package's task scripts with real gh against a local HTTPS API proxy.
The matcher is a passthrough fixture: rwx-test.yml covers real glob matching/outputs.
"""

import http.server
import json
import os
from pathlib import Path
import socketserver
import ssl
import subprocess
import tempfile
import threading
import unittest


PACKAGE = Path(__file__).resolve().parent
SHA = "1" * 40


class HostIsolationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            ["node", "-e", "console.log(JSON.stringify(require('yaml').parse(require('fs').readFileSync('rwx-package.yml', 'utf8'))))"],
            cwd=PACKAGE, check=True, capture_output=True, text=True,
        )
        cls.tasks = {task["key"]: task for task in json.loads(result.stdout)["tasks"]}

    def test_host_and_token_are_isolated_for_ref_and_compare_requests(self):
        cases = [
            ("owner/repo", "github.com", "api.github.com", ""),
            ("https://github.com/owner/repo.git", "github.com", "api.github.com", ""),
            ("ssh://git@github.com:22/owner/repo.git", "github.com", "api.github.com", ""),
            ("git@github.com:owner/repo.git", "github.com", "api.github.com", ""),
            ("https://GITHUB.EXAMPLE.COM/owner/repo.git/", "github.example.com", "github.example.com", "/api/v3"),
            ("https://github.example.com:443/owner/repo.git", "github.example.com", "github.example.com", "/api/v3"),
            ("ssh://git@github.example.com:2222/owner/repo.git", "github.example.com", "github.example.com", "/api/v3"),
            ("git@github.example.com:owner/repo.git", "github.example.com", "github.example.com", "/api/v3"),
            ("https://tenant.ghe.com/owner/repo", "tenant.ghe.com", "api.tenant.ghe.com", ""),
        ]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cert, key = root / "cert.pem", root / "key.pem"
            subprocess.run([
                "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
                "-keyout", str(key), "-out", str(cert), "-days", "1", "-subj", "/CN=localhost",
                "-addext", "subjectAltName=DNS:api.github.com,DNS:github.example.com,DNS:api.tenant.ghe.com",
            ], check=True, capture_output=True)
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(cert, key)
            requests = []

            class API(http.server.BaseHTTPRequestHandler):
                def do_GET(self):
                    requests.append((self.headers["Host"], self.path, self.headers.get("Authorization")))
                    body = json.dumps({"object": {"sha": SHA}, "files": [{"filename": "src/main.go"}]}).encode()
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_header("Content-Length", str(len(body)))
                    self.end_headers()
                    self.wfile.write(body)

                def log_message(self, *args):
                    pass

            class Proxy(socketserver.StreamRequestHandler):
                def handle(self):
                    request = self.rfile.readline().decode().split()
                    if len(request) != 3 or request[0] != "CONNECT":
                        return
                    while self.rfile.readline() != b"\r\n":
                        pass
                    self.wfile.write(b"HTTP/1.1 200 Connection established\r\n\r\n")
                    self.wfile.flush()
                    with context.wrap_socket(self.connection, server_side=True) as connection:
                        API(connection, self.client_address, self.server)

            with socketserver.ThreadingTCPServer(("127.0.0.1", 0), Proxy) as server:
                thread = threading.Thread(target=server.serve_forever, daemon=True)
                thread.start()
                try:
                    for index, (repository, hostname, api_host, prefix) in enumerate(cases):
                        with self.subTest(repository=repository):
                            work = root / str(index)
                            work.mkdir()
                            values = work / "values"
                            values.mkdir()
                            package = work / "package"
                            (package / "bin").mkdir(parents=True)
                            (package / "gh-env.sh").symlink_to(PACKAGE / "gh-env.sh")
                            arch = {"x86_64": "amd64", "aarch64": "arm64"}[os.uname().machine]
                            matcher = package / "bin" / f"glob_patterns-{arch}"
                            matcher.write_text("#!/usr/bin/env bash\ncat\n")
                            matcher.chmod(0o755)
                            env = dict(os.environ, GH_HOST="wrong.example.com", GH_TOKEN="wrong-public",
                                       GITHUB_TOKEN="wrong-fallback", GH_ENTERPRISE_TOKEN="wrong-enterprise",
                                       GITHUB_ENTERPRISE_TOKEN="wrong-enterprise-fallback",
                                       GH_CONFIG_DIR=str(work / "gh"), GH_NO_UPDATE_NOTIFIER="1",
                                       GH_TELEMETRY="0", SSL_CERT_FILE=str(cert), NO_PROXY="", no_proxy="",
                                       HTTPS_PROXY=f"http://127.0.0.1:{server.server_address[1]}",
                                       https_proxy=f"http://127.0.0.1:{server.server_address[1]}",
                                       RWX_VALUES=str(values), RWX_PACKAGE_PATH=str(package))
                            params = {"repository": repository, "github-token": "package-token",
                                      "base-ref": "main", "head-ref": "refs/heads/main", "patterns": "**/*"}
                            outputs = {}
                            requests.clear()
                            for task_key in ("repository", "shas", "compare"):
                                task = self.tasks[task_key]
                                task_env = env.copy()
                                for name, value in task["env"].items():
                                    expression = value["value"] if isinstance(value, dict) else value
                                    reference = expression.removeprefix("${{ ").removesuffix(" }}")
                                    if reference.startswith("params."):
                                        task_env[name] = params[reference.removeprefix("params.")]
                                    else:
                                        _, dependency, _, output = reference.split(".")
                                        task_env[name] = outputs[dependency][output]
                                result = subprocess.run(["bash", "-ueo", "pipefail", "-c", task["run"]],
                                                        cwd=work, env=task_env, capture_output=True, text=True, timeout=15)
                                self.assertEqual(result.returncode, 0, result.stderr)
                                outputs[task_key] = {path.name: path.read_text().rstrip("\n") for path in values.iterdir()}
                            self.assertEqual(outputs["repository"], {"hostname": hostname, "repository": "owner/repo"})
                            self.assertEqual(outputs["shas"]["base-sha"], SHA)
                            self.assertEqual(outputs["shas"]["head-sha"], SHA)
                            self.assertEqual(requests, [
                                (api_host, prefix + "/repos/owner/repo/git/ref/heads/main", "token package-token"),
                                (api_host, prefix + "/repos/owner/repo/git/ref/heads/main", "token package-token"),
                                (api_host, prefix + f"/repos/owner/repo/compare/{SHA}...{SHA}", "token package-token"),
                            ])
                finally:
                    server.shutdown()
                    thread.join()

    def test_rejects_custom_https_ports_before_any_api_request(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                ["bash", "-ueo", "pipefail", "-c", self.tasks["repository"]["run"]],
                env=dict(os.environ, REPOSITORY="https://github.example.com:8443/owner/repo.git", RWX_VALUES=directory),
                capture_output=True, text=True, timeout=15,
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("standard HTTPS port (443)", result.stderr)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
