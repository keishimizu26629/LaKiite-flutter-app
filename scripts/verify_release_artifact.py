"""Read version metadata from the built IPA/AAB/APK; stdout is JSON only."""
import argparse
import json
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile


def metadata(version, build_number):
    if not isinstance(version, str) or not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", version):
        raise ValueError("Artifact has missing/invalid version name")
    if not isinstance(build_number, str) or not re.fullmatch(r"[1-9]\d*", build_number):
        raise ValueError("Artifact has missing/invalid build number")
    return {"version": version, "buildNumber": build_number}


def read_ipa(path):
    with zipfile.ZipFile(path) as archive:
        matches = [info for info in archive.infolist()
                   if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", info.filename)]
        if len(matches) != 1 or matches[0].file_size > 1024 * 1024:
            raise ValueError("Expected exactly one bounded top-level app Info.plist")
        info = plistlib.loads(archive.read(matches[0]))
    return metadata(info.get("CFBundleShortVersionString"), info.get("CFBundleVersion"))


def read_android(path, bundletool, apkanalyzer):
    if path.suffix == ".aab" and bundletool:
        command = ["java", "-jar", bundletool, "dump", "manifest", f"--bundle={path}", "--module=base"]
    elif path.suffix == ".apk" and apkanalyzer:
        command = [apkanalyzer, "manifest", "print", str(path)]
    else:
        raise ValueError("AAB needs --bundletool; APK needs --apkanalyzer")
    manifest = ET.fromstring(subprocess.check_output(command, text=True, timeout=120))
    if manifest.tag != "manifest":
        raise ValueError("Android tool did not return a manifest")
    namespace = "{http://schemas.android.com/apk/res/android}"
    return metadata(manifest.get(namespace + "versionName"), manifest.get(namespace + "versionCode"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--bundletool")
    parser.add_argument("--apkanalyzer")
    args = parser.parse_args()
    if not args.artifact.is_file():
        raise ValueError("Built artifact does not exist")
    value = read_ipa(args.artifact) if args.artifact.suffix == ".ipa" else read_android(args.artifact, args.bundletool, args.apkanalyzer)
    print(json.dumps(value))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Artifact verification failed: {error}", file=sys.stderr)
        sys.exit(1)
