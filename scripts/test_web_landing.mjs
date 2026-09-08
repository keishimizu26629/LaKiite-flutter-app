import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { test } from 'node:test';

const web = new URL('../web/', import.meta.url);
const html = readFileSync(new URL('index.html', web), 'utf8');
const css = readFileSync(new URL('style.css', web), 'utf8');
const origin = 'https://lakiite-flutter-app-prod.web.app/';
const stores = [
  ['ios', 'https://apps.apple.com/jp/app/lakiite/id6746154277'],
  ['android', 'https://play.google.com/store/apps/details?id=com.inoworl.lakiite&hl=ja&gl=JP'],
];

// Inspect the static, quoted HTML attributes emitted by this hand-authored LP.
// Layout, focus visibility, and browser behavior are checked separately.
function attributes(tag) {
  return Object.fromEntries([...tag.matchAll(/([\w:-]+)="([^"]*)"/g)]
    .map(([, key, value]) => [key, value.replaceAll('&amp;', '&')]));
}

function tags(source, name) {
  return [...source.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'g'))]
    .map(([tag]) => attributes(tag));
}

function section(className) {
  const match = [...html.matchAll(/<section\b([^>]*)>([\s\S]*?)<\/section>/g)]
    .find(([, attrs]) => attributes(attrs).class?.split(' ').includes(className));
  assert.ok(match, `${className} section exists`);
  return match[2];
}

