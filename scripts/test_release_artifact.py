"""Artifact readers must inspect archive contents, never build arguments."""
import importlib.util
import plistlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

SPEC = importlib.util.spec_from_file_location(
    "artifact", Path(__file__).with_name("verify_release_artifact.py")
)
artifact = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(artifact)

XML = '<manifest xmlns:android="http://schemas.android.com/apk/res/android" android:versionCode="1788875932" android:versionName="2.3.0"/>'


class ArtifactTests(unittest.TestCase):
    def test_binary_ipa_plist_and_extension_are_not_confused(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "release.ipa"
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("Payload/Runner.app/Info.plist", plistlib.dumps({
                    "CFBundleShortVersionString": "2.3.0", "CFBundleVersion": "10665",
                }, fmt=plistlib.FMT_BINARY))
                archive.writestr("Payload/Runner.app/PlugIns/Widget.appex/Info.plist", b"ignore")
            self.assertEqual(artifact.read_ipa(path), {"version": "2.3.0", "buildNumber": "10665"})

    def test_ipa_with_missing_or_ambiguous_app_plist_fails(self):
        for entries in [[], ["Payload/A.app/Info.plist", "Payload/B.app/Info.plist"]]:
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "release.ipa"
                with zipfile.ZipFile(path, "w") as archive:
                    for entry in entries:
                        archive.writestr(entry, b"invalid")
                with self.assertRaises(ValueError):
                    artifact.read_ipa(path)

    def test_aab_reads_base_module_using_bundletool(self):
        with patch.object(artifact.subprocess, "check_output", return_value=XML) as execute:
            self.assertEqual(artifact.read_android(Path("release.aab"), "bundletool.jar", None),
                             {"version": "2.3.0", "buildNumber": "1788875932"})
            self.assertEqual(execute.call_args.args[0], ["java", "-jar", "bundletool.jar", "dump", "manifest", "--bundle=release.aab", "--module=base"])

    def test_apk_reads_manifest_using_sdk_analyzer(self):
        with patch.object(artifact.subprocess, "check_output", return_value=XML) as execute:
            self.assertEqual(artifact.read_android(Path("release.apk"), None, "/sdk/apkanalyzer"),
                             {"version": "2.3.0", "buildNumber": "1788875932"})
            self.assertEqual(execute.call_args.args[0], ["/sdk/apkanalyzer", "manifest", "print", "release.apk"])

    def test_missing_or_invalid_manifest_fields_and_tool_failure_fail_closed(self):
        for xml in ["<manifest/>", XML.replace("2.3.0", "@string/version"), XML.replace("1788875932", "0"), "not XML"]:
            with patch.object(artifact.subprocess, "check_output", return_value=xml):
                with self.assertRaises((ValueError, artifact.ET.ParseError)):
                    artifact.read_android(Path("release.apk"), None, "apkanalyzer")
        with patch.object(artifact.subprocess, "check_output", side_effect=subprocess.CalledProcessError(1, "tool")):
            with self.assertRaises(subprocess.CalledProcessError):
                artifact.read_android(Path("release.aab"), "bundletool.jar", None)


if __name__ == "__main__":
    unittest.main()
