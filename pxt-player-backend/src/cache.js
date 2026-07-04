// Cache simples em memoria. Nao persiste senhas, tokens ou dados em disco.
const accounts = new Map();

function buildAccountKey(dns, username) {
  return `${String(dns || '').trim()}::${String(username || '').trim()}`;
}

function createEntry() {
  const now = new Date().toISOString();

  return {
    movies: [],
    series: [],
    movieCategories: [],
    seriesCategories: [],
    startedAt: now,
    updatedAt: now,
    ready: false
  };
}

function getCache(dns, username) {
  return accounts.get(buildAccountKey(dns, username));
}

function setCache(dns, username, data) {
  const key = buildAccountKey(dns, username);
  const current = accounts.get(key) || createEntry();
  const now = new Date().toISOString();

  const next = {
    ...current,
    ...data,
    updatedAt: now
  };

  accounts.set(key, next);
  return next;
}

function startCache(dns, username) {
  const entry = createEntry();
  accounts.set(buildAccountKey(dns, username), entry);
  return entry;
}

function clearCache(dns, username) {
  return accounts.delete(buildAccountKey(dns, username));
}

module.exports = {
  buildAccountKey,
  getCache,
  setCache,
  startCache,
  clearCache
};