// Static contracts for this stylesheet's simple rules, not a CSS cascade engine.
// Computed hover/focus colors and responsive geometry need browser checks too.
function declarations(source, selector) {
  const result = {};
  const uncommented = source.replace(/\/\*[\s\S]*?\*\//g, '');
  for (const [, selectors, body] of uncommented.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    if (!selectors.split(',').map(value => value.trim()).includes(selector)) continue;
    for (const declaration of body.split(';')) {
      const colon = declaration.indexOf(':');
      if (colon < 0) continue;
      result[declaration.slice(0, colon).trim()] = declaration.slice(colon + 1).trim();
    }
  }
  return result;
}

function contrast(foreground, background) {
  const tokens = declarations(css, ':root');
  const luminance = value => {
    assert.equal(typeof value, 'string', 'a color declaration must exist');
    const token = value.match(/^var\((--[\w-]+)\)$/)?.[1];
    const hex = token ? tokens[token] : value;
    assert.match(hex ?? '', /^#(?:[a-f\d]{3}|[a-f\d]{6})$/i, `supported color: ${value}`);
    const digits = hex.length === 4 ? [...hex.slice(1)].map(v => v + v).join('') : hex.slice(1);
    const rgb = digits.match(/../g).map(v => parseInt(v, 16) / 255)
      .map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
    return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
  };
  const values = [luminance(foreground), luminance(background)];
  return (Math.max(...values) + 0.05) / (Math.min(...values) + 0.05);
}

function mediaRules(condition) {
  const start = css.indexOf(`@media ${condition} {`);
  assert.ok(start >= 0, `media query exists: ${condition}`);
  const bodyStart = css.indexOf('{', start) + 1;
  let depth = 1;
  for (let i = bodyStart; i < css.length; i++) {
    if (css[i] === '{') depth++;
    if (css[i] === '}' && --depth === 0) return css.slice(bodyStart, i);
  }
  assert.fail(`unclosed media query: ${condition}`);
}

for (const [surface, className] of [['hero', 'hero'], ['footer', 'cta']]) {
  for (const [platform, href] of stores) {
    test(`${surface}: ${platform} has a direct, labeled store link without JavaScript`, () => {
      const links = tags(section(className), 'a').filter(link => link.href === href);
      assert.equal(links.length, 1);
      assert.ok(links[0]['aria-label']);
      assert.equal(links[0]['data-growth-channel'], 'owned_web');
      assert.equal(links[0]['data-growth-campaign'], 'jp_install_casual_friends_202609');
      assert.equal(links[0]['data-growth-content'], `${surface}_oinamiman_a`);
      assert.equal(links[0]['data-growth-platform'], platform);
    });
  }
}

test('all five public legal and support destinations remain accessible in the footer', () => {
  const footer = html.match(/<footer\b[\s\S]*?<\/footer>/)?.[0];
  assert.ok(footer);
  const destinations = tags(footer, 'a').map(link => link.href);
  for (const file of ['privacy-policy.html', 'terms-of-service.html', 'support.html',
    'child-safety-standards.html', 'account-deletion.html']) {
    assert.ok(destinations.includes(file), file);
  }
});

test('registration copy describes the currently available email/password flow', () => {
  const how = section('how');
  assert.ok(how.includes('メールアドレスとパスワードで'));
  assert.doesNotMatch(how, /Apple|Google認証/);
});

test('heading hierarchy does not skip a level', () => {
  let previous = 0;
  for (const [, level] of html.matchAll(/<h([1-6])\b/g)) {
    assert.ok(Number(level) <= previous + 1, `h${previous} to h${level}`);
    previous = Number(level);
  }
});

test('accent text is legible against white and warm surfaces', () => {
  for (const background of ['surface', 'bg-warm']) {
    const ratio = contrast('var(--primary-dark)', `var(--${background})`);
    assert.ok(ratio >= 4.5, `${background}: ${ratio.toFixed(2)}:1`);
  }
});

test('download navigation text retains contrast in its normal and hover states', () => {
  const normal = declarations(css, '.nav-cta');
  const hover = { ...normal, ...declarations(css, '.nav-cta:hover') };
  for (const [state, rule] of [['normal', normal], ['hover', hover]]) {
    const ratio = contrast(rule.color, rule.background);
    assert.ok(ratio >= 4.5, `${state}: ${ratio.toFixed(2)}:1`);
  }
});

test('footer focus indicator contrasts with the dark footer surface', () => {
  const focus = {
    ...declarations(css, 'a:focus-visible'),
    ...declarations(css, '.footer a:focus-visible'),
  };
  const color = focus['outline-color'] ?? focus.outline?.split(/\s+/).at(-1);
  const ratio = contrast(color, declarations(css, '.footer').background);
  assert.ok(ratio >= 3, `footer focus: ${ratio.toFixed(2)}:1`);
});

test('mobile footer allows links to wrap as items and bounds enlarged link text', () => {
  const base = css.slice(0, css.indexOf('@media'));
  const mobile = mediaRules('(max-width: 768px)');
  const links = { ...declarations(base, '.footer-links'), ...declarations(mobile, '.footer-links') };
  const link = { ...declarations(base, '.footer-links a'), ...declarations(mobile, '.footer-links a') };
  assert.equal(links['flex-wrap'], 'wrap', 'links must not shrink into five narrow columns');
  assert.equal(link['max-width'], '100%',
    'an enlarged label must remain within the footer width');
});

test('footer wrapping is also available above the mobile breakpoint', () => {
  const firstMedia = css.indexOf('@media');
  assert.ok(firstMedia > 0);
  const base = css.slice(0, firstMedia);
  assert.equal(declarations(base, '.footer-links')['flex-wrap'], 'wrap',
    'tablet widths must wrap links instead of squeezing their text');
  assert.equal(declarations(base, '.footer-links a')['max-width'], '100%');
});

test('canonical and social metadata describe the same production page', () => {
  const links = tags(html, 'link');
  assert.equal(links.find(link => link.rel === 'canonical')?.href, origin);
  const meta = Object.fromEntries(tags(html, 'meta').map(tag => [tag.property ?? tag.name, tag.content]));
  const title = html.match(/<title>([^<]+)<\/title>/)?.[1];
  assert.ok(title?.includes('お誘い未満'));
  assert.equal(meta['og:title'], title);
  assert.equal(meta['twitter:title'], title);
  assert.equal(meta['og:description'], meta.description);
  assert.equal(meta['twitter:description'], meta.description);
  assert.equal(meta['og:url'], origin);
  assert.equal(meta['og:type'], 'website');
  assert.equal(meta['og:locale'], 'ja_JP');
  assert.equal(meta['og:image'], `${origin}images/logo.png`);
  assert.equal(meta['twitter:image'], meta['og:image']);
  assert.equal(meta['twitter:card'], 'summary');
  assert.ok(meta['og:image:alt']);
  assert.equal(meta['twitter:image:alt'], meta['og:image:alt']);
});

test('structured data is valid JSON and describes the actual app, without invented ratings', () => {
  const json = html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)?.[1];
  assert.ok(json);
  const app = JSON.parse(json);
  assert.equal(app['@context'], 'https://schema.org');
  assert.equal(app['@type'], 'SoftwareApplication');
  assert.equal(app.name, 'LaKiite');
  assert.equal(app.url, origin);
  assert.deepEqual(app.downloadUrl, stores.map(([, href]) => href));
  assert.equal(app.operatingSystem, 'iOS, Android');
  assert.equal(app.aggregateRating, undefined);
  assert.equal(app.review, undefined);
});

test('local linked files, styles, icons and images exist; fragment targets resolve', () => {
  const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(([, id]) => id));
  for (const tag of [...tags(html, 'a'), ...tags(html, 'link'), ...tags(html, 'img')]) {
    const target = tag.href ?? tag.src;
    if (!target || /^(https?:|mailto:)/.test(target)) continue;
    if (target.startsWith('#')) {
      assert.ok(target === '#' || ids.has(target.slice(1)), target);
    } else {
      assert.ok(existsSync(new URL(target, web)), target);
    }
  }
  for (const image of tags(html, 'img')) assert.ok('alt' in image, image.src);
});

test('robots advertises the production sitemap', () => {
  const robots = readFileSync(new URL('robots.txt', web), 'utf8');
  assert.match(robots, /^User-agent: \*$/m);
  assert.match(robots, /^Allow: \/$/m);
  assert.ok(robots.includes(`Sitemap: ${origin}sitemap.xml`));
  assert.ok(!robots.includes('localhost') && !robots.includes('-dev.'));
});

test('sitemap contains only existing public pages on the production origin', () => {
  const sitemap = readFileSync(new URL('sitemap.xml', web), 'utf8');
  assert.match(sitemap, /xmlns="http:\/\/www.sitemaps.org\/schemas\/sitemap\/0.9"/);
  const urls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map(([, url]) => url);
  assert.ok(urls.includes(origin));
  assert.equal(new Set(urls).size, urls.length);
  for (const url of urls) {
    assert.ok(url.startsWith(origin), url);
    assert.ok(!url.includes('account-deletion-webview'));
    assert.ok(existsSync(new URL(url.slice(origin.length) || 'index.html', web)), url);
  }
});
