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

function requireCredentials({ dns, username, password }, includePassword = true) {
  if (!dns || !username || (includePassword && !password)) {
    const fields = includePassword ? 'dns, username e password' : 'dns e username';
    const error = new Error(`Informe ${fields}.`);
    error.statusCode = 400;
    throw error;
  }
}

function buildPlayerApiUrl({ dns, username, password, action }) {
  const baseDns = normalizeDns(dns);
  const url = new URL(`${baseDns}/player_api.php`);

  url.searchParams.set('username', username);
  url.searchParams.set('password', password);

  if (action) {
    url.searchParams.set('action', action);
  }

  return url;
}

async function fetchXtreamJson(credentials, action) {
  const url = buildPlayerApiUrl({ ...credentials, action });
  const response = await fetch(url);

  if (!response.ok) {
    const error = new Error(`Xtream API respondeu com status ${response.status}.`);
    error.statusCode = response.status;
    throw error;
  }

  return response.json();
}

async function login(credentials) {
  requireCredentials(credentials);
  return fetchXtreamJson(credentials);
}

async function bootstrap(credentials) {
  requireCredentials(credentials);

  const [movieCategories, seriesCategories, movies, series] = await Promise.all([
    fetchXtreamJson(credentials, 'get_vod_categories'),
    fetchXtreamJson(credentials, 'get_series_categories'),
    fetchXtreamJson(credentials, 'get_vod_streams'),
    fetchXtreamJson(credentials, 'get_series')
  ]);

  return {
    movieCategories: Array.isArray(movieCategories) ? movieCategories : [],
    seriesCategories: Array.isArray(seriesCategories) ? seriesCategories : [],
    movies: Array.isArray(movies) ? movies : [],
    series: Array.isArray(series) ? series : []
  };
}

module.exports = {
  normalizeDns,
  requireCredentials,
  login,
  bootstrap
};
