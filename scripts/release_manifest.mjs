import { createHash, randomUUID } from 'node:crypto';
import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const semver = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const shaPattern = /^[a-f0-9]{40}$/;
const idPattern = /^[1-9]\d*$/;
const requireThat = (condition, message) => { if (!condition) throw new Error(message); };

function metadata(input) {
  requireThat(input && semver.test(input.version), 'Invalid release version');
  requireThat(input.tag === `v${input.version}`, 'Tag/version mismatch');
  requireThat(shaPattern.test(input.sourceSha), 'Invalid source SHA');
  for (const key of ['runId', 'releaseId']) {
    requireThat(typeof input[key] === 'string' && idPattern.test(input[key]), `Invalid ${key}`);
  }
  const notes = {};
  for (const [platform, limit] of [['apple', 4000], ['googlePlay', 500]]) {
    const value = input.notes?.[platform];
    requireThat(typeof value === 'string' && value.trim().length > 0 && [...value].length <= limit && !value.includes('\0'), `Invalid ${platform} notes`);
    notes[platform] = value;
  }
  return { schemaVersion: 1, version: input.version, tag: input.tag, sourceSha: input.sourceSha, runId: input.runId, releaseId: input.releaseId, notes };
}

const digest = value => createHash('sha256').update(JSON.stringify(value)).digest('hex');

export function createManifest(input) {
  const value = metadata(input);
  return { ...value, digest: digest(value) };
}

export function shouldRestoreSnapshot(artifacts, attempt) {
  requireThat(idPattern.test(attempt) && Array.isArray(artifacts), 'Invalid snapshot lookup');
  const matches = artifacts.filter(artifact => artifact.name === 'release-manifest');
  if (matches.length === 1 && matches[0].expired === false) return true;
  if (matches.length === 0 && attempt === '1') return false;
  throw new Error('Missing/expired/ambiguous snapshot on retry; investigate the original run instead of recalculating');
}

export function validateManifest(input, expected) {
  requireThat(input?.schemaVersion === 1, 'Missing or unsupported release snapshot');
  const value = metadata(input);
  requireThat(input.digest === digest(value), 'Release snapshot digest mismatch');
  requireThat(value.sourceSha === expected.sourceSha, 'Release source SHA mismatch');
  requireThat(value.runId === expected.runId, 'Release run ID mismatch');
  return { ...value, digest: input.digest };
}

export function validateBuild(actual, manifest, expectedBuildNumber) {
  requireThat(actual.version === manifest.version, `Built version ${actual.version} differs from release ${manifest.version}`);
  requireThat(idPattern.test(expectedBuildNumber) && actual.buildNumber === expectedBuildNumber, 'Built build number differs from planned build number');
}

export function validateSourceRun(run, runId, repository) {
  requireThat(typeof runId === 'string' && idPattern.test(runId) && String(run.id) === runId, 'Invalid release run ID');
  requireThat(run.head_repository?.full_name === repository, 'Release run repository mismatch');
  requireThat(run.event === 'push' && run.head_branch === 'main', 'Release run must originate from a main push');
  requireThat(run.path === '.github/workflows/release-drafter.yml' && run.conclusion === 'success', 'Release Drafter run must have succeeded');
  requireThat(shaPattern.test(run.head_sha), 'Invalid release run source SHA');
  return run.head_sha;
}

function output(key, value) {
  if (!process.env.GITHUB_OUTPUT) return;
  const delimiter = `release_${randomUUID()}`;
  appendFileSync(process.env.GITHUB_OUTPUT, `${key}<<${delimiter}\n${value}\n${delimiter}\n`);
}

function render(manifest) {
  mkdirSync('.release/play', { recursive: true });
  writeFileSync('.release/release-manifest.json', `${JSON.stringify(manifest, null, 2)}\n`);
  writeFileSync('.release/apple.txt', manifest.notes.apple);
  writeFileSync('.release/play/ja-JP.txt', manifest.notes.googlePlay);
  for (const [key, value] of Object.entries({ version: manifest.version, tag: manifest.tag, source_sha: manifest.sourceSha, run_id: manifest.runId, release_id: manifest.releaseId })) output(key, value);
  console.log(`Verified release ${manifest.tag}, source ${manifest.sourceSha}, run ${manifest.runId}`);
}

const json = path => JSON.parse(readFileSync(path, 'utf8'));
const head = () => execFileSync('git', ['rev-parse', '--verify', 'HEAD'], { encoding: 'utf8' }).trim();

function main(command, args) {
  if (command === 'restore-check') {
    output('exists', String(shouldRestoreSnapshot(json(args[0]), process.env.GITHUB_RUN_ATTEMPT)));
  } else if (command === 'source') {
    const sourceSha = validateSourceRun(json(args[0]), process.env.RELEASE_RUN_ID, process.env.GITHUB_REPOSITORY);
    output('sha', sourceSha);
    output('run_id', process.env.RELEASE_RUN_ID);
  } else if (command === 'create') {
    requireThat(head() === process.env.RELEASE_SHA, 'Snapshot checkout source mismatch');
    render(createManifest({ version: process.env.RELEASE_VERSION, tag: process.env.RELEASE_TAG, sourceSha: process.env.RELEASE_SHA, runId: process.env.GITHUB_RUN_ID, releaseId: process.env.RELEASE_ID, notes: json('release-notes/ja-JP.json') }));
  } else if (command === 'load') {
    render(validateManifest(json(args[0]), { sourceSha: head(), runId: process.env.RELEASE_RUN_ID }));
  } else if (command === 'header') {
    const notes = json('release-notes/ja-JP.json');
    // Validate copy before allowing it into the draft or artifact.
    metadata({ version: '0.0.0', tag: 'v0.0.0', sourceSha: head(), runId: '1', releaseId: '1', notes });
    const header = `## アプリの更新内容\n\n### iOS\n${notes.apple}\n\n### Android\n${notes.googlePlay}\n\n対象コミット: \`${head()}\`\n\n以下はWeb・CIも含む開発者向けの変更履歴です。ストア文言更新・一般公開の完了を意味しません。\n`;
    output('header', header);
  } else if (command === 'verify-build') {
    const manifest = validateManifest(json('.release/release-manifest.json'), { sourceSha: head(), runId: process.env.RELEASE_RUN_ID });
    validateBuild(json(args[0]), manifest, process.env.EXPECTED_BUILD_NUMBER);
    console.log(`Artifact metadata verified: ${manifest.version} (${process.env.EXPECTED_BUILD_NUMBER})`);
  } else {
    throw new Error(`Unknown release command: ${command}`);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv[2], process.argv.slice(3)); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
