// Cache simples em memoria por conta Xtream. Nao persiste senhas, tokens ou dados em disco.
const CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const accounts = new Map();

function normalizeCacheDns(dns) {
  const trimmed = String(dns || '').trim().replace(/\/+$/, '');

  if (!trimmed) {
    return '';
  }

  return /^https?:\/\//i.test(trimmed) ? trimmed : `http://${trimmed}`;
}

function buildAccountKey(dns, username) {
  return `${normalizeCacheDns(dns)}::${String(username || '').trim()}`;
}

function nowIso() {
  return new Date().toISOString();
}

function createEntry(data = {}) {
  const now = nowIso();

  return {
    movieCategories: [],
    movies: [],
    seriesCategories: [],
    series: [],
    startedAt: now,
    loadedAt: null,
    updatedAt: now,
    ready: false,
    loading: false,
    errors: {},
    ...data
  };
}

function count(value) {
  return Array.isArray(value) ? value.length : 0;
}

function hasCatalogData(entry) {
  return Boolean(
    entry &&
      (count(entry.movieCategories) || count(entry.movies) || count(entry.seriesCategories) || count(entry.series))
  );
}

function isCacheExpired(entry, ttlMs = CACHE_TTL_MS) {
  if (!entry || !entry.loadedAt) {
    return true;
  }

  return Date.now() - new Date(entry.loadedAt).getTime() > ttlMs;
}

function isCacheValid(entry, ttlMs = CACHE_TTL_MS) {
  return Boolean(entry && entry.ready && !isCacheExpired(entry, ttlMs));
}

function getCache(dns, username) {
  return accounts.get(buildAccountKey(dns, username));
}

function setCache(dns, username, data) {
  const key = buildAccountKey(dns, username);
  const current = accounts.get(key) || createEntry();
  const next = {
    ...current,
    ...data,
    updatedAt: nowIso()
  };

  accounts.set(key, next);
  return next;
}

function startCache(dns, username) {
  const key = buildAccountKey(dns, username);
  const current = accounts.get(key);
  const now = nowIso();
  const entry = current
    ? {
        ...current,
        startedAt: now,
        updatedAt: now,
        loading: true,
        errors: current.errors || {}
      }
    : createEntry({ startedAt: now, updatedAt: now, loading: true });

  accounts.set(key, entry);
  return entry;
}

function finishCache(dns, username, data) {
  return setCache(dns, username, {
    movieCategories: Array.isArray(data.movieCategories) ? data.movieCategories : [],
    movies: Array.isArray(data.movies) ? data.movies : [],
    seriesCategories: Array.isArray(data.seriesCategories) ? data.seriesCategories : [],
    series: Array.isArray(data.series) ? data.series : [],
    loadedAt: data.loadedAt || nowIso(),
    ready: Boolean(data.ready),
    loading: false,
    errors: data.errors || {}
  });
}

function failCache(dns, username, error) {
  const entry = getCache(dns, username);
  return setCache(dns, username, {
    ready: Boolean(entry?.ready),
    loading: false,
    errors: {
      ...(entry?.errors || {}),
      bootstrap: error?.message || 'Erro ao carregar cache.'
    }
  });
}

function clearCache(dns, username) {
  return accounts.delete(buildAccountKey(dns, username));
}

function cacheCounts(entry) {
  return {
    movieCategories: count(entry?.movieCategories),
    movies: count(entry?.movies),
    seriesCategories: count(entry?.seriesCategories),
    series: count(entry?.series)
  };
}

module.exports = {
  CACHE_TTL_MS,
  buildAccountKey,
  cacheCounts,
  clearCache,
  failCache,
  finishCache,
  getCache,
  hasCatalogData,
  isCacheExpired,
  isCacheValid,
  setCache,
  startCache
};
