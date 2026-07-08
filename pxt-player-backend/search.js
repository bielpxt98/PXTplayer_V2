const DEFAULT_SEARCH_LIMIT = 50;
const MAX_SEARCH_LIMIT = 100;

function normalizeText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

function searchableNames(item) {
  return [item?.name, item?.title, item?.stream_name]
    .filter((value) => value !== undefined && value !== null)
    .map(normalizeText)
    .filter(Boolean);
}

function displayMovieName(item) {
  return item?.name || item?.title || item?.stream_name || '';
}

function displaySeriesName(item) {
  return item?.name || item?.title || item?.stream_name || '';
}

function findBestRank(names, normalizedQuery) {
  let bestRank = null;

  for (const name of names) {
    const index = name.indexOf(normalizedQuery);

    if (index === -1) {
      continue;
    }

    let rank = 2;

    if (index === 0) {
      rank = 0;
    } else if (name[index - 1] === ' ') {
      rank = 1;
    }

    if (bestRank === null || rank < bestRank) {
      bestRank = rank;
    }
  }

  return bestRank;
}

function normalizeYear(value) {
  if (!value) {
    return undefined;
  }

  const match = String(value).match(/\d{4}/);
  return match ? match[0] : String(value);
}

function movieIndexItem(item) {
  const result = {
    type: 'movie',
    id: item?.stream_id !== undefined && item?.stream_id !== null ? String(item.stream_id) : '',
    name: displayMovieName(item),
    normalizedName: searchableNames(item),
    poster: item?.stream_icon || '',
    category_id: item?.category_id !== undefined && item?.category_id !== null ? String(item.category_id) : ''
  };

  const year = normalizeYear(item?.year || item?.releaseDate);
  if (year) result.year = year;

  if (item?.container_extension) {
    result.container_extension = item.container_extension;
  }

  return result;
}

function seriesIndexItem(item) {
  const result = {
    type: 'series',
    id: item?.series_id !== undefined && item?.series_id !== null ? String(item.series_id) : '',
    name: displaySeriesName(item),
    normalizedName: searchableNames(item),
    poster: item?.cover || '',
    category_id: item?.category_id !== undefined && item?.category_id !== null ? String(item.category_id) : ''
  };

  const releaseDate = item?.releaseDate || item?.year;
  if (releaseDate) result.releaseDate = String(releaseDate);

  return result;
}

function buildSearchIndex({ movies, series } = {}) {
  return {
    moviesIndex: (Array.isArray(movies) ? movies : []).map(movieIndexItem),
    seriesIndex: (Array.isArray(series) ? series : []).map(seriesIndexItem)
  };
}

function resultFromIndexItem(item) {
  const result = {
    type: item.type,
    id: item.id,
    name: item.name,
    poster: item.poster,
    category_id: item.category_id
  };

  if (item.year) result.year = item.year;
  if (item.releaseDate) result.releaseDate = item.releaseDate;
  if (item.container_extension) result.container_extension = item.container_extension;

  return result;
}

function collectMatches(indexItems, query, sourceOrder) {
  const normalizedQuery = normalizeText(query);

  if (!normalizedQuery) {
    return [];
  }

  return (Array.isArray(indexItems) ? indexItems : [])
    .map((item, index) => ({
      result: resultFromIndexItem(item),
      index,
      sourceOrder,
      rank: findBestRank(Array.isArray(item.normalizedName) ? item.normalizedName : [item.normalizedName], normalizedQuery)
    }))
    .filter((match) => match.rank !== null);
}

function parseSearchLimit(limit) {
  if (limit === undefined || limit === null || limit === '') {
    return DEFAULT_SEARCH_LIMIT;
  }

  const parsed = Number.parseInt(limit, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_SEARCH_LIMIT;
  }

  return Math.min(parsed, MAX_SEARCH_LIMIT);
}

function searchCache(cacheEntry, query, type = 'all', limit = DEFAULT_SEARCH_LIMIT) {
  const normalizedType = String(type || 'all').toLowerCase();
  const boundedLimit = parseSearchLimit(limit);
  const matches = [];
  const index = cacheEntry?.searchIndex || {};

  if (normalizedType === 'movies' || normalizedType === 'all') {
    matches.push(...collectMatches(index.moviesIndex, query, 0));
  }

  if (normalizedType === 'series' || normalizedType === 'all') {
    matches.push(...collectMatches(index.seriesIndex, query, 1));
  }

  return matches
    .sort((a, b) => a.rank - b.rank || a.sourceOrder - b.sourceOrder || a.index - b.index)
    .slice(0, boundedLimit)
    .map((match) => match.result);
}

function isValidSearchType(type) {
  return ['movies', 'series', 'all'].includes(String(type || 'all').toLowerCase());
}

module.exports = {
  DEFAULT_SEARCH_LIMIT,
  MAX_SEARCH_LIMIT,
  buildSearchIndex,
  normalizeText,
  parseSearchLimit,
  searchCache,
  isValidSearchType
};
