import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir, mkdtemp, readdir, rename, rm, symlink } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';

const root = new URL('../', import.meta.url);
const canonicalOrigin = 'https://lakiite.inoworl.com/';
const publicPages = ['index.html', 'how-to-use.html', 'support.html', 'privacy-policy.html', 'terms-of-service.html', 'child-safety-standards.html', 'account-deletion.html'];

test('every sitemap page declares its own production custom-domain canonical', async () => {
  for (const file of publicPages) {
    const html = await readFile(new URL(`web/${file}`, root), 'utf8');
    const canonicals = [...html.matchAll(/<link\s+rel="canonical"\s+href="([^"]+)"\s*\/?>/g)].map(m => m[1]);
    assert.deepEqual(canonicals, [canonicalOrigin + (file === 'index.html' ? '' : file)], file);
    assert.doesNotMatch(html, /<meta\b[^>]*name="robots"[^>]*noindex/i);
  }
});

async function fixture(t) {
  const dir = await mkdtemp(path.join(tmpdir(), 'lakiite-hosting-seo-test-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  await mkdir(path.join(dir, 'web', 'images'), { recursive: true });
  await mkdir(path.join(dir, 'web', '.well-known'));
  await writeFile(path.join(dir, 'firebase.json'), JSON.stringify({ hosting: {
    public: 'web', ignore: ['firebase.json', '**/.*', '**/node_modules/**'],
    headers: [{ source: '/app-ads.txt', headers: [{ key: 'Cache-Control', value: 'max-age=3600' }] }],
  } }));
  const files = {
    'index.html': '<!doctype html><head><link rel="canonical" href="https://lakiite.inoworl.com/"></head><body>LaKiite（ラキーテ）</body>',
    'robots.txt': 'User-agent: *\nAllow: /\nSitemap: https://lakiite.inoworl.com/sitemap.xml\n',
    'sitemap.xml': '<urlset><url><loc>https://lakiite.inoworl.com/</loc></url></urlset>',
    'images/sample.svg': '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
    '.well-known/assetlinks.json': '[]',
    '.well-known/apple-app-site-association': '{"applinks":{"details":[]}}',
    'app-ads.txt': 'example.com, demo, DIRECT',
    'README.md': 'internal publishing notes',
    '.env': 'TEST_ONLY_NOT_A_SECRET=excluded',
  };
  for (const [file, text] of Object.entries(files)) await writeFile(path.join(dir, 'web', file), text);
  return { dir, files };
}

for (const target of ['dev', 'prod']) {
  test(`${target}: prepare an isolated, correctly indexed Hosting artifact without changing source`, async t => {
    const { prepareHosting } = await import('./prepare_hosting.mjs');
    const { dir, files } = await fixture(t);
    const configPath = await prepareHosting({ target, repoRoot: dir });
    const config = JSON.parse(await readFile(configPath, 'utf8'));
    const outputWeb = path.join(path.dirname(configPath), config.hosting.public);
    assert.ok(outputWeb.startsWith(path.join(dir, 'build') + path.sep));
    const globalRobots = config.hosting.headers.filter(rule => rule.source === '**').flatMap(rule => rule.headers).find(h => h.key === 'X-Robots-Tag');
    assert.equal(globalRobots?.value, target === 'dev' ? 'noindex, nofollow' : undefined);
    assert.ok(config.hosting.headers.some(rule => rule.source === '/app-ads.txt'));
    assert.ok(!config.hosting.ignore.includes('**/.*'), 'preserve existing app association files');
    for (const file of ['index.html', 'images/sample.svg', '.well-known/assetlinks.json', '.well-known/apple-app-site-association', 'app-ads.txt']) {
      assert.equal(await readFile(path.join(outputWeb, file), 'utf8'), files[file], file);
    }
    for (const file of ['README.md', '.env']) await assert.rejects(readFile(path.join(outputWeb, file)), { code: 'ENOENT' });
    const robots = await readFile(path.join(outputWeb, 'robots.txt'), 'utf8');
    if (target === 'dev') {
      assert.match(robots, /^Allow: \/$/m, 'allow crawler to see noindex');
      assert.doesNotMatch(robots, /Sitemap:|Disallow: \/$/m);
      await assert.rejects(readFile(path.join(outputWeb, 'sitemap.xml')), { code: 'ENOENT' });
    } else {
      assert.equal(robots, files['robots.txt']);
      assert.equal(await readFile(path.join(outputWeb, 'sitemap.xml'), 'utf8'), files['sitemap.xml']);
    }
    for (const [file, text] of Object.entries(files)) assert.equal(await readFile(path.join(dir, 'web', file), 'utf8'), text);
    const second = await prepareHosting({ target, repoRoot: dir });
    assert.notEqual(second, configPath, 'a repeated build does not overwrite a previous artifact');
  });
}

test('a missing or unknown environment fails closed before producing an artifact', async t => {
  const { prepareHosting } = await import('./prepare_hosting.mjs');
  const { dir } = await fixture(t);
  for (const target of [undefined, '', 'production', '../prod']) await assert.rejects(prepareHosting({ target, repoRoot: dir }), /dev or prod/);
  await assert.rejects(readdir(path.join(dir, 'build')), { code: 'ENOENT' });
});

test('symlinks cannot pull files from outside the public source into a deploy', async t => {
  const { prepareHosting } = await import('./prepare_hosting.mjs');
  const { dir } = await fixture(t);
  await writeFile(path.join(dir, 'private-test.txt'), 'test fixture only');
  await symlink(path.join(dir, 'private-test.txt'), path.join(dir, 'web', 'leak.txt'));
  await assert.rejects(prepareHosting({ target: 'dev', repoRoot: dir }), /symbolic link/);
});

for (const directory of ['web', 'build']) {
  test(`a symbolic-link ${directory} root is rejected`, async t => {
    const { prepareHosting } = await import('./prepare_hosting.mjs');
    const { dir } = await fixture(t);
    const outside = path.join(dir, 'outside');
    if (directory === 'web') await rename(path.join(dir, 'web'), outside);
    else await mkdir(outside);
    await symlink(outside, path.join(dir, directory));
    await assert.rejects(prepareHosting({ target: 'prod', repoRoot: dir }), /symbolic link/);
  });
}

test('the CLI requires an explicit, valid target and never prints a config on failure', () => {
  const cli = new URL('prepare_hosting.mjs', import.meta.url);
  for (const args of [[], ['--target', 'qa'], ['--target', 'dev', '--extra']]) {
    const result = spawnSync(process.execPath, [cli.pathname, ...args], { encoding: 'utf8' });
    assert.equal(result.status, 1);
    assert.equal(result.stdout, '');
    assert.match(result.stderr, /Usage:|dev or prod/);
  }
});

test('Hosting automation validates, generates and deploys the matching environment config', async () => {
  const workflow = await readFile(new URL('.github/workflows/deploy_firebase_hosting.yml', root), 'utf8');
  assert.match(workflow, /scripts\/prepare_hosting\.mjs/);
  assert.match(workflow, /node --test scripts\/test_web_landing\.mjs scripts\/test_store_marketing\.mjs scripts\/test_hosting_seo\.mjs/);
  assert.match(workflow, /--target dev/);
  assert.match(workflow, /--target prod/);
  assert.equal((workflow.match(/--config "\$\{\{ steps\.prepare\.outputs\.config \}\}"/g) || []).length, 2);
  assert.match(workflow, /if: github\.ref == 'refs\/heads\/main' &&/);
  assert.match(workflow, /github\.event_name == 'push' && github\.ref == 'refs\/heads\/dev'/);
});

test('non-deploying PR CI runs the same landing, store and SEO contracts on Node 20', async () => {
  const workflow = await readFile(new URL('.github/workflows/ci.yml', root), 'utf8');
  const job = workflow.match(/^  web-contracts:\n([\s\S]*?)(?=^  [\w-]+:\n|$(?![\s\S]))/m)?.[1];
  assert.ok(job, 'a dedicated web-contracts job exists');
  assert.match(job, /node-version: '20\.x'/);
  assert.match(job, /node --test scripts\/test_web_landing\.mjs scripts\/test_store_marketing\.mjs scripts\/test_hosting_seo\.mjs/);
  assert.doesNotMatch(job, /firebase deploy|secrets\./);
});

test('the final CI gate includes web-contracts in both dependencies and result checking', async () => {
  const workflow = await readFile(new URL('.github/workflows/ci.yml', root), 'utf8');
  const gate = workflow.slice(workflow.indexOf('  ci_success:'));
  assert.match(gate, /needs: \[analyze, test, web-contracts\]/);
  assert.match(gate, /&& "\$\{\{ needs\.web-contracts\.result \}\}" == "success"/);
});
