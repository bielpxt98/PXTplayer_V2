const express = require('express');
const { clearCache, getCache } = require('./src/cache');
const { bootstrap, login, requireCredentials } = require('./src/xtream');
const { isValidSearchType, searchCache } = require('./src/search');
const { getBootstrapStatus, setBootstrapCatalog } = require('./src/bootstrapCatalog');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json({ limit: '1mb' }));

function cacheStatus(entry) {
  return {
    startedAt: entry.startedAt,
    updatedAt: entry.updatedAt,
    ready: entry.ready
  };
}

function handleError(res, error) {
  const statusCode = error.statusCode || 500;
  res.status(statusCode).json({
    ok: false,
    error: error.message || 'Erro interno.'
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

// Carrega o catalogo inicial da API Xtream e guarda em memoria durante a execucao do servidor.
app.post('/api/bootstrap', async (req, res) => {
  try {
    requireCredentials(req.body);

    const data = await bootstrap(req.body);
    const catalog = setBootstrapCatalog(data);

    res.json({
      ok: true,
      ready: catalog.ready,
      movieCategories: catalog.movieCategories.length,
      movies: catalog.movies.length,
      seriesCategories: catalog.seriesCategories.length,
      series: catalog.series.length,
      loadedAt: catalog.loadedAt,
      loadTimeMs: data.loadTimeMs,
      errors: catalog.errors
    });
  } catch (error) {
    handleError(res, error);
  }
});

app.get('/api/bootstrap/status', (_req, res) => {
  res.json(getBootstrapStatus());
});

// Pesquisa somente no cache ja carregado, sem chamar a API Xtream novamente.
app.post('/api/search', (req, res) => {
  const { dns, username, query, type = 'all' } = req.body;

  try {
    requireCredentials({ dns, username }, false);

    if (!isValidSearchType(type)) {
      return res.status(400).json({ error: 'type deve ser movies, series ou all.' });
    }

    const entry = getCache(dns, username);

    if (!entry || !entry.ready) {
      return res.status(404).json({ error: 'Cache nao encontrado ou ainda nao carregado.' });
    }

    res.json({
      results: searchCache(entry, query, type, 50),
      cache: cacheStatus(entry)
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
    res.json({ cleared });
  } catch (error) {
    handleError(res, error);
  }
});

app.listen(port, () => {
  console.log(`PXT Player backend ouvindo na porta ${port}`);
});
