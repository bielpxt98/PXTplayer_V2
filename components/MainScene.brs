sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.homeScreen = m.top.findNode("homeScreen")
    m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.catalogTimeoutTimer = m.top.findNode("catalogTimeoutTimer")

    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.homeScreen.observeField("seriesSelected", "onHomeSeriesSelected")
    m.homeScreen.observeField("accountSelected", "onHomeAccountSelected")
    m.homeScreen.observeField("backRequested", "onHomeBackRequested")
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
    m.pendingSeriesCategory = invalid

    savedAccount = LoadPlaylistAccount()
    if HasValidPlaylistAccount(savedAccount)
        showHome(savedAccount)
    else
        m.loginScreen.account = savedAccount
        showLogin()
    end if
end sub

sub showLogin()
    m.loadingCategories = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.homeScreen.visible = false
    m.seriesCatalogScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.setFocus(true)
end sub

sub showHome(account as object)
    m.loadingCategories = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.loginScreen.loading = false
    m.loginScreen.visible = false
    m.seriesCatalogScreen.visible = false
    m.homeScreen.account = account
    m.homeScreen.visible = true
    m.homeScreen.callFunc("setHomeFocus")
    m.account = account
    m.credentials = account
    PRINT "HOME_SCREEN_OPENED"
end sub

sub openSeriesCatalog(account as object)
    m.loginScreen.loading = false
    m.loginScreen.visible = false
    m.homeScreen.visible = false
    m.seriesCatalogScreen.callFunc("resetForLoading")
    m.seriesCatalogScreen.message = "Carregando categorias..."
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
    PRINT "SERIES_SCREEN_OPENED"
    m.account = account
    m.credentials = account
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
        showHome(m.credentials)
    else
        m.loginScreen.loading = false
        m.loginScreen.message = "Usuario ou senha invalidos."
        showLogin()
    end if
end sub

sub onLoadCategoriesRequested()
    if m.loadingCategories then return
    if m.account = invalid then m.account = m.credentials
    if not HasValidPlaylistAccount(m.account)
        m.seriesCatalogScreen.callFunc("showError", "Conta nao encontrada.")
        return
    end if

    cachedCategories = LoadSeriesCategoriesCache()
    if cachedCategories <> invalid
        m.seriesCatalogScreen.callFunc("setCategories", cachedCategories)
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
        SaveSeriesCategoriesCache(result.data)
        m.seriesCatalogScreen.callFunc("setCategories", result.data)
    else
        m.seriesCatalogScreen.callFunc("showError", RetryMessage(result.message, "categorias"))
    end if
end sub

sub onSeriesResult(result as object)
    if result = invalid then return
    if not m.catalogLoading then return
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.seriesCatalogScreen.loading = false
    if result.success = true
        if PxtTrim(result.category_id) = ""
            SaveSeriesAllCache(result.data)
        else
            SaveSeriesCategoryCache(result.category_id, result.data)
        end if
        m.seriesCatalogScreen.series = result.data
        m.seriesCatalogScreen.message = ""
    else
        m.seriesCatalogScreen.message = RetryMessage(SeriesLoadErrorMessage(result), "series")
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
        m.seriesCatalogScreen.message = "Tempo esgotado ao carregar series." + Chr(10) + "Pressione OK para tentar novamente."
        PRINT "GET_SERIES_TIMEOUT"
    end if
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading or m.loadingCategories then return
    cat = event.getData()
    if cat = invalid then return
    m.pendingSeriesCategory = cat
    categoryId = PxtTrim(cat.category_id)

    cachedSeries = invalid
    if categoryId = "all" or categoryId = ""
        cachedSeries = LoadSeriesAllCache()
    else
        cachedSeries = LoadSeriesCategoryCache(categoryId)
    end if
    if cachedSeries <> invalid
        m.seriesCatalogScreen.series = cachedSeries
        m.seriesCatalogScreen.message = ""
        return
    end if

    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando series..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 60
    m.catalogTimeoutTimer.control = "start"
    apiCategoryId = categoryId
    if apiCategoryId = "all" then apiCategoryId = ""
    m.xtreamService.control = "STOP"
    m.xtreamService.callFunc("getSeries", { account: m.account, category_id: apiCategoryId })
end sub

sub onHomeSeriesSelected()
    if not HasValidPlaylistAccount(m.account) then
        showLogin()
        return
    end if
    openSeriesCatalog(m.account)
end sub

sub onHomeAccountSelected()
    ' Dados basicos sao exibidos pela propria HomeScreen.
end sub

sub onHomeBackRequested()
    m.top.getScene().close = true
end sub

sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub

sub onCatalogBackRequested()
    m.loadingCategories = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    showHome(m.account)
end sub

function SeriesLoadErrorMessage(result as dynamic) as string
    if result <> invalid and result.code = "timeout" then return "Tempo esgotado ao carregar series."
    return "Nao foi possivel carregar series."
end function

function RetryMessage(message as dynamic, contentName as string) as string
    text = PxtTrim(message)
    if text = "" then text = "Nao foi possivel carregar " + contentName + "."
    return text + Chr(10) + "Pressione OK para tentar novamente."
end function
