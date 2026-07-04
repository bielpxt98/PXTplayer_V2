function normalizeText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim();
}

function itemName(item) {
  return item?.name || item?.title || '';
}

function searchList(items, query, limit) {
  const normalizedQuery = normalizeText(query);

  if (!normalizedQuery) {
    return [];
  }

  return items
    .filter((item) => normalizeText(itemName(item)).includes(normalizedQuery))
    .slice(0, limit);
}

function searchCache(cacheEntry, query, type = 'all', limit = 50) {
  const results = [];
  const normalizedType = String(type || 'all').toLowerCase();

  if (normalizedType === 'movies' || normalizedType === 'all') {
    results.push(
      ...searchList(cacheEntry.movies || [], query, limit).map((item) => ({
        type: 'movies',
        item
      }))
    );
  }

  if (results.length < limit && (normalizedType === 'series' || normalizedType === 'all')) {
    results.push(
      ...searchList(cacheEntry.series || [], query, limit - results.length).map((item) => ({
        type: 'series',
        item
      }))
    );
  }

  return results.slice(0, limit);
}

function isValidSearchType(type) {
  return ['movies', 'series', 'all'].includes(String(type || 'all').toLowerCase());
}

module.exports = {
  normalizeText,
  searchCache,
  isValidSearchType
};
