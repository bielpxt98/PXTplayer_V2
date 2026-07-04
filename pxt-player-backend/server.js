const express = require('express');
const { clearCache, getCache, setCache, startCache } = require('./src/cache');
const { bootstrap, login, requireCredentials } = require('./src/xtream');
const { isValidSearchType, searchCache } = require('./src/search');

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
    error: error.message || 'Erro interno.'
  });
}

// Endpoint simples para monitoramento de hospedagens como Railway/Fly/VPS.
app.get('/health', (req, res) => {
  res.json({ ok: true });
});

// Valida credenciais diretamente na API Xtream e devolve a resposta original.
app.post('/api/login', async (req, res) => {
  try {
    const data = await login(req.body);
    res.json(data);
  } catch (error) {
    handleError(res, error);
  }
});

// Carrega os catalogos principais em paralelo e guarda tudo em memoria por conta.
app.post('/api/bootstrap', async (req, res) => {
  const { dns, username } = req.body;

  try {
    requireCredentials(req.body);
    startCache(dns, username);

    const data = await bootstrap(req.body);
    const entry = setCache(dns, username, {
      ...data,
      ready: true
    });

    res.json({
      movieCategories: entry.movieCategories,
      seriesCategories: entry.seriesCategories,
      firstMovies: entry.movies.slice(0, 50),
      firstSeries: entry.series.slice(0, 50),
      cache: cacheStatus(entry)
    });
  } catch (error) {
    if (dns && username) {
      setCache(dns, username, { ready: false });
    }

    handleError(res, error);
  }
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
