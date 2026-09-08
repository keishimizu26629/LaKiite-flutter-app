import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createManifest, validateManifest, validateBuild, validateSourceRun, shouldRestoreSnapshot } from './release_manifest.mjs';

const sha = '75579cec858526e10d7d27a8b02a885a76d7ee57';
const notes = { apple: '・友だち申請の承認処理を見直しました。', googlePlay: '・友だち申請の承認処理を見直しました。' };
const input = { version: '2.2.0', tag: 'v2.2.0', sourceSha: sha, runId: '34234985326', releaseId: '42', notes };
const expected = { sourceSha: sha, runId: input.runId };

test('retries reuse a single valid artifact and never recalculate when the snapshot is missing or expired', () => {
  assert.equal(shouldRestoreSnapshot([], '1'), false);
  const artifact = { name: 'release-manifest', expired: false };
  assert.equal(shouldRestoreSnapshot([artifact], '2'), true);
  assert.equal(shouldRestoreSnapshot([artifact], '1'), true);
  assert.throws(() => shouldRestoreSnapshot([], '2'), /snapshot/i);
  assert.throws(() => shouldRestoreSnapshot([{ ...artifact, expired: true }], '2'), /snapshot/i);
  assert.throws(() => shouldRestoreSnapshot([artifact, artifact], '1'), /snapshot/i);
  assert.equal(shouldRestoreSnapshot([{ name: 'unrelated', expired: false }], '1'), false);
  assert.throws(() => shouldRestoreSnapshot([], '0'));
});

test('publishing v2.2.0 after the draft is resolved never increments the build to 2.3.0', () => {
  const snapshot = createManifest(input);
  for (const latestRelease of ['2.1.0', '2.2.0', '2.3.0']) {
    assert.equal(validateManifest(snapshot, { ...expected, latestRelease }).version, '2.2.0');
  }
});

test('both OS jobs and retries receive exactly the same notes and source', () => {
  const artifactBytes = JSON.stringify(createManifest(input));
  for (const consumer of ['ios', 'android', 'retry']) {
    const snapshot = validateManifest(JSON.parse(artifactBytes), expected);
    assert.deepEqual({ version: snapshot.version, source: snapshot.sourceSha, notes: snapshot.notes },
      { version: '2.2.0', source: sha, notes }, consumer);
  }
});

test('a missing snapshot or mismatching source/run fails closed', () => {
  assert.throws(() => validateManifest(null, expected));
  assert.throws(() => validateManifest(createManifest(input), { ...expected, sourceSha: 'f'.repeat(40) }), /source/i);
  assert.throws(() => validateManifest(createManifest(input), { ...expected, runId: '99' }), /run/i);
});

test('manifest integrity detects changed metadata or notes', () => {
  for (const change of [{ version: '2.3.0', tag: 'v2.3.0' }, { notes: { ...notes, apple: 'changed' } }]) {
    assert.throws(() => validateManifest({ ...createManifest(input), ...change }, expected), /digest/i);
  }
});

test('rejects unsupported versions, mismatching tags, empty/overlong notes and invalid identifiers', () => {
  for (const version of ['', 'v2.2.0', '2.2.0-beta', '02.2.0', '2.2', '2.2.0\ninjected=yes']) {
    assert.throws(() => createManifest({ ...input, version }));
  }
  assert.throws(() => createManifest({ ...input, tag: 'v2.3.0' }));
  assert.throws(() => createManifest({ ...input, sourceSha: 'main' }));
  assert.throws(() => createManifest({ ...input, runId: '../123' }));
  assert.throws(() => createManifest({ ...input, notes: { ...notes, googlePlay: '' } }));
  assert.throws(() => createManifest({ ...input, notes: { ...notes, googlePlay: 'あ'.repeat(501) } }));
});

