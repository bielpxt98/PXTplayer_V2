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
    m.xtreamService.ObserveField("result", "onXtreamResult")
    m.catalogTimeoutTimer.observeField("fire", "onCatalogTimeout")

    m.connecting = false
    m.loadingCategories = false
    m.catalogLoading = false
    m.credentials = invalid
    m.account = invalid

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
    PRINT "SERIES_SCREEN_OPENED"
    m.account = account
    m.seriesCatalogScreen.account = m.account
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

sub onXtreamResult()
    result = m.xtreamService.result
    if result = invalid then return

    if result.request = "connect" then
        onConnectResult(result)
    else if result.request = "getSeriesCategories" then
        onSeriesCategoriesResult(result)
    else if result.request = "getSeries" then
        onSeriesResult(result)
    end if
end sub

sub onConnectResult(result as object)
    PRINT "CONNECT_RESULT_RECEIVED"
    if result = invalid then return
    m.connecting = false

    if result.success = true
        PRINT "CONNECT_SUCCESS"
        m.credentials = result.account
        m.account = result.account
        SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
        openSeriesCatalog(m.credentials)
    else
        m.loginScreen.loading = false
        m.loginScreen.message = "Usuario ou senha invalidos."
        showLogin()
    end if
end sub

sub onLoadCategoriesRequested()
    if m.loadingCategories then return
    if m.account = invalid then m.account = m.credentials
    if m.account = invalid or PxtTrim(m.account.dns) = "" or PxtTrim(m.account.username) = "" or PxtTrim(m.account.password) = ""
        m.seriesCatalogScreen.callFunc("showError", "Conta nao encontrada.")
        return
    end if

    m.loadingCategories = true
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 30
    m.catalogTimeoutTimer.control = "start"
    PRINT "XTREAM_GET_SERIES_CATEGORIES_RUN"
    m.xtreamService.control = "STOP"
    m.xtreamService.action = "getSeriesCategories"
    m.xtreamService.dns = m.account.dns
    m.xtreamService.username = m.account.username
    m.xtreamService.password = m.account.password
    m.xtreamService.control = "RUN"
end sub

sub onSeriesCategoriesResult(result as object)
    PRINT "MAINSCENE_CATEGORIES_RESULT_RECEIVED"
    if result = invalid then return
    if not m.loadingCategories then return

    m.loadingCategories = false
    m.catalogTimeoutTimer.control = "stop"

    if result.success = true
        m.seriesCatalogScreen.callFunc("setCategories", result.data)
    else
        m.seriesCatalogScreen.callFunc("showError", result.message)
    end if
end sub

sub onSeriesResult(result as object)
    if result = invalid then return
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.seriesCatalogScreen.loading = false
    if result.success = true
        m.seriesCatalogScreen.series = result.data
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
