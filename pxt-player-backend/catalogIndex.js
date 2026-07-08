const DEFAULT_PAGE_LIMIT = 200;
const MAX_PAGE_LIMIT = 500;

function normalizeCategoryId(value) {
  if (value === undefined || value === null) {
    return '';
  }

  return String(value).trim();
}

function itemCategoryId(item) {
  if (!item || typeof item !== 'object') {
    return '';
  }

  return normalizeCategoryId(item.category_id ?? item.categoryId ?? item.cat_id);
}

function buildCategoryIndex(items) {
  const index = {};

  for (const item of Array.isArray(items) ? items : []) {
    const categoryId = itemCategoryId(item);
    if (!categoryId) {
      continue;
    }

    if (!index[categoryId]) {
      index[categoryId] = [];
    }

    index[categoryId].push(item);
  }

  return index;
}

function parsePageLimit(limit) {
  if (limit === undefined || limit === null || limit === '') {
    return DEFAULT_PAGE_LIMIT;
  }

  const parsed = Number.parseInt(limit, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_PAGE_LIMIT;
  }

  return Math.min(parsed, MAX_PAGE_LIMIT);
}

function parsePageOffset(offset) {
  if (offset === undefined || offset === null || offset === '') {
    return 0;
  }

  const parsed = Number.parseInt(offset, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    return 0;
  }

  return parsed;
}

function slicePage(items, limit, offset) {
  const list = Array.isArray(items) ? items : [];
  const boundedLimit = parsePageLimit(limit);
  const boundedOffset = parsePageOffset(offset);
  const page = list.slice(boundedOffset, boundedOffset + boundedLimit);

  return {
    total: list.length,
    limit: boundedLimit,
    offset: boundedOffset,
    count: page.length,
    items: page
  };
}

function getIndexedItems(index, categoryId) {
  if (!index || typeof index !== 'object') {
    return [];
  }

  const normalizedCategoryId = normalizeCategoryId(categoryId);
  if (!normalizedCategoryId) {
    return [];
  }

  return Array.isArray(index[normalizedCategoryId]) ? index[normalizedCategoryId] : [];
}

function getCatalogItems(entry, kind, categoryId, limit, offset) {
  const normalizedCategoryId = normalizeCategoryId(categoryId);

  if (kind === 'movieCategories') {
    return slicePage(entry?.movieCategories, limit, offset);
  }

  if (kind === 'seriesCategories') {
    return slicePage(entry?.seriesCategories, limit, offset);
  }

  if (kind === 'liveCategories') {
    return slicePage(entry?.liveCategories, limit, offset);
  }

  if (kind === 'movies') {
    const source = normalizedCategoryId
      ? getIndexedItems(entry?.moviesByCategory, normalizedCategoryId)
      : entry?.movies;
    return slicePage(source, limit, offset);
  }

  if (kind === 'series') {
    const source = normalizedCategoryId
      ? getIndexedItems(entry?.seriesByCategory, normalizedCategoryId)
      : entry?.series;
    return slicePage(source, limit, offset);
  }

  if (kind === 'live') {
    const source = normalizedCategoryId
      ? getIndexedItems(entry?.liveByCategory, normalizedCategoryId)
      : entry?.liveChannels;
    return slicePage(source, limit, offset);
  }

  return slicePage([], limit, offset);
}

function hasCatalogSlice(entry, kind) {
  if (!entry) {
    return false;
  }

  if (kind === 'movieCategories') {
    return Array.isArray(entry.movieCategories) && entry.movieCategories.length > 0;
  }

  if (kind === 'movies') {
    return Array.isArray(entry.movies) && entry.movies.length > 0;
  }

  if (kind === 'seriesCategories') {
    return Array.isArray(entry.seriesCategories) && entry.seriesCategories.length > 0;
  }

  if (kind === 'series') {
    return Array.isArray(entry.series) && entry.series.length > 0;
  }

  if (kind === 'liveCategories') {
    return Array.isArray(entry.liveCategories) && entry.liveCategories.length > 0;
  }

  if (kind === 'live') {
    return Array.isArray(entry.liveChannels) && entry.liveChannels.length > 0;
  }

  return false;
}

module.exports = {
  DEFAULT_PAGE_LIMIT,
  MAX_PAGE_LIMIT,
  buildCategoryIndex,
  getCatalogItems,
  hasCatalogSlice,
  normalizeCategoryId,
  parsePageLimit,
  parsePageOffset
};