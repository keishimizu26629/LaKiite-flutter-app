import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { test } from 'node:test';

const folder = new URL('../docs/marketing/store/ja-JP/', import.meta.url);
const load = file => JSON.parse(readFileSync(new URL(file, folder), 'utf8'));
const length = text => [...text].length;

test('both store variants identify the brand reading and schedule-sharing purpose within field limits', () => {
  const copy = load('copy.json');
  assert.equal(copy.status, 'draft_not_uploaded');
  assert.equal(copy.recommendedVariant, 'purpose_first');
  assert.equal(copy.variants.length, 2);
  assert.equal(new Set(copy.variants.map(variant => variant.id)).size, 2);
  assert.ok(copy.variants.some(variant => variant.id === copy.recommendedVariant));
  for (const variant of copy.variants) {
    for (const store of ['apple', 'googlePlay']) {
      const metadata = variant[store];
      assert.match(metadata.name, /LaKiite/);
      assert.match(metadata.name, /ラキーテ/);
      assert.match(metadata.name, /予定/);
      assert.ok(length(metadata.name) <= 30);
      assert.ok(length(metadata.description) > 50 && length(metadata.description) <= 4000);
      assert.match(metadata.description, /^LaKiite（ラキーテ）は、友だちと予定を共有できるカレンダーアプリです。/);
      assert.doesNotMatch(metadata.description, /グループ|絶対|必ず|No\.1|ナンバーワン/);
    }
    assert.ok(length(variant.apple.subtitle) > 0 && length(variant.apple.subtitle) <= 30);
    assert.ok(length(variant.apple.promotionalText) <= 170);
    // Keep the Japanese copy below the stricter 40-character localized guidance.
    assert.ok(length(variant.googlePlay.shortDescription) > 0 && length(variant.googlePlay.shortDescription) <= 40);
    assert.match(variant.googlePlay.shortDescription, /予定.*カレンダー/);
    assert.ok(length(variant.googlePlay.description) <= 2000);
    assert.match(variant.apple.description, /リスト/);
    assert.match(variant.googlePlay.description, /リスト/);
    const keywords = variant.apple.keywords.split(',');
    assert.equal(new Set(keywords).size, keywords.length);
    assert.ok(keywords.every(word => word.length > 0 && !/\s/.test(word)));
    assert.ok(Buffer.byteLength(variant.apple.keywords, 'utf8') <= 100);
    assert.ok(keywords.every(word => !(variant.apple.name + variant.apple.subtitle).includes(word)));
  }
});

test('recommended store name is the approved kana-inclusive wording', () => {
  const copy = load('copy.json');
  const selected = copy.variants.find(variant => variant.id === copy.recommendedVariant);
  for (const store of ['apple', 'googlePlay']) {
    assert.equal(selected[store].name, 'LaKiite（ラキーテ）予定共有カレンダー');
  }
});

test('release-note drafts describe user benefits and do not put iOS fixes on Google Play', () => {
  const copy = load('copy.json');
  assert.equal(copy.releaseNotes.status, 'verify_against_target_release_before_upload');
  assert.match(copy.releaseNotes.apple, /招待/);
  assert.match(copy.releaseNotes.googlePlay, /招待/);
  assert.doesNotMatch(copy.releaseNotes.googlePlay, /iOS|iPhone|Airbridge|ディープリンク/);
});

test('seven ordered creative briefs explain purpose, sharing and discovery first', () => {
  const storyboard = load('screenshots.json');
  assert.equal(storyboard.status, 'draft_not_for_submission');
  assert.equal(storyboard.cards.length, 7);
  assert.deepEqual(storyboard.cards.map(card => card.order), [1, 2, 3, 4, 5, 6, 7]);
  assert.deepEqual(storyboard.cards.slice(0, 3).map(card => card.intent), ['purpose', 'share', 'discover']);
  for (const card of storyboard.cards) {
    assert.ok(card.headline && length(card.headline) <= 30);
    assert.equal(card.headlineLines.join(''), card.headline);
    assert.ok(card.headlineLines.every(line => line.length > 0));
    assert.ok(card.message && card.captureBrief);
    assert.equal(card.androidSource, null, 'iPhone assets must not masquerade as Android captures');
    assert.equal(card.requiresRecapture, true);
    if (card.iosReference) {
      assert.ok(card.iosReference.startsWith('../../../../web/images/'));
      assert.ok(existsSync(new URL(card.iosReference, folder)));
    }
  }
});

test('creative previews remain outside Hosting and mark each exported card as non-submittable', () => {
  const html = readFileSync(new URL('preview.html', folder), 'utf8');
  const script = readFileSync(new URL('preview.mjs', folder), 'utf8');
  assert.match(html, /入稿不可/);
  assert.match(html, /<noscript>/);
  assert.match(script, /入稿不可/);
  assert.match(script, /textContent/);
  assert.match(script, /headlineLines/);
  assert.doesNotMatch(script, /innerHTML|outerHTML|eval\(/);
  assert.equal(existsSync(new URL('../web/store-preview.html', import.meta.url)), false);
  for (const resource of ['preview.mjs', 'preview.css']) assert.ok(existsSync(new URL(resource, folder)));
});
