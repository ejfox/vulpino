#!/usr/bin/env python3
"""Minimal App Store Connect API client — JWT signing lifted from paperclip's
godmode.py (ES256 via openssl, DER->raw). Issuer/key are non-secret identifiers;
the secret is the .p8 on disk.

Usage:
    asc.py get  /v1/apps?filter[bundleId]=com.vulpino.app
    asc.py post /v1/bundleIds '{"data": {...}}'
    asc.py patch /v1/builds/<id> '{"data": {...}}'
"""
import base64, json, os, subprocess, sys, tempfile, time

ASC_KEY_PATH = os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_8FC45Q864T.p8")
ASC_KEY_ID = "8FC45Q864T"
ASC_ISSUER = "3dae97bc-b1b9-4b6b-bb38-0c204c6c6896"


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _der_to_raw(der: bytes) -> bytes:
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    assert der[i] == 0x02
    rlen = der[i + 1]; r = der[i + 2:i + 2 + rlen]
    j = i + 2 + rlen
    assert der[j] == 0x02
    slen = der[j + 1]; sv = der[j + 2:j + 2 + slen]
    return r.lstrip(b"\x00").rjust(32, b"\x00") + sv.lstrip(b"\x00").rjust(32, b"\x00")


def asc_jwt() -> str:
    header = _b64url(json.dumps({"alg": "ES256", "kid": ASC_KEY_ID, "typ": "JWT"}).encode())
    now = int(time.time())
    payload = _b64url(json.dumps(
        {"iss": ASC_ISSUER, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{header}.{payload}".encode()
    with tempfile.NamedTemporaryFile(suffix=".bin") as tf:
        tf.write(signing_input); tf.flush()
        der = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", ASC_KEY_PATH, tf.name],
            capture_output=True, check=True).stdout
    return f"{header}.{payload}.{_b64url(_der_to_raw(der))}"


def call(method: str, path: str, body: str | None = None):
    token = asc_jwt()
    args = ["curl", "-gsS", "-m", "30", "-X", method.upper(),
            f"https://api.appstoreconnect.apple.com{path}",
            "-H", f"Authorization: Bearer {token}"]
    if body:
        args += ["-H", "Content-Type: application/json", "-d", body]
    out = subprocess.run(args, capture_output=True, text=True, check=True).stdout
    return out


if __name__ == "__main__":
    method, path = sys.argv[1], sys.argv[2]
    body = sys.argv[3] if len(sys.argv) > 3 else None
    print(call(method, path, body))
