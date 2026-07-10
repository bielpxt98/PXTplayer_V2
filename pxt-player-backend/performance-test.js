#!/usr/bin/env node
const http = require('http');
const { spawn } = require('child_process');
const { once } = require('events');

const BACKEND_PORT = Number(process.env.PERFORMANCE_BACKEND_PORT || 3100);
const MOCK_PORT = Number(process.env.PERFORMANCE_MOCK_PORT || 3200);
const SEARCH_QUERIES = ['mock movie 1', 'movie 199', 'serie 99', 'ação', 'drama'];

function makeCategories(prefix, count) {
  return Array.from({ length: count }, (_, i) => ({ category_id: String(i + 1), category_name: `${prefix} ${i + 1}` }));
}

function makeMovies(total = 20000) {
  return Array.from({ length: total }, (_, i) => ({
    stream_id: i + 1,
    name: `Mock Movie ${i + 1} ${i % 7 === 0 ? 'Ação' : 'Drama'}`,
    title: `Movie Title ${i + 1}`,
    stream_name: `Stream Movie ${i + 1}`,
    stream_icon: `https://img.example/movie-${i + 1}.jpg`,
    category_id: String((i % 20) + 1),
    year: String(1980 + (i % 45)),
    container_extension: i % 2 === 0 ? 'mp4' : 'mkv'
  }));
}

function makeLiveChannels(total = 1200) {
  return Array.from({ length: total }, (_, i) => ({
    stream_id: i + 1,
    name: `Mock Channel ${i + 1}`,
    stream_icon: `https://img.example/live-${i + 1}.jpg`,
    category_id: String((i % 8) + 1),
    container_extension: 'm3u8'
  }));
}

function makeSeries(total = 10000) {
  return Array.from({ length: total }, (_, i) => ({
    series_id: i + 1,
    name: `Mock Serie ${i + 1} ${i % 5 === 0 ? 'Comédia' : 'Drama'}`,
    title: `Serie Title ${i + 1}`,
    stream_name: `Stream Serie ${i + 1}`,
    cover: `https://img.example/series-${i + 1}.jpg`,
    category_id: String((i % 12) + 1),
    releaseDate: `${1990 + (i % 35)}-01-01`
  }));
}

async function postJson(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body)
  });
  return response.json();
}

async function getJson(url) {
  const response = await fetch(url);
  return response.json();
}

function createMockXtreamServer() {
  const catalogs = {
    get_vod_categories: makeCategories('Filmes', 20),
    get_vod_streams: makeMovies(),
    get_series_categories: makeCategories('Séries', 12),
    get_series: makeSeries(),
    get_live_categories: makeCategories('Live', 8),
    get_live_streams: makeLiveChannels()
  };

  return http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    if (url.pathname !== '/player_api.php') {
      res.writeHead(404).end();
      return;
    }

    const action = url.searchParams.get('action');
    const payload = action
      ? catalogs[action] || []
      : { user_info: { auth: 1, username: 'mock', status: 'Active' }, server_info: { url: 'localhost' } };

    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify(payload));
  });
}

async function waitForBackend(baseUrl) {
  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    try {
      const health = await getJson(`${baseUrl}/health`);
      if (health.ok) return;
    } catch (_error) {}
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error('Backend did not start in time.');
}

async function waitForCache(baseUrl, dns, username) {
  const deadline = Date.now() + 60000;
  while (Date.now() < deadline) {
    const status = await getJson(`${baseUrl}/api/cache/status?dns=${encodeURIComponent(dns)}&username=${encodeURIComponent(username)}`);
    if (status.ready) return status;
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error('Cache did not become ready in time.');
}

async function main() {
  const useRealXtream = Boolean(process.env.XTREAM_DNS && process.env.XTREAM_USERNAME && process.env.XTREAM_PASSWORD);
  const mockServer = useRealXtream ? null : createMockXtreamServer();
  if (mockServer) {
    mockServer.listen(MOCK_PORT);
    await once(mockServer, 'listening');
  }

  const mockDns = `http://127.0.0.1:${MOCK_PORT}`;
  const backendEnv = {
    ...process.env,
    PORT: String(BACKEND_PORT)
  };

  // Em modo mock, libera temporariamente o DNS local (produção fica trancada em ttvp2.live).
  if (!useRealXtream) {
    backendEnv.ALLOWED_DNS_HOST = '127.0.0.1';
    backendEnv.ALLOWED_DNS = mockDns;
  }

  const backend = spawn(process.execPath, ['server.js'], {
    cwd: process.cwd(),
    env: backendEnv,
    stdio: ['ignore', 'pipe', 'pipe']
  });

  backend.stdout.on('data', (chunk) => process.stderr.write(chunk));
  backend.stderr.on('data', (chunk) => process.stderr.write(chunk));

  const baseUrl = `http://127.0.0.1:${BACKEND_PORT}`;
  const credentials = {
    dns: useRealXtream ? process.env.XTREAM_DNS : mockDns,
    username: useRealXtream ? process.env.XTREAM_USERNAME : 'mock-user',
    password: useRealXtream ? process.env.XTREAM_PASSWORD : 'mock-password'
  };

  try {
    await waitForBackend(baseUrl);
    const bootstrapStarted = performance.now();
    await postJson(`${baseUrl}/api/bootstrap`, credentials);
    const status = await waitForCache(baseUrl, credentials.dns, credentials.username);
    const bootstrapTimeMs = Math.round(performance.now() - bootstrapStarted);

    const searchTimes = [];
    for (const query of SEARCH_QUERIES) {
      const started = performance.now();
      await postJson(`${baseUrl}/api/search`, {
        dns: credentials.dns,
        username: credentials.username,
        query,
        type: 'all',
        limit: 50
      });
      searchTimes.push(performance.now() - started);
    }

    const memoryUsageMb = Math.round((process.memoryUsage().rss / 1024 / 1024) * 100) / 100;
    const liveCatalog = await postJson(`${baseUrl}/api/catalog/live`, {
      dns: credentials.dns,
      username: credentials.username,
      category_id: '1',
      limit: 50
    });

    const report = {
      bootstrapTimeMs,
      movies: status.counts?.movies || 0,
      series: status.counts?.series || 0,
      liveCategories: status.counts?.liveCategories || 0,
      liveChannels: status.counts?.liveChannels || 0,
      liveCategoryItems: liveCatalog.count || 0,
      cacheReady: Boolean(status.ready),
      averageSearchMs: Math.round((searchTimes.reduce((sum, value) => sum + value, 0) / searchTimes.length) * 100) / 100,
      memoryUsageMb
    };

    console.log(JSON.stringify(report, null, 2));
  } finally {
    backend.kill('SIGTERM');
    if (mockServer) mockServer.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
