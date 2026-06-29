sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
    m.xtreamService = m.top.findNode("xtreamService")

    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.seriesCatalogScreen.observeField("categorySelected", "onCategorySelected")
    m.seriesCatalogScreen.observeField("backRequested", "onCatalogBackRequested")
    m.xtreamService.observeField("result", "onXtreamResult")

    m.connecting = false
    m.catalogLoading = false
    m.credentials = invalid

    m.loginScreen.account = LoadPlaylistAccount()
    showLogin()
end sub

sub showLogin()
    m.seriesCatalogScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.setFocus(true)
end sub

sub showCatalog()
    m.loginScreen.visible = false
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
end sub

sub onLoginSubmit(event as object)
    PRINT "LOGIN_SUBMIT_RECEIVED"
    if m.connecting then return

    credentials = event.getData()
    dns = NormalizeDns(credentials.dns)
    username = PxtTrim(credentials.username)
    password = PxtTrim(credentials.password)

    if dns = "" or username = "" or password = ""
        m.loginScreen.message = "Preencha DNS, usuário e senha."
        return
    end if

    m.connecting = true
    m.loginScreen.loading = true
    m.loginScreen.message = "Conectando..."
    PRINT "XTREAM_CONNECT_STARTED"
    m.xtreamService.callFunc("connect", { dns: dns, username: username, password: password })
end sub

sub onXtreamResult(event as object)
    PRINT "XTREAM_CONNECT_RESULT"
    result = event.getData()
    if result = invalid then return

    if result.action = "connect"
        m.connecting = false
        m.loginScreen.loading = false

        if result.success = true
            m.credentials = result.account
            SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
            m.loginScreen.message = ""
            m.seriesCatalogScreen.account = m.credentials
            showCatalog()
            PRINT "OPEN_SERIES_CATALOG"
            loadCategories()
        else
            if result.message <> invalid then m.loginScreen.message = result.message else m.loginScreen.message = "Não foi possível conectar ao servidor."
            showLogin()
        end if
    else if result.action = "get_series_categories"
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        if result.success = true
            m.seriesCatalogScreen.categories = result.categories
            m.seriesCatalogScreen.message = "Selecione uma categoria e pressione OK."
        else
            m.seriesCatalogScreen.message = result.message
        end if
    else if result.action = "get_series"
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        if result.success = true
            m.seriesCatalogScreen.series = result.series
            m.seriesCatalogScreen.message = ""
        else
            m.seriesCatalogScreen.message = result.message
        end if
    end if
end sub

sub loadCategories()
    if m.credentials = invalid then return
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando categorias..."
    PRINT "SERIES_CATEGORIES_STARTED"
    m.xtreamService.callFunc("getSeriesCategories", m.credentials)
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading then return
    cat = event.getData()
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando series..."
    m.xtreamService.callFunc("getSeries", { account: m.credentials, category_id: cat.category_id })
end sub

sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub

sub onCatalogBackRequested()
    m.catalogLoading = false
    showLogin()
end sub
