import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const read = file => readFileSync(new URL(`../${file}`, import.meta.url), 'utf8');
test('build consumers never recompute a version from mutable latest releases or PR labels', () => {
  const action = read('.github/actions/resolve-release-version/action.yml');
  assert.doesNotMatch(action, /releases\/latest|semver_label|release-drafter\/release-drafter|pubspec\.yaml/);
  assert.match(action, /actions\/download-artifact@v4/);
  assert.match(action, /run-id: \$\{\{ inputs\.run-id \}\}/);
});
test('both prod jobs validate the source run and their real artifacts before uploading', () => {
  for (const os of ['ios', 'android']) {
    const workflow = read(`.github/workflows/deploy_prod_${os}.yml`);
    assert.match(workflow, /release_run_id:/);
    assert.match(workflow, /actions: read/);
    assert.match(workflow, /\.\/\.github\/actions\/prepare-release-source/);
    assert.match(workflow, /ref: \$\{\{ steps\.release_source\.outputs\.sha \}\}/);
    const verification = workflow.indexOf('Verify built release metadata');
    const upload = workflow.indexOf(os === 'ios' ? '- name: Upload to TestFlight' : '- name: Deploy to Play Store');
    assert.ok(verification >= 0 && verification < upload, 'metadata verification must run before store upload');
    assert.match(workflow, /verify_release_artifact\.py/);
    assert.doesNotMatch(workflow, /LATEST_COMMIT_MESSAGES/);
    assert.match(workflow, /run-id: \$\{\{ steps\.release_source\.outputs\.run_id \}\}/);
    if (os === 'android') {
      assert.match(workflow, /whatsNewDirectory: \.release\/play/);
      assert.match(workflow, /--release-notes-file \.release\/play\/ja-JP\.txt/);
      assert.match(workflow, /verify-build \.release\/aab-metadata\.json/);
      assert.match(workflow, /verify-build \.release\/apk-metadata\.json/);
    }
  }
});
test('parent publishes one immutable snapshot and reuses it for retries', () => {
  const workflow = read('.github/workflows/release-drafter.yml');
  assert.match(workflow, /Restore frozen release manifest/);
  assert.match(workflow, /actions\/upload-artifact@v4/);
  assert.match(workflow, /name: release-manifest/);
  assert.match(workflow, /include-hidden-files: true/);
  assert.match(workflow, /release_manifest\.mjs restore-check/);
  assert.doesNotMatch(workflow, /overwrite: true/);
});
