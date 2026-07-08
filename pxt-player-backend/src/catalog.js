const { getCatalogItems, hasCatalogSlice } = require('./catalogIndex');

function isCacheUsable(entry) {
  return Boolean(entry && (entry.ready || entry.loading === false) && hasAnyCatalogData(entry));
}

function hasAnyCatalogData(entry) {
  return Boolean(
    entry &&
      (hasCatalogSlice(entry, 'movieCategories') ||
        hasCatalogSlice(entry, 'movies') ||
        hasCatalogSlice(entry, 'seriesCategories') ||
        hasCatalogSlice(entry, 'series') ||
        hasCatalogSlice(entry, 'liveCategories') ||
        hasCatalogSlice(entry, 'live'))
  );
}

function buildCatalogError(message, statusCode = 404) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function requireCatalogEntry(dns, username, getCache) {
  const entry = getCache(dns, username);

  if (!entry) {
    throw buildCatalogError('cache_not_ready', 404);
  }

  if (entry.loading && !hasAnyCatalogData(entry)) {
    throw buildCatalogError('cache_loading', 202);
  }

  if (!hasAnyCatalogData(entry)) {
    throw buildCatalogError('cache_not_ready', 404);
  }

  return entry;
}

function buildCatalogResponse(kind, entry, categoryId, limit, offset) {
  const page = getCatalogItems(entry, kind, categoryId, limit, offset);

  return {
    ok: true,
    kind,
    category_id: categoryId ? String(categoryId) : '',
    total: page.total,
    limit: page.limit,
    offset: page.offset,
    count: page.count,
    items: page.items,
    loadedAt: entry.loadedAt || null,
    updatedAt: entry.updatedAt || null,
    source: 'cache'
  };
}

module.exports = {
  buildCatalogResponse,
  hasAnyCatalogData,
  isCacheUsable,
  requireCatalogEntry
};