const decks = [...document.querySelectorAll('.deck')];

async function loadConfig() {
  const response = await fetch('/api/config');
  const payload = await response.json();
  document.getElementById('portal-meta').textContent =
    `仓库 ${payload.repoKey} · Firmware 前缀 ${payload.areas.firmware} · Patch 前缀 ${payload.areas.patch}`;
}

function renderList(listElement, area, currentPath, files) {
  listElement.innerHTML = '';

  if (currentPath) {
    const up = document.createElement('li');
    const upButton = document.createElement('button');
    upButton.textContent = '返回上一级';
    upButton.className = 'link';
    upButton.addEventListener('click', () => {
      const segments = currentPath.split('/').filter(Boolean);
      segments.pop();
      const nextPath = segments.join('/');
      const deck = listElement.closest('.deck');
      deck.querySelector('[data-role="path"]').value = nextPath;
      void refreshDeck(deck);
    });
    up.appendChild(upButton);
    listElement.appendChild(up);
  }

  if (!files.length) {
    const empty = document.createElement('li');
    empty.textContent = '当前目录为空';
    listElement.appendChild(empty);
    return;
  }

  for (const item of files) {
    const li = document.createElement('li');
    if (item.folder) {
      const button = document.createElement('button');
      button.className = 'link';
      button.textContent = `📁 ${item.uri.replace(/^\//, '')}`;
      button.addEventListener('click', () => {
        const name = item.uri.replace(/^\//, '');
        const nextPath = [currentPath, name].filter(Boolean).join('/');
        const deck = listElement.closest('.deck');
        deck.querySelector('[data-role="path"]').value = nextPath;
        void refreshDeck(deck);
      });
      li.appendChild(button);
    } else {
      const filename = item.uri.replace(/^\//, '');
      const link = document.createElement('a');
      link.href = `/api/download?area=${encodeURIComponent(area)}&path=${encodeURIComponent(currentPath)}&filename=${encodeURIComponent(filename)}`;
      link.textContent = `⬇ ${filename}`;
      li.appendChild(link);
      const meta = document.createElement('span');
      meta.textContent = ` ${item.size ? `· ${item.size} bytes` : ''}${item.lastModified ? ` · ${item.lastModified}` : ''}`;
      li.appendChild(meta);
    }
    listElement.appendChild(li);
  }
}

async function refreshDeck(deck) {
  const area = deck.dataset.area;
  const pathInput = deck.querySelector('[data-role="path"]');
  const status = deck.querySelector('[data-role="status"]');
  const listElement = deck.querySelector('[data-role="list"]');
  status.textContent = '正在读取目录…';
  const response = await fetch(`/api/list?area=${encodeURIComponent(area)}&path=${encodeURIComponent(pathInput.value)}`);
  const payload = await response.json();
  if (!response.ok) {
    status.textContent = payload.error || '目录读取失败';
    return;
  }
  renderList(listElement, area, payload.path, payload.files || []);
  status.textContent = '目录已刷新';
}

async function uploadFromDeck(deck) {
  const area = deck.dataset.area;
  const pathInput = deck.querySelector('[data-role="path"]');
  const fileInput = deck.querySelector('[data-role="file"]');
  const status = deck.querySelector('[data-role="status"]');
  const file = fileInput.files[0];
  if (!file) {
    status.textContent = '请先选择文件';
    return;
  }

  status.textContent = `正在上传 ${file.name} …`;
  const response = await fetch(
    `/api/upload?area=${encodeURIComponent(area)}&path=${encodeURIComponent(pathInput.value)}&filename=${encodeURIComponent(file.name)}`,
    {
      method: 'PUT',
      headers: {
        'Content-Type': file.type || 'application/octet-stream',
      },
      body: file,
    },
  );
  const payload = await response.json();
  if (!response.ok) {
    status.textContent = payload.error || '上传失败';
    return;
  }
  status.textContent = `${file.name} 上传完成`;
  fileInput.value = '';
  await refreshDeck(deck);
}

function wireDeck(deck) {
  deck.querySelector('[data-action="refresh"]').addEventListener('click', () => {
    void refreshDeck(deck);
  });
  deck.querySelector('[data-action="upload"]').addEventListener('click', () => {
    void uploadFromDeck(deck);
  });
}

for (const deck of decks) {
  wireDeck(deck);
}

void loadConfig();
void Promise.all(decks.map((deck) => refreshDeck(deck)));

