const express = require('express');
const {
  cacheCounts,
  clearCache,
  failCache,
  finishCache,
  getCache,
  hasCatalogData,
  isCacheExpired,
  isCacheValid,
  startCache
} = require('./src/cache');
const { bootstrap, login, normalizeDns, requireCredentials } = require('./src/xtream');
const { isValidSearchType, normalizeText, parseSearchLimit, searchCache } = require('./src/search');
const { getBootstrapStatus, setBootstrapCatalog } = require('./src/bootstrapCatalog');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json({ limit: '1mb' }));

function cacheStatus(entry) {
  return {
    startedAt: entry.startedAt,
    loadedAt: entry.loadedAt,
    updatedAt: entry.updatedAt,
    ready: entry.ready,
    loading: entry.loading
  };
}

function catalogResponse(entry, extra = {}) {
  const counts = cacheCounts(entry);

  return {
    ok: true,
    ready: Boolean(entry.ready),
    loading: Boolean(entry.loading),
    movieCategories: counts.movieCategories,
    movies: counts.movies,
    seriesCategories: counts.seriesCategories,
    series: counts.series,
    startedAt: entry.startedAt,
    loadedAt: entry.loadedAt,
    updatedAt: entry.updatedAt,
    errors: entry.errors || {},
    ...extra
  };
}

function accountLogContext(dns, username) {
  return `dns=${normalizeDns(dns)} username=${username}`;
}

function handleError(res, error) {
  const statusCode = error.statusCode || 500;
  res.status(statusCode).json({
    ok: false,
    error: error.message || 'Erro interno.'
  });
}

function loadCacheInBackground(credentials) {
  const { dns, username } = credentials;
  startCache(dns, username);
  console.log(`[cache] carregamento em andamento ${accountLogContext(dns, username)}`);

  bootstrap(credentials)
    .then((data) => {
      const entry = finishCache(dns, username, data);
      setBootstrapCatalog(entry);
      console.log(`[cache] cache criado ${accountLogContext(dns, username)}`);
    })
    .catch((error) => {
      failCache(dns, username, error);
      console.error(`[cache] erro ao carregar ${accountLogContext(dns, username)}: ${error.message}`);
    });
}

// Endpoint simples para monitoramento de hospedagens como Railway/Fly/VPS.
app.get('/health', (req, res) => {
  res.json({ ok: true });
});

// Valida credenciais diretamente na API Xtream e devolve uma resposta normalizada.
app.post('/api/login', async (req, res) => {
  try {
    const data = await login(req.body);
    res.json(data);
  } catch (error) {
    handleError(res, error);
  }
});

// Carrega o catalogo inicial da API Xtream e guarda em memoria por conta durante a execucao do servidor.
app.post('/api/bootstrap', (req, res) => {
  try {
    requireCredentials(req.body);
    const { dns, username } = req.body;
    const entry = getCache(dns, username);

    if (isCacheValid(entry)) {
      console.log(`[cache] cache usado ${accountLogContext(dns, username)}`);
      return res.json(catalogResponse(entry, { source: 'cache' }));
    }

    if (entry?.loading) {
      console.log(`[cache] carregamento em andamento ${accountLogContext(dns, username)}`);
      return res.json(catalogResponse(entry, { status: 'loading' }));
    }

    if (entry && isCacheExpired(entry)) {
      console.log(`[cache] cache expirado ${accountLogContext(dns, username)}`);
      loadCacheInBackground(req.body);

      if (hasCatalogData(entry)) {
        return res.json(catalogResponse(entry, { expired: true, refreshing: true, source: 'stale-cache' }));
      }

      return res.json(catalogResponse(getCache(dns, username), { status: 'loading' }));
    }

    loadCacheInBackground(req.body);
    return res.json(catalogResponse(getCache(dns, username), { status: 'loading' }));
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/bootstrap/status', (_req, res) => {
  res.json(getBootstrapStatus());
});

app.get('/api/cache/status', (req, res) => {
  const { dns, username } = req.query;

  try {
    requireCredentials({ dns, username }, false);
    const entry = getCache(dns, username);

    res.json({
      ok: true,
      exists: Boolean(entry),
      ready: Boolean(entry?.ready),
      loading: Boolean(entry?.loading),
      counts: cacheCounts(entry),
      loadedAt: entry?.loadedAt || null,
      updatedAt: entry?.updatedAt || null
    });
  } catch (error) {
    handleError(res, error);
  }
});

// Pesquisa global somente no cache completo ja carregado, sem chamar a API Xtream novamente.
app.post('/api/search', (req, res) => {
  const { dns, username, query, type = 'all', limit } = req.body;

  try {
    requireCredentials({ dns, username }, false);

    if (!isValidSearchType(type)) {
      return res.status(400).json({ ok: false, error: 'type deve ser movies, series ou all.' });
    }

    const entry = getCache(dns, username);

    if (!entry || !entry.ready || !entry.searchIndex) {
      return res.status(404).json({ ok: false, error: 'cache_not_ready' });
    }

    const normalizedType = String(type || 'all').toLowerCase();
    const normalizedQuery = normalizeText(query);
    const boundedLimit = parseSearchLimit(limit);
    const results = searchCache(entry, normalizedQuery, normalizedType, boundedLimit);

    res.json({
      ok: true,
      query: normalizedQuery,
      type: normalizedType,
      limit: boundedLimit,
      count: results.length,
      results
    });
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/search/status', (req, res) => {
  const { dns, username } = req.query;

  try {
    requireCredentials({ dns, username }, false);
    const entry = getCache(dns, username);
    const counts = cacheCounts(entry);

    res.json({
      ok: true,
      exists: Boolean(entry),
      ready: Boolean(entry?.ready),
      loading: Boolean(entry?.loading),
      searchable: Boolean(entry?.ready && (counts.movies || counts.series)),
      counts,
      loadedAt: entry?.loadedAt || null,
      updatedAt: entry?.updatedAt || null
    });
  } catch (error) {
    handleError(res, error);
  }
});

// Remove dados em memoria de uma conta especifica.
app.post('/api/cache/clear', (req, res) => {
  const { dns, username } = req.body;

  try {
    requireCredentials({ dns, username }, false);
    const cleared = clearCache(dns, username);
    console.log(`[cache] cache limpo ${accountLogContext(dns, username)}`);
    res.json({ ok: true, cleared });
  } catch (error) {
    handleError(res, error);
  }
});

app.listen(port, () => {
  console.log(`PXT Player backend ouvindo na porta ${port}`);
});
