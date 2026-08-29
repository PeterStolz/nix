{ pkgs, ... }:

let
  # Terminal access to the Detesia credential broker (terraform-infra
  # SECRETS_STRATEGY.md).
  #
  #   detesia login   one-time per machine: OAuth device flow against Authentik
  #   detesia token   print a valid access token (silent refresh)
  #   detesia curl    curl a broker path with bearer + X-Actor preset
  #   detesia whoami  decode the current token's claims
  #
  # Deliberately NOT oidc-agent: its nixpkgs derivation hard-depends on
  # webkitgtk (broken on darwin). This stdlib-python implementation uses the
  # macOS Keychain on Darwin and a mode-0600 state file on headless Linux,
  # caches the short-lived access token under $XDG_STATE_HOME, and needs no
  # agent daemon.
  authScript = pkgs.writeText "detesia-auth.py" ''
    """Device-flow login and silent token refresh for the Detesia broker."""

    import json
    import os
    import pathlib
    import stat
    import subprocess
    import sys
    import tempfile
    import time
    import urllib.error
    import urllib.parse
    import urllib.request

    # Bump on ANY behavior change — login/whoami print it so a stale binary
    # (user forgot home-manager switch) is diagnosable from a pasted transcript.
    VERSION = "6"
    DEVICE_URL = "https://auth.cluster.detesia.com/application/o/device/"
    TOKEN_URL = "https://auth.cluster.detesia.com/application/o/token/"
    CLIENT_ID = "detesia-cli"
    # profile carries the groups claim: per-person broker routes (e.g. /qonto)
    # authorize on Authentik group membership at the gateway, so one login
    # covers everything the person is entitled to.
    SCOPES = "openid profile offline_access observability:read grafana:read"
    KEYCHAIN_SERVICE = "detesia-broker-refresh-token"
    CREDENTIAL_BACKEND = "${if pkgs.stdenv.isDarwin then "macOS Keychain" else "private state file"}"
    STATE_DIR = pathlib.Path(
        os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local/state")
    ) / "detesia"
    ACCESS_CACHE = STATE_DIR / "access-token.json"
    REFRESH_TOKEN_FILE = STATE_DIR / "refresh-token"


    def _post(url: str, form: dict) -> dict:
        body = urllib.parse.urlencode(form).encode()
        request = urllib.request.Request(
            url,
            data=body,
            method="POST",
            headers={
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=15) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            try:
                return json.load(error)
            except Exception:
                return {"error": f"http_{error.code}"}


    def _ensure_state_dir() -> None:
        STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
        STATE_DIR.chmod(0o700)


    def _write_private_file(path: pathlib.Path, contents: str) -> None:
        _ensure_state_dir()
        file_descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{path.name}.", dir=STATE_DIR
        )
        try:
            os.fchmod(file_descriptor, 0o600)
            with os.fdopen(file_descriptor, "w") as temporary_file:
                file_descriptor = -1
                temporary_file.write(contents)
                temporary_file.flush()
                os.fsync(temporary_file.fileno())
            os.replace(temporary_name, path)
        finally:
            if file_descriptor >= 0:
                os.close(file_descriptor)
            try:
                pathlib.Path(temporary_name).unlink()
            except FileNotFoundError:
                pass


    def _read_private_file(path: pathlib.Path) -> str | None:
        flags = os.O_RDONLY | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)
        try:
            file_descriptor = os.open(path, flags)
        except FileNotFoundError:
            return None
        with os.fdopen(file_descriptor) as private_file:
            metadata = os.fstat(private_file.fileno())
            if not stat.S_ISREG(metadata.st_mode):
                raise RuntimeError(f"credential is not a regular file: {path}")
            if metadata.st_uid != os.getuid() or metadata.st_mode & 0o077:
                raise RuntimeError(f"credential has unsafe ownership or mode: {path}")
            return private_file.read().strip()


    def _refresh_token_get() -> str | None:
        if CREDENTIAL_BACKEND == "private state file":
            return _read_private_file(REFRESH_TOKEN_FILE)
        result = subprocess.run(
            ["/usr/bin/security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
            capture_output=True,
            text=True,
        )
        return result.stdout.strip() if result.returncode == 0 else None


    def _refresh_token_set(refresh_token: str) -> None:
        if CREDENTIAL_BACKEND == "private state file":
            _write_private_file(REFRESH_TOKEN_FILE, refresh_token)
            return
        subprocess.run(
            [
                "/usr/bin/security", "add-generic-password",
                "-a", os.environ.get("USER", "detesia"),
                "-s", KEYCHAIN_SERVICE,
                "-w", refresh_token,
                "-U",  # update in place if the item exists
            ],
            check=True,
            capture_output=True,
        )


    def _cache_access(payload: dict) -> None:
        record = {
            "access_token": payload["access_token"],
            "expires_at": int(time.time()) + int(payload.get("expires_in", 600)),
        }
        _write_private_file(ACCESS_CACHE, json.dumps(record))


    def _accept_tokens(payload: dict) -> None:
        # Authentik rotates refresh tokens on use; always persist the newest.
        if payload.get("refresh_token"):
            _refresh_token_set(payload["refresh_token"])
        _cache_access(payload)


    def login() -> int:
        print(
            f"detesia cli v{VERSION} (client {CLIENT_ID}, scopes: {SCOPES}, "
            f"credential store: {CREDENTIAL_BACKEND})"
        )
        device = _post(DEVICE_URL, {"client_id": CLIENT_ID, "scope": SCOPES})
        if "device_code" not in device:
            print(f"device authorization failed: {device}", file=sys.stderr)
            return 1
        url = device.get("verification_uri_complete") or device["verification_uri"]
        print(f"Open:  {url}")
        print(f"Code:  {device['user_code']}")
        print(f"(expires in {device.get('expires_in', '?')}s)")
        # Convenience only — headless/SSH sessions fall back to the printed URL.
        try:
            import webbrowser
            webbrowser.open(url)
        except Exception:
            pass
        interval = int(device.get("interval", 5))
        deadline = time.time() + int(device.get("expires_in", 300))
        while time.time() < deadline:
            time.sleep(interval)
            token = _post(TOKEN_URL, {
                "client_id": CLIENT_ID,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                "device_code": device["device_code"],
            })
            if token.get("access_token"):
                _accept_tokens(token)
                print(f"Logged in; refresh token stored in {CREDENTIAL_BACKEND}.")
                return 0
            # Authentik answers invalid_grant (not RFC 8628's
            # authorization_pending) while the code awaits approval; the
            # deadline bounds the loop either way.
            if token.get("error") in ("authorization_pending", "slow_down", "invalid_grant"):
                if token["error"] == "slow_down":
                    interval += 5
                continue
            print(f"login failed: {token.get('error')}", file=sys.stderr)
            return 1
        print("device code expired before approval; run login again", file=sys.stderr)
        return 1


    def token() -> int:
        try:
            record = json.loads(ACCESS_CACHE.read_text())
            if record["expires_at"] - time.time() > 60:
                print(record["access_token"])
                return 0
        except (OSError, ValueError, KeyError):
            pass
        refresh = _refresh_token_get()
        if not refresh:
            print("no session; run `detesia login` first", file=sys.stderr)
            return 1
        payload = _post(TOKEN_URL, {
            "client_id": CLIENT_ID,
            "grant_type": "refresh_token",
            "refresh_token": refresh,
        })
        if not payload.get("access_token"):
            print(
                f"refresh failed ({payload.get('error')}); run `detesia login`",
                file=sys.stderr,
            )
            return 1
        _accept_tokens(payload)
        print(payload["access_token"])
        return 0


    def whoami() -> int:
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            if token() != 0:
                return 1
        seg = buf.getvalue().strip().split(".")[1]
        seg += "=" * (-len(seg) % 4)
        import base64
        claims = json.loads(base64.urlsafe_b64decode(seg))
        out = {"cli_version": VERSION, "credential_store": CREDENTIAL_BACKEND}
        out.update({k: claims.get(k) for k in ("preferred_username", "scope", "groups", "iss", "exp")})
        print(json.dumps(out, indent=2))
        return 0


    if __name__ == "__main__":
        try:
            sys.exit({"login": login, "token": token, "whoami": whoami}[sys.argv[1]]())
        except (OSError, RuntimeError) as error:
            print(f"detesia credential error: {error}", file=sys.stderr)
            sys.exit(1)
  '';

  detesia = pkgs.writeShellScriptBin "detesia" ''
    set -euo pipefail
    PY=${pkgs.python312}/bin/python3
    case "''${1:-}" in
      login|token)
        exec "$PY" -u ${authScript} "$1"
        ;;
      curl)
        shift
        tok="$("$PY" -u ${authScript} token)"
        exec ${pkgs.curl}/bin/curl -sS \
          -H "Authorization: Bearer $tok" \
          -H "X-Actor: ''${DETESIA_ACTOR:-human}" \
          "$@"
        ;;
      whoami)
        exec "$PY" -u ${authScript} whoami
        ;;
      *)
        echo "usage: detesia {login|token|curl <args>|whoami}" >&2
        echo "  broker: https://broker.cluster.detesia.com (/mimir /loki /tempo /grafana /qonto)" >&2
        exit 64
        ;;
    esac
  '';
in
{
  home.packages = [ detesia ];
}
