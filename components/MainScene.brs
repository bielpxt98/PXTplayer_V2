sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.catalogTimeoutTimer = m.top.findNode("catalogTimeoutTimer")

    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.seriesCatalogScreen.observeField("categorySelected", "onCategorySelected")
    m.seriesCatalogScreen.observeField("backRequested", "onCatalogBackRequested")
    m.seriesCatalogScreen.observeField("loadCategoriesRequested", "onLoadCategoriesRequested")
    m.xtreamService.observeField("connectResult", "onConnectResult")
    m.xtreamService.observeField("categoriesResult", "onSeriesCategoriesResult")
    m.xtreamService.observeField("seriesResult", "onSeriesResult")
    m.catalogTimeoutTimer.observeField("fire", "onCatalogTimeout")

    m.connecting = false
    m.loadingCategories = false
    m.catalogLoading = false
    m.credentials = invalid

    m.loginScreen.account = LoadPlaylistAccount()
    showLogin()
end sub

sub showLogin()
    m.loadingCategories = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.seriesCatalogScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.setFocus(true)
end sub

sub openSeriesCatalog(account as object)
    m.loginScreen.loading = false
    m.loginScreen.visible = false
    m.seriesCatalogScreen.callFunc("resetForLoading")
    m.seriesCatalogScreen.message = "Carregando categorias..."
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
    PRINT "OPEN_SERIES_CATALOG"
    m.seriesCatalogScreen.account = account
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

    startConnect({ dns: dns, username: username, password: password })
end sub

sub startConnect(credentials as object)
    m.connecting = true
    m.loginScreen.loading = true
    m.loginScreen.message = "Conectando..."
    PRINT "CONNECT_STARTED"
    m.xtreamService.callFunc("connect", credentials)
end sub

sub onConnectResult(event as object)
    PRINT "CONNECT_RESULT_RECEIVED"
    result = event.getData()
    if result = invalid then return
    m.connecting = false

    if result.success = true
        PRINT "CONNECT_SUCCESS"
        m.credentials = result.account
        SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
        openSeriesCatalog(m.credentials)
    else
        m.loginScreen.loading = false
        m.loginScreen.message = "Usuario ou senha invalidos."
        showLogin()
    end if
end sub

sub onLoadCategoriesRequested(event as object)
    if m.loadingCategories then return
    account = event.getData()
    if account = invalid then account = m.credentials
    if account = invalid or PxtTrim(account.dns) = "" or PxtTrim(account.username) = "" or PxtTrim(account.password) = ""
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Nao foi possivel carregar categorias." + Chr(10) + "Pressione OK para tentar novamente."
        return
    end if

    m.loadingCategories = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando categorias..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 30
    m.catalogTimeoutTimer.control = "start"
    PRINT "CATEGORIES_STARTED"
    m.xtreamService.callFunc("getSeriesCategories", account)
end sub

sub onSeriesCategoriesResult(event as object)
    PRINT "CATEGORIES_RESULT_RECEIVED"
    result = event.getData()
    if result = invalid then return
    if not m.loadingCategories then return

    m.loadingCategories = false
    m.catalogTimeoutTimer.control = "stop"
    m.seriesCatalogScreen.loading = false

    if result.success = true
        PRINT "CATEGORIES_SUCCESS"
        m.seriesCatalogScreen.categories = result.categories
        m.seriesCatalogScreen.message = "Selecione uma categoria e pressione OK."
    else
        if result.code = "timeout"
            PRINT "CATEGORIES_TIMEOUT"
            m.seriesCatalogScreen.message = "Tempo esgotado ao carregar categorias." + Chr(10) + "Pressione OK para tentar novamente."
        else
            PRINT "CATEGORIES_ERROR"
            m.seriesCatalogScreen.message = "Nao foi possivel carregar categorias." + Chr(10) + "Pressione OK para tentar novamente."
        end if
    end if
end sub

sub onSeriesResult(event as object)
    result = event.getData()
    if result = invalid then return
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.seriesCatalogScreen.loading = false
    if result.success = true
        m.seriesCatalogScreen.series = result.series
        m.seriesCatalogScreen.message = ""
    else
        m.seriesCatalogScreen.message = result.message
    end if
end sub

sub onCatalogTimeout()
    if m.loadingCategories
        m.loadingCategories = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo esgotado ao carregar categorias." + Chr(10) + "Pressione OK para tentar novamente."
        PRINT "CATEGORIES_TIMEOUT"
    else if m.catalogLoading
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo de conexao esgotado."
        PRINT "GET_SERIES_ERROR"
    end if
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading or m.loadingCategories then return
    cat = event.getData()
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando series..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 20
    m.catalogTimeoutTimer.control = "start"
    m.xtreamService.callFunc("getSeries", { account: m.credentials, category_id: cat.category_id })
end sub

sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub

sub onCatalogBackRequested()
    m.loadingCategories = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    showLogin()
end sub
