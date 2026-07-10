const LOGIN_TIMEOUT_MS = 10000;
const STREAM_TIMEOUT_MS = 15000;
const REQUIRED_LOGIN_ERROR = 'dns, username and password are required';

// Backend trancado para um unico servidor Xtream (override via env se necessario).
const ALLOWED_DNS_HOST = String(process.env.ALLOWED_DNS_HOST || 'ttvp2.live')
  .trim()
  .toLowerCase()
  .replace(/^www\./, '');
const CANONICAL_DNS = String(process.env.ALLOWED_DNS || 'http://ttvp2.live')
  .trim()
  .replace(/\/+$/, '');
const DNS_NOT_ALLOWED_ERROR = `DNS não permitido. Este backend só funciona com ${CANONICAL_DNS}.`;

function createHttpError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function extractHostname(dns) {
  const trimmed = String(dns || '').trim().replace(/\/+$/, '');

  if (!trimmed) {
    return '';
  }

  try {
    const withProtocol = /^https?:\/\//i.test(trimmed) ? trimmed : `http://${trimmed}`;
    return new URL(withProtocol).hostname.toLowerCase().replace(/^www\./, '');
  } catch (_error) {
    return '';
  }
}

function isAllowedDns(dns) {
  const host = extractHostname(dns);
  return Boolean(host) && host === ALLOWED_DNS_HOST;
}

function assertAllowedDns(dns) {
  if (!isAllowedDns(dns)) {
    throw createHttpError(DNS_NOT_ALLOWED_ERROR, 403);
  }
}

function normalizeDns(dns) {
  const trimmed = String(dns || '').trim().replace(/\/+$/, '');

  if (!trimmed) {
    return '';
  }

  // Qualquer variação válida de ttvp2.live vira o DNS canônico.
  if (isAllowedDns(trimmed)) {
    return CANONICAL_DNS;
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

  assertAllowedDns(dns);
}

function buildPlayerApiUrl({ dns, username, password, action }) {
  assertAllowedDns(dns);
  // Sempre chama o Xtream no DNS fixo do provedor.
  const baseDns = CANONICAL_DNS;

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
  } catch (error) {
    if (error.statusCode) {
      throw error;
    }

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

function resolveXtreamTimeout(action, timeoutMs) {
  if (Number.isFinite(timeoutMs) && timeoutMs > 0) {
    return timeoutMs;
  }

  if (action === 'get_live_streams' || action === 'get_vod_streams' || action === 'get_series') {
    return STREAM_TIMEOUT_MS;
  }

  return LOGIN_TIMEOUT_MS;
}

async function fetchXtreamJson(credentials, action, timeoutMs) {
  const effectiveTimeout = resolveXtreamTimeout(action, timeoutMs);
  const url = buildPlayerApiUrl({ ...credentials, action });
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), effectiveTimeout);

  try {
    const response = await fetch(url, { signal: controller.signal });

    if (!response.ok) {
      throw createHttpError(`Xtream server responded with HTTP ${response.status}.`, 502);
    }

    return parseJsonResponse(response);
  } catch (error) {
    if (error.name === 'AbortError') {
      throw createHttpError(`Xtream server did not respond within ${effectiveTimeout / 1000} seconds.`, 504);
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

  const [movieResults, seriesResults, liveResults] = await Promise.all([
    loadGroup('filmes', credentials, ['get_vod_categories', 'get_vod_streams']),
    loadGroup('séries', credentials, ['get_series_categories', 'get_series']),
    loadGroup('live', credentials, ['get_live_categories', 'get_live_streams'])
  ]);

  const [movieCategoriesResult, moviesResult] = movieResults;
  const [seriesCategoriesResult, seriesResult] = seriesResults;
  const [liveCategoriesResult, liveChannelsResult] = liveResults;

  const errors = {};

  const movieCategoriesError = resultError(movieCategoriesResult);
  const moviesError = resultError(moviesResult);
  const seriesCategoriesError = resultError(seriesCategoriesResult);
  const seriesError = resultError(seriesResult);
  const liveCategoriesError = resultError(liveCategoriesResult);
  const liveChannelsError = resultError(liveChannelsResult);

  if (movieCategoriesError) errors.movieCategories = movieCategoriesError;
  if (moviesError) errors.movies = moviesError;
  if (seriesCategoriesError) errors.seriesCategories = seriesCategoriesError;
  if (seriesError) errors.series = seriesError;
  if (liveCategoriesError) errors.liveCategories = liveCategoriesError;
  if (liveChannelsError) errors.liveChannels = liveChannelsError;

  const loadedAt = new Date().toISOString();
  const loadTimeMs = Date.now() - startedAt;
  const requiredKeys = ['movieCategories', 'movies', 'seriesCategories', 'series'];
  const ready = requiredKeys.every((key) => !errors[key]);

  console.log(`[bootstrap] bootstrap concluído em ${loadTimeMs}ms`);
  console.log(`[bootstrap] tempo total: ${loadTimeMs}ms`);

  return {
    movieCategories: movieCategoriesResult.status === 'fulfilled' ? normalizeList(movieCategoriesResult.value) : [],
    movies: moviesResult.status === 'fulfilled' ? normalizeList(moviesResult.value) : [],
    seriesCategories: seriesCategoriesResult.status === 'fulfilled' ? normalizeList(seriesCategoriesResult.value) : [],
    series: seriesResult.status === 'fulfilled' ? normalizeList(seriesResult.value) : [],
    liveCategories: liveCategoriesResult.status === 'fulfilled' ? normalizeList(liveCategoriesResult.value) : [],
    liveChannels: liveChannelsResult.status === 'fulfilled' ? normalizeList(liveChannelsResult.value) : [],
    loadedAt,
    loadTimeMs,
    ready,
    errors
  };
}

module.exports = {
  ALLOWED_DNS_HOST,
  CANONICAL_DNS,
  normalizeDns,
  isAllowedDns,
  assertAllowedDns,
  requireCredentials,
  login,
  bootstrap
};
