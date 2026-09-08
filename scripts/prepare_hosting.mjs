import { copyFile, lstat, mkdir, mkdtemp, readFile, readdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const defaultRoot = fileURLToPath(new URL('../', import.meta.url));

async function copyPublicTree(source, destination, { target, topLevel = true }) {
  const stat = await lstat(source);
  if (stat.isSymbolicLink()) throw new Error('Public source must not contain a symbolic link');
  if (!stat.isDirectory()) throw new Error('Public source must be a directory');
  await mkdir(destination, { recursive: true });
  for (const entry of await readdir(source, { withFileTypes: true })) {
    if (entry.name === 'README.md' || entry.name === 'node_modules') continue;
    if (entry.name.startsWith('.') && !(topLevel && entry.name === '.well-known')) continue;
    if (target === 'dev' && topLevel && entry.name === 'sitemap.xml') continue;
    if (entry.isSymbolicLink()) throw new Error('Public source must not contain a symbolic link');
    const from = path.join(source, entry.name);
    const to = path.join(destination, entry.name);
    if (entry.isDirectory()) await copyPublicTree(from, to, { target, topLevel: false });
    else if (entry.isFile()) await copyFile(from, to);
    else throw new Error('Public source contains an unsupported file type');
  }
}

/** Build a new, local-only artifact. This function never deploys or changes web/. */
export async function prepareHosting({ target, repoRoot = defaultRoot } = {}) {
  if (!['dev', 'prod'].includes(target)) throw new Error('Hosting target must be explicitly dev or prod');
  const base = JSON.parse(await readFile(path.join(repoRoot, 'firebase.json'), 'utf8'));
  if (!base.hosting || Array.isArray(base.hosting) || base.hosting.public !== 'web') {
    throw new Error('Expected one Hosting configuration with public directory web');
  }
  const buildRoot = path.join(repoRoot, 'build');
  await mkdir(buildRoot, { recursive: true });
  if ((await lstat(buildRoot)).isSymbolicLink()) throw new Error('Build output must not be a symbolic link');
  const output = await mkdtemp(path.join(buildRoot, `hosting-${target}-`));
  const publicDir = path.join(output, 'web');
  await copyPublicTree(path.join(repoRoot, 'web'), publicDir, { target });

  const hosting = {
    ...base.hosting,
    public: 'web',
    // Hidden source files are filtered above; .well-known must remain deployable.
    ignore: [...new Set([...(base.hosting.ignore ?? []).filter(pattern => pattern !== '**/.*'), '**/README.md'])],
    headers: [...(base.hosting.headers ?? [])],
  };
  if (target === 'dev') {
    hosting.headers.push({ source: '**', headers: [{ key: 'X-Robots-Tag', value: 'noindex, nofollow' }] });
    // Crawlers must be able to fetch a page to observe its noindex HTTP header.
    await writeFile(path.join(publicDir, 'robots.txt'), 'User-agent: *\nAllow: /\n');
  }
  const configPath = path.join(output, 'firebase.json');
  await writeFile(configPath, JSON.stringify({ hosting }, null, 2) + '\n');
  return configPath;
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  const args = process.argv.slice(2);
  try {
    if (args.length !== 2 || args[0] !== '--target') throw new Error('Usage: node scripts/prepare_hosting.mjs --target dev|prod');
    console.log(await prepareHosting({ target: args[1] }));
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
