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
    } else if (name.slice(0, index).trim().includes(' ') || name[index - 1] === ' ') {
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

function movieResult(item) {
  const result = {
    type: 'movie',
    id: item?.stream_id !== undefined && item?.stream_id !== null ? String(item.stream_id) : '',
    name: displayMovieName(item),
    poster: item?.stream_icon || '',
    category_id: item?.category_id !== undefined && item?.category_id !== null ? String(item.category_id) : ''
  };

  if (item?.year) {
    result.year = normalizeYear(item.year);
  }

  if (item?.container_extension) {
    result.container_extension = item.container_extension;
  }

  return result;
}

function seriesResult(item) {
  const result = {
    type: 'series',
    id: item?.series_id !== undefined && item?.series_id !== null ? String(item.series_id) : '',
    name: displaySeriesName(item),
    poster: item?.cover || '',
    category_id: item?.category_id !== undefined && item?.category_id !== null ? String(item.category_id) : ''
  };

  const year = normalizeYear(item?.releaseDate || item?.year);

  if (year) {
    result.year = year;
  }

  return result;
}

function collectMatches(items, query, mapResult, sourceOrder) {
  const normalizedQuery = normalizeText(query);

  if (!normalizedQuery) {
    return [];
  }

  return (Array.isArray(items) ? items : [])
    .map((item, index) => ({
      result: mapResult(item),
      index,
      sourceOrder,
      rank: findBestRank(searchableNames(item), normalizedQuery)
    }))
    .filter((match) => match.rank !== null);
}

function searchCache(cacheEntry, query, type = 'all', limit = 50) {
  const normalizedType = String(type || 'all').toLowerCase();
  const matches = [];

  if (normalizedType === 'movies' || normalizedType === 'all') {
    matches.push(...collectMatches(cacheEntry?.movies, query, movieResult, 0));
  }

  if (normalizedType === 'series' || normalizedType === 'all') {
    matches.push(...collectMatches(cacheEntry?.series, query, seriesResult, 1));
  }

  return matches
    .sort((a, b) => a.rank - b.rank || a.sourceOrder - b.sourceOrder || a.index - b.index)
    .slice(0, limit)
    .map((match) => match.result);
}

function isValidSearchType(type) {
  return ['movies', 'series', 'all'].includes(String(type || 'all').toLowerCase());
}

module.exports = {
  normalizeText,
  searchCache,
  isValidSearchType
};