test('artifact version and build number must both match the planned upload', () => {
  const manifest = createManifest(input);
  assert.doesNotThrow(() => validateBuild({ version: '2.2.0', buildNumber: '10665' }, manifest, '10665'));
  assert.throws(() => validateBuild({ version: '2.3.0', buildNumber: '10665' }, manifest, '10665'), /version/i);
  assert.throws(() => validateBuild({ version: '2.2.0', buildNumber: '10664' }, manifest, '10665'), /build/i);
});

const repository = 'Inoworl/LaKiite-flutter-app';
const run = { id: 34234985326, event: 'push', head_branch: 'main', head_sha: sha, conclusion: 'success', path: '.github/workflows/release-drafter.yml', head_repository: { full_name: repository } };
test('manual and automatic source selection only accepts successful main Release Drafter runs from this repo', () => {
  assert.equal(validateSourceRun(run, input.runId, repository), sha);
  for (const change of [{ id: 99 }, { event: 'pull_request' }, { head_branch: 'dev' }, { conclusion: 'failure' }, { path: '.github/workflows/ci.yml' }, { head_repository: { full_name: 'other/repo' } }]) {
    assert.throws(() => validateSourceRun({ ...run, ...change }, input.runId, repository));
  }
});

test('CLI freezes reviewed copy, renders identical consumer files and rejects a real metadata mismatch', () => {
  const directory = mkdtempSync(join(tmpdir(), 'lakiite-release-test-'));
  try {
    const git = args => execFileSync('git', args, { cwd: directory, encoding: 'utf8' }).trim();
    git(['init', '--quiet']);
    git(['-c', 'user.name=Release Test', '-c', 'user.email=release-test@example.invalid', '-c', 'core.hooksPath=/dev/null', 'commit', '--quiet', '--allow-empty', '-m', 'fixture']);
    const sourceSha = git(['rev-parse', 'HEAD']);
    mkdirSync(join(directory, 'release-notes'));
    writeFileSync(join(directory, 'release-notes/ja-JP.json'), JSON.stringify(notes));
    const env = { ...process.env, RELEASE_VERSION: input.version, RELEASE_TAG: input.tag, RELEASE_SHA: sourceSha,
      RELEASE_ID: input.releaseId, GITHUB_RUN_ID: input.runId, RELEASE_RUN_ID: input.runId,
      GITHUB_OUTPUT: join(directory, 'outputs.txt'), EXPECTED_BUILD_NUMBER: '10665' };
    const cli = args => spawnSync(process.execPath, [fileURLToPath(new URL('./release_manifest.mjs', import.meta.url)), ...args], { cwd: directory, env, encoding: 'utf8' });
    let result = cli(['create']);
    assert.equal(result.status, 0, result.stderr);
    const snapshotPath = join(directory, '.release/release-manifest.json');
    const frozenBytes = readFileSync(snapshotPath, 'utf8');
    writeFileSync(join(directory, 'snapshot.json'), frozenBytes);
    // A later branch copy must not change the original run's notes.
    writeFileSync(join(directory, 'release-notes/ja-JP.json'), JSON.stringify({ apple: 'new', googlePlay: 'new' }));
    rmSync(join(directory, '.release'), { recursive: true });
    result = cli(['load', 'snapshot.json']);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(readFileSync(snapshotPath, 'utf8'), frozenBytes);
    assert.equal(readFileSync(join(directory, '.release/apple.txt'), 'utf8'), notes.apple);
    assert.equal(readFileSync(join(directory, '.release/play/ja-JP.txt'), 'utf8'), notes.googlePlay);
    writeFileSync(join(directory, 'actual.json'), JSON.stringify({ version: '2.2.0', buildNumber: '10665' }));
    assert.equal(cli(['verify-build', 'actual.json']).status, 0);
    writeFileSync(join(directory, 'actual.json'), JSON.stringify({ version: '2.3.0', buildNumber: '10665' }));
    assert.notEqual(cli(['verify-build', 'actual.json']).status, 0);
    env.RELEASE_RUN_ID = '99';
    assert.notEqual(cli(['load', 'snapshot.json']).status, 0);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
