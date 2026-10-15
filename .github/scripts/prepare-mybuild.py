#!/usr/bin/env python3

"""Prepare private image settings from repository secrets."""

import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import uuid


def required_secret(name):
    value = os.environ.get(name, "")
    if not value or any(char in value for char in "\0\r\n"):
        raise SystemExit(f"{name} must be nonempty and contain no line breaks or NULs")
    return value


def password_hash(password):
    result = subprocess.run(
        ["openssl", "passwd", "-6", "-stdin"],
        input=password + "\n",
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip()


def keyfile_string(value):
    return value.replace("\\", "\\\\").replace(" ", "\\s")


def report_image_format(image_format):
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with Path(output).open("a", encoding="utf-8") as stream:
            stream.write(f"image_format={image_format}\n")


def main():
    names = (
        "ROOT_PASSWORD", "USER_NAME", "USER_PASSWORD",
        "WIFI_SSID", "WIFI_PASSWORD", "IMAGE_PASSWORD",
    )
    destination = Path("userpatches/private/mybuild")
    if destination.exists():
        shutil.rmtree(destination)
    missing = [name for name in names if not os.environ.get(name)]
    if missing:
        print(
            f"::warning::Missing repository secrets: {', '.join(missing)}. "
            "Using standard mode without account/Wi-Fi presets or image encryption."
        )
        report_image_format("xz")
        return
    secrets = {name: required_secret(name) for name in names}
    username = secrets["USER_NAME"]
    if not re.fullmatch(r"[a-z][a-z0-9_-]{0,31}", username) or username == "root":
        raise SystemExit("USER_NAME must be a valid non-root Linux username")
    for name in ("ROOT_PASSWORD", "USER_PASSWORD"):
        if re.fullmatch(r"-[neE]+", secrets[name]):
            raise SystemExit(f"{name} is incompatible with Armbian's password input")
    ssid = secrets["WIFI_SSID"].encode("utf-8")
    if not 1 <= len(ssid) <= 32:
        raise SystemExit("WIFI_SSID must contain 1 to 32 UTF-8 bytes")
    psk = secrets["WIFI_PASSWORD"]
    if not (
        (8 <= len(psk) <= 63 and all(32 <= ord(char) <= 126 for char in psk))
        or re.fullmatch(r"[0-9a-fA-F]{64}", psk)
    ):
        raise SystemExit("WIFI_PASSWORD must contain 8 to 63 printable ASCII characters, or 64 hexadecimal digits")

    os.umask(0o077)
    destination.mkdir(parents=True, exist_ok=True, mode=0o700)
    settings = {
        "PRESET_ROOT_PASSWORD": secrets["ROOT_PASSWORD"],
        "PRESET_USER_NAME": username,
        "PRESET_USER_PASSWORD": secrets["USER_PASSWORD"],
        "PRESET_DEFAULT_REALNAME": username,
        "PRESET_USER_SHELL": "bash",
        "PRESET_LOCALE": "zh_CN.UTF-8",
        "PRESET_TIMEZONE": "Asia/Shanghai",
        "SET_LANG_BASED_ON_LOCATION": "n",
        "PRESET_CONNECT_WIRELESS": "n",
        "PRESET_NET_CHANGE_DEFAULTS": "0",
    }
    (destination / "first-boot.conf").write_text(
        "".join(f"{name}={shlex.quote(value)}\n" for name, value in settings.items()),
        encoding="utf-8",
    )
    (destination / "root-password").write_text(
        f"root:{password_hash(secrets['ROOT_PASSWORD'])}\n", encoding="utf-8",
    )
    (destination / "wifi.nmconnection").write_text(
        "[connection]\n"
        "id=mybuild-wifi\n"
        f"uuid={uuid.uuid4()}\n"
        "type=wifi\n"
        "autoconnect=true\n"
        "autoconnect-priority=100\n"
        "autoconnect-retries=0\n"
        "\n[wifi]\n"
        "mode=infrastructure\n"
        f"ssid={';'.join(str(byte) for byte in ssid)};\n"
        "\n[wifi-security]\n"
        "key-mgmt=wpa-psk\n"
        "psk-flags=0\n"
        f"psk={keyfile_string(psk)}\n"
        "\n[ipv4]\nmethod=auto\n"
        "\n[ipv6]\nmethod=auto\n",
        encoding="utf-8",
    )
    for path in destination.iterdir():
        path.chmod(0o600)
    report_image_format("7z")


if __name__ == "__main__":
    main()
