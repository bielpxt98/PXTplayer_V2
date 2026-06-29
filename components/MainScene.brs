sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.catalogScreen = m.top.findNode("seriesCatalogScreen")
    m.detailScreen = m.top.findNode("seriesDetailScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.catalogScreen.observeField("categorySelected", "onCategorySelected")
    m.catalogScreen.observeField("seriesSelected", "onSeriesSelected")
    m.catalogScreen.observeField("backRequested", "onCatalogBackRequested")
    m.detailScreen.observeField("backRequested", "onDetailBackRequested")
    m.detailScreen.observeField("retryRequested", "onDetailRetryRequested")
    m.xtreamService.observeField("result", "onXtreamResult")
    m.connecting = false : m.catalogLoading = false : m.seriesDetailsLoading = false
    m.credentials = invalid : m.selectedSeries = invalid
    m.loginScreen.account = LoadPlaylistAccount()
    showLogin()
end sub
sub showLogin()
    m.catalogScreen.visible = false : m.detailScreen.visible = false : m.loginScreen.visible = true : m.loginScreen.setFocus(true)
end sub
sub showCatalog()
    m.loginScreen.visible = false : m.detailScreen.visible = false : m.catalogScreen.visible = true : m.catalogScreen.callFunc("setCatalogFocus")
end sub
sub showDetail()
    m.loginScreen.visible = false : m.catalogScreen.visible = false : m.detailScreen.visible = true : m.detailScreen.callFunc("setDetailFocus")
end sub
sub onLoginSubmit(event as object)
    if m.connecting then return
    credentials = event.getData() : dns = NormalizeDns(credentials.dns)
    if dns = "" or PxtTrim(credentials.username) = "" or PxtTrim(credentials.password) = "" then m.loginScreen.message = "Preencha DNS, usuário e senha." : return
    m.connecting = true : m.loginScreen.loading = true : m.loginScreen.message = "Conectando..."
    m.xtreamService.request = { dns: dns, username: credentials.username, password: credentials.password }
end sub
sub onCategorySelected(event as object)
    if m.catalogLoading then return
    cat = event.getData() : m.catalogLoading = true : m.catalogScreen.loading = true : m.catalogScreen.message = "Carregando series..."
    m.xtreamService.request = baseRequest("get_series", { category_id: cat.category_id })
end sub
sub onSeriesSelected(event as object)
    if m.seriesDetailsLoading then return
    series = event.getData()
    if PxtTrim(series.series_id) = "" then m.catalogScreen.message = "Esta serie nao possui detalhes disponiveis." : return
    m.selectedSeries = series : m.seriesDetailsLoading = true
    m.detailScreen.selectedSeries = series : m.detailScreen.details = invalid : m.detailScreen.loading = true : m.detailScreen.message = "Carregando detalhes..."
    showDetail()
    m.xtreamService.request = baseRequest("get_series_info", { series_id: series.series_id })
end sub
sub onDetailRetryRequested()
    if m.selectedSeries = invalid or m.seriesDetailsLoading then return
    m.seriesDetailsLoading = true
    m.detailScreen.loading = true : m.detailScreen.message = "Carregando detalhes..."
    m.xtreamService.request = baseRequest("get_series_info", { series_id: m.selectedSeries.series_id })
end sub
sub onXtreamResult(event as object)
    result = event.getData()
    if result.action = invalid
        m.connecting = false : m.loginScreen.loading = false
        if result.success = true
            m.credentials = { dns: result.dns, username: result.username, password: result.password }
            SavePlaylistAccount(result.dns, result.username, result.password)
            m.loginScreen.message = "" : loadCategories() : showCatalog()
        else
            m.loginScreen.message = result.message : showLogin()
        end if
    else if result.action = "get_series_categories"
        m.catalogLoading = false : m.catalogScreen.loading = false
        if result.success then m.catalogScreen.categories = result.categories : m.catalogScreen.message = "Selecione uma categoria e pressione OK." else m.catalogScreen.message = result.message
    else if result.action = "get_series"
        m.catalogLoading = false : m.catalogScreen.loading = false
        if result.success then m.catalogScreen.series = result.series : m.catalogScreen.message = "" else m.catalogScreen.message = result.message
    else if result.action = "get_series_info"
        m.seriesDetailsLoading = false : m.detailScreen.loading = false
        if result.success then m.detailScreen.details = result.details : m.detailScreen.message = "" else m.detailScreen.message = result.message
    end if
end sub
sub loadCategories()
    if m.credentials = invalid then return
    m.catalogLoading = true : m.catalogScreen.loading = true : m.catalogScreen.message = "Carregando categorias..."
    m.xtreamService.request = baseRequest("get_series_categories", {})
end sub
function baseRequest(action as string, extra as object) as object
    req = { action: action, dns: m.credentials.dns, username: m.credentials.username, password: m.credentials.password }
    for each k in extra : req[k] = extra[k] : end for
    return req
end function
sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub
sub onCatalogBackRequested()
    showLogin()
  end if
end sub
sub onDetailBackRequested()
    m.seriesDetailsLoading = false : m.detailScreen.loading = false : showCatalog()
end sub
