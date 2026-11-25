// ShiftFit offline support: the app always loads, even with no signal.
// App files: try the network first (so updates show up), fall back to the saved copy.
// Fonts and recipe photos: use the saved copy if there is one.
const APP = 'shiftfit-app-v1';
const MEDIA = 'shiftfit-media-v1';
const CORE = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(APP).then(c => c.addAll(CORE)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(
    keys.filter(k => k !== APP && k !== MEDIA).map(k => caches.delete(k)))));
  self.clients.claim();
});

async function trimMedia(max) {
  const c = await caches.open(MEDIA);
  const keys = await c.keys();
  for (let i = 0; i < keys.length - max; i++) await c.delete(keys[i]);
}

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (url.origin === self.location.origin) {
    e.respondWith(
      fetch(req).then(res => {
        if (res.ok) { const copy = res.clone(); caches.open(APP).then(c => c.put(req, copy)); }
        return res;
      }).catch(() => caches.match(req).then(r => r || caches.match('./index.html')))
    );
    return;
  }

  if (/fonts\.(googleapis|gstatic)\.com|themealdb\.com\/images|img\.spoonacular\.com/.test(url.hostname + url.pathname)) {
    e.respondWith(caches.open(MEDIA).then(c => c.match(req).then(hit => hit || fetch(req).then(res => {
      if (res.ok || res.type === 'opaque') { c.put(req, res.clone()); trimMedia(300); }
      return res;
    }))));
  }
});
