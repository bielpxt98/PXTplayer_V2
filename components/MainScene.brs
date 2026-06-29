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
    m.seriesCatalogScreen.message = "Carregando categorias de séries..."
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
    PRINT "SERIES_CATALOG_SCREEN_OPENED"
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
    PRINT "LOGIN INICIADO"
    PRINT "CONNECT_STARTED dns=" + PxtTrim(credentials.dns)
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
        PRINT "LOGIN OK"
        PRINT "CONNECT_SUCCESS"
        m.credentials = result.account
        m.account = result.account
        SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
        openSeriesCatalog(m.credentials)
    else
        m.loginScreen.loading = false
        PRINT "CONNECT_ERROR code=" + PxtTrim(result.code)
        m.loginScreen.loading = false
        m.loginScreen.message = RetryMessage(result.message, "conexao")
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

    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando categorias de séries..."
    m.loadingCategories = true
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 30
    m.catalogTimeoutTimer.control = "start"
    PRINT "SERIES_CATEGORIES_ENDPOINT action=get_series_categories"
    m.xtreamService.control = "STOP"
    m.xtreamService.callFunc("getSeriesCategories", m.account)
end sub

sub onSeriesCategoriesResult(result as object)
    PRINT "MAINSCENE_CATEGORIES_RESULT_RECEIVED"
    if result = invalid then return
    if not m.loadingCategories then return

    m.loadingCategories = false
    m.catalogTimeoutTimer.control = "stop"

    if result.success = true
        PRINT "CATEGORIES_LOAD_SUCCESS"
        PRINT "CATEGORIES_COUNT " + result.data.Count().ToStr()
        SaveSeriesCategoriesCache(result.data)
        m.seriesCatalogScreen.callFunc("setCategories", result.data)
    else
        PRINT "CATEGORIES_LOAD_ERROR code=" + PxtTrim(result.code)
        m.seriesCatalogScreen.callFunc("showError", CategoryLoadErrorMessage(result))
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
        PRINT "SERIES_COUNT " + result.data.Count().ToStr()
        m.seriesCatalogScreen.series = result.data
        if result.data.Count() = 0
            m.seriesCatalogScreen.message = "Nenhum item encontrado nesta categoria."
        else
            m.seriesCatalogScreen.message = ""
        end if
    else
        m.seriesCatalogScreen.message = RetryMessage(SeriesLoadErrorMessage(result), "series")
    end if
end sub

sub onCatalogTimeout()
    if m.loadingCategories
        m.loadingCategories = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo esgotado ao carregar categorias."
        PRINT "SERIES_CATEGORIES_TIMEOUT"
    else if m.catalogLoading
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo esgotado ao carregar series."
        PRINT "SERIES_CATALOG_TIMEOUT"
    end if
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading or m.loadingCategories then return
    cat = event.getData()
    if cat = invalid then return
    PRINT "CATEGORIA SELECIONADA: " + PxtTrim(cat.name) + "/" + PxtTrim(cat.category_id)
    categoryId = PxtTrim(cat.category_id)

    m.catalogLoading = true
    m.seriesCatalogScreen.series = []
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando séries..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.duration = 60
    m.catalogTimeoutTimer.control = "start"
    if categoryId = ""
        PRINT "SERIES_CATALOG_ENDPOINT action=get_series"
    else
        PRINT "SERIES_CATALOG_ENDPOINT action=get_series category_id=" + categoryId
    end if
    m.xtreamService.control = "STOP"
    m.xtreamService.callFunc("getSeries", { account: m.account, category_id: categoryId })
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

function CategoryLoadErrorMessage(result as dynamic) as string
    if result <> invalid and result.code = "timeout" then return "Tempo esgotado ao carregar categorias." + Chr(10) + "Pressione OK para tentar novamente."
    return "Erro ao carregar categorias. Verifique a lista ou o login." + Chr(10) + "Pressione OK para tentar novamente."
end function

function SeriesLoadErrorMessage(result as dynamic) as string
    if result <> invalid and result.code = "timeout" then return "Tempo esgotado ao carregar series."
    return "Nao foi possivel carregar series."
end function

function RetryMessage(message as dynamic, contentName as string) as string
    text = PxtTrim(message)
    if text = "" then text = "Nao foi possivel carregar " + contentName + "."
    return text + Chr(10) + "Pressione OK para tentar novamente."
end function
