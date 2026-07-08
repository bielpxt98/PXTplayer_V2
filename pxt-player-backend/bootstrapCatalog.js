const emptyCatalog = () => ({
  movieCategories: [],
  movies: [],
  seriesCategories: [],
  series: [],
  liveCategories: [],
  liveChannels: [],
  loadedAt: null,
  ready: false,
  errors: {}
});

let catalog = emptyCatalog();

function count(value) {
  return Array.isArray(value) ? value.length : 0;
}

function getBootstrapCatalog() {
  return catalog;
}

function setBootstrapCatalog(data) {
  catalog = {
    movieCategories: Array.isArray(data.movieCategories) ? data.movieCategories : [],
    movies: Array.isArray(data.movies) ? data.movies : [],
    seriesCategories: Array.isArray(data.seriesCategories) ? data.seriesCategories : [],
    series: Array.isArray(data.series) ? data.series : [],
    liveCategories: Array.isArray(data.liveCategories) ? data.liveCategories : [],
    liveChannels: Array.isArray(data.liveChannels) ? data.liveChannels : [],
    loadedAt: data.loadedAt || new Date().toISOString(),
    ready: Boolean(data.ready),
    errors: data.errors || {}
  };

  return catalog;
}

function getBootstrapStatus() {
  return {
    ready: catalog.ready,
    loadedAt: catalog.loadedAt,
    movieCategories: count(catalog.movieCategories),
    movies: count(catalog.movies),
    seriesCategories: count(catalog.seriesCategories),
    series: count(catalog.series),
    liveCategories: count(catalog.liveCategories),
    liveChannels: count(catalog.liveChannels),
    errors: catalog.errors
  };
}

module.exports = {
  getBootstrapCatalog,
  setBootstrapCatalog,
  getBootstrapStatus
};