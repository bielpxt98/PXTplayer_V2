const LOGIN_TIMEOUT_MS = 10000;
const REQUIRED_LOGIN_ERROR = 'dns, username and password are required';

function createHttpError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function normalizeDns(dns) {
  const trimmed = String(dns || '').trim().replace(/\/+$/, '');

  if (!trimmed) {
    return '';
  }

  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed;
  }

  return `http://${trimmed}`;
}

function requireCredentials({ dns, username, password } = {}, includePassword = true) {
  if (!dns || !username || (includePassword && !password)) {
    if (includePassword) {
      throw createHttpError(REQUIRED_LOGIN_ERROR, 400);
    }

    throw createHttpError('dns and username are required', 400);
  }
}

function buildPlayerApiUrl({ dns, username, password, action }) {
  const baseDns = normalizeDns(dns);

  try {
    const url = new URL(`${baseDns}/player_api.php`);

    if (!['http:', 'https:'].includes(url.protocol) || !url.hostname) {
      throw new Error('Unsupported protocol or hostname.');
    }

    url.searchParams.set('username', username);
    url.searchParams.set('password', password);

    if (action) {
      url.searchParams.set('action', action);
    }

    return url;
  } catch (_error) {
    throw createHttpError('Invalid DNS. Use a valid host with http:// or https://.', 400);
  }
}

function logSafeLoginStart(dns, username) {
  console.log(`[login] starting attempt for dns=${normalizeDns(dns)} username=${username}`);
}

function logSafeLoginSuccess(dns, username) {
  console.log(`[login] success for dns=${normalizeDns(dns)} username=${username}`);
}

function logSafeLoginError(dns, username, message) {
  console.error(`[login] error for dns=${normalizeDns(dns)} username=${username}: ${message}`);
}

async function parseJsonResponse(response) {
  const text = await response.text();

  try {
    return JSON.parse(text);
  } catch (_error) {
    throw createHttpError('Xtream server returned a non-JSON response.', 502);
  }
}

async function fetchXtreamJson(credentials, action, timeoutMs = LOGIN_TIMEOUT_MS) {
  const url = buildPlayerApiUrl({ ...credentials, action });
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });

    if (!response.ok) {
      throw createHttpError(`Xtream server responded with HTTP ${response.status}.`, 502);
    }

    return parseJsonResponse(response);
  } catch (error) {
    if (error.name === 'AbortError') {
      throw createHttpError('Xtream server did not respond within 10 seconds.', 504);
    }

    if (error.statusCode) {
      throw error;
    }

    throw createHttpError('Unable to connect to the Xtream server. Check the DNS and try again.', 502);
  } finally {
    clearTimeout(timeout);
  }
}

function normalizeAccount(userInfo = {}) {
  return {
    username: userInfo.username,
    status: userInfo.status,
    exp_date: userInfo.exp_date,
    is_trial: userInfo.is_trial,
    active_cons: userInfo.active_cons,
    max_connections: userInfo.max_connections
  };
}

function normalizeServer(serverInfo = {}) {
  return {
    url: serverInfo.url,
    port: serverInfo.port,
    https_port: serverInfo.https_port,
    server_protocol: serverInfo.server_protocol
  };
}

function normalizeLoginResponse(data) {
  const userInfo = data && data.user_info;
  const serverInfo = data && data.server_info;

  if (!userInfo || typeof userInfo !== 'object') {
    throw createHttpError('Invalid username or password.', 401);
  }

  if (userInfo.auth === 0 || userInfo.auth === '0') {
    throw createHttpError('Invalid username or password.', 401);
  }

  if (userInfo.status !== 'Active') {
    throw createHttpError(`Account status is ${userInfo.status || 'not Active'}.`, 403);
  }

  return {
    ok: true,
    account: normalizeAccount(userInfo),
    server: normalizeServer(serverInfo)
  };
}

async function login(credentials) {
  requireCredentials(credentials);
  logSafeLoginStart(credentials.dns, credentials.username);

  try {
    const data = await fetchXtreamJson(credentials);
    const normalized = normalizeLoginResponse(data);
    logSafeLoginSuccess(credentials.dns, credentials.username);
    return normalized;
  } catch (error) {
    logSafeLoginError(credentials.dns, credentials.username, error.message || 'Unknown error');
    throw error;
  }
}


function normalizeList(value) {
  return Array.isArray(value) ? value : [];
}

function resultError(result) {
  if (result.status !== 'rejected') {
    return null;
  }

  return result.reason?.message || 'Erro ao carregar dados da API Xtream.';
}

async function loadGroup(groupName, credentials, actions) {
  console.log(`[bootstrap] carregando ${groupName}`);

  return Promise.allSettled(actions.map((action) => fetchXtreamJson(credentials, action)));
}

async function bootstrap(credentials) {
  requireCredentials(credentials);

  console.log('[bootstrap] iniciando bootstrap');
  const startedAt = Date.now();

  const [movieResults, seriesResults] = await Promise.all([
    loadGroup('filmes', credentials, ['get_vod_categories', 'get_vod_streams']),
    loadGroup('séries', credentials, ['get_series_categories', 'get_series'])
  ]);

  const [movieCategoriesResult, moviesResult] = movieResults;
  const [seriesCategoriesResult, seriesResult] = seriesResults;

  const errors = {};

  const movieCategoriesError = resultError(movieCategoriesResult);
  const moviesError = resultError(moviesResult);
  const seriesCategoriesError = resultError(seriesCategoriesResult);
  const seriesError = resultError(seriesResult);

  if (movieCategoriesError) errors.movieCategories = movieCategoriesError;
  if (moviesError) errors.movies = moviesError;
  if (seriesCategoriesError) errors.seriesCategories = seriesCategoriesError;
  if (seriesError) errors.series = seriesError;

  const loadedAt = new Date().toISOString();
  const loadTimeMs = Date.now() - startedAt;
  const ready = Object.keys(errors).length === 0;

  console.log(`[bootstrap] bootstrap concluído em ${loadTimeMs}ms`);
  console.log(`[bootstrap] tempo total: ${loadTimeMs}ms`);

  return {
    movieCategories: movieCategoriesResult.status === 'fulfilled' ? normalizeList(movieCategoriesResult.value) : [],
    movies: moviesResult.status === 'fulfilled' ? normalizeList(moviesResult.value) : [],
    seriesCategories: seriesCategoriesResult.status === 'fulfilled' ? normalizeList(seriesCategoriesResult.value) : [],
    series: seriesResult.status === 'fulfilled' ? normalizeList(seriesResult.value) : [],
    loadedAt,
    loadTimeMs,
    ready,
    errors
  };
}

module.exports = {
  normalizeDns,
  requireCredentials,
  login,
  bootstrap
};
