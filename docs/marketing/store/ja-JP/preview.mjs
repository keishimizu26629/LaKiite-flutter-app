const container = document.querySelector('#cards');
const status = document.querySelector('#status');

function element(tag, className, text) {
  const node = document.createElement(tag);
  node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

async function render() {
  const response = await fetch(new URL('screenshots.json', import.meta.url));
  if (!response.ok) throw new Error('Storyboards unavailable');
  const storyboard = await response.json();
  for (const card of storyboard.cards) {
    const article = element('article', 'creative');
    article.id = `card-${card.order}`;
    const artboard = element('div', 'artboard');
    const copy = element('div', 'card-copy');
    const brand = element('p', 'brand', storyboard.brand);
    brand.append(element('span', 'card-number', String(card.order).padStart(2, '0')));
    const headline = element('h2', '');
    for (const line of card.headlineLines) headline.append(element('span', 'headline-line', line));
    copy.append(brand, headline, element('p', 'message', card.message));
    const visual = element('div', 'visual');
    if (card.iosReference) {
      const image = element('img', '');
      image.src = new URL(card.iosReference, import.meta.url).href;
      image.alt = `旧LPのiOS参考画像：${card.headline}。対象リリースでの再撮影が必要です。`;
      image.addEventListener('error', () => {
        visual.replaceChildren(element('p', 'placeholder', '参考画像を読み込めません。撮影指示を確認してください。'));
      }, { once: true });
      visual.append(image);
    } else {
      visual.append(element('p', 'placeholder', '実機画面の再撮影が必要\n架空のUIは作成しません'));
    }
    artboard.append(copy, visual, element('p', 'draft', '構成案・入稿不可 / iOS参考・Android未撮影'));
    article.append(artboard, element('p', 'brief source', '両OSとも要再撮影。既存画像は現行版の動作を証明しません。'), element('p', 'brief', card.captureBrief));
    container.append(article);
  }
  status.textContent = `${storyboard.cards.length}枚の構成案を表示しています。公開・入稿はしていません。`;
}

render().catch(() => {
  container.replaceChildren();
  status.textContent = '構成案を読み込めません。READMEのローカル起動手順で開き直すか、screenshots.jsonを確認してください。';
});
