sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.catalogTimeoutTimer = m.top.findNode("catalogTimeoutTimer")

    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.seriesCatalogScreen.observeField("categorySelected", "onCategorySelected")
    m.seriesCatalogScreen.observeField("backRequested", "onCatalogBackRequested")
    m.xtreamService.observeField("connectResult", "onConnectResult")
    m.xtreamService.observeField("categoriesResult", "onSeriesCategoriesResult")
    m.xtreamService.observeField("seriesResult", "onSeriesResult")
    m.catalogTimeoutTimer.observeField("fire", "onCatalogTimeout")

    m.connecting = false
    m.loadingCategoriesForLogin = false
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

sub openSeriesCatalog(categories as object)
    m.loginScreen.visible = false
    m.seriesCatalogScreen.categories = categories
    m.seriesCatalogScreen.series = []
    m.seriesCatalogScreen.loading = false
    m.seriesCatalogScreen.message = "Selecione uma categoria e pressione OK."
    m.seriesCatalogScreen.visible = true
    m.seriesCatalogScreen.callFunc("setCatalogFocus")
    PRINT "OPEN_SERIES_CATALOG"
end sub

sub onLoginSubmit(event as object)
    PRINT "LOGIN_SUBMIT_RECEIVED"
    if m.connecting or m.loadingCategoriesForLogin then return

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
        m.credentials = result.account
        SavePlaylistAccount(m.credentials.dns, m.credentials.username, m.credentials.password)
        m.seriesCatalogScreen.account = m.credentials
        startLoadSeriesCategories()
    else
        m.loginScreen.loading = false
        if result.message <> invalid then m.loginScreen.message = result.message else m.loginScreen.message = "Não foi possível conectar ao servidor."
        showLogin()
    end if
end sub

sub startLoadSeriesCategories()
    if m.credentials = invalid or PxtTrim(m.credentials.dns) = "" or PxtTrim(m.credentials.username) = "" or PxtTrim(m.credentials.password) = ""
        m.loginScreen.loading = false
        m.loginScreen.message = "Conta nao encontrada para carregar categorias."
        return
    end if


    m.loadingCategoriesForLogin = true
    m.loginScreen.loading = true
    m.loginScreen.message = "Carregando categorias..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.control = "start"
    PRINT "CATEGORIES_STARTED"
    m.xtreamService.callFunc("getSeriesCategories", m.credentials)
end sub

sub onSeriesCategoriesResult(event as object)
    PRINT "CATEGORIES_RESULT_RECEIVED"
    result = event.getData()
    if result = invalid then return
    wasLoginCategoryLoad = m.loadingCategoriesForLogin
    m.loadingCategoriesForLogin = false
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    m.loginScreen.loading = false
    m.seriesCatalogScreen.loading = false

    if result.success = true
        if wasLoginCategoryLoad
            openSeriesCatalog(result.categories)
        else
            m.seriesCatalogScreen.categories = result.categories
            m.seriesCatalogScreen.message = "Selecione uma categoria e pressione OK."
        end if
    else
        PRINT "CATEGORIES_ERROR"
        if wasLoginCategoryLoad
            showLogin()
            if result.code = "timeout"
                m.loginScreen.message = "Tempo de conexao esgotado ao carregar categorias."
            else
                m.loginScreen.message = "Login realizado, mas nao foi possivel carregar as categorias."
            end if
        else
            if result.code = "timeout"
                m.seriesCatalogScreen.message = "Tempo de conexao esgotado."
            else
                m.seriesCatalogScreen.message = "Nao foi possivel carregar as categorias."
            end if
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
    if m.loadingCategoriesForLogin
        m.loadingCategoriesForLogin = false
        m.loginScreen.loading = false
        showLogin()
        m.loginScreen.message = "Tempo de conexao esgotado ao carregar categorias."
        PRINT "CATEGORIES_ERROR"
    else if m.catalogLoading
        m.catalogLoading = false
        m.seriesCatalogScreen.loading = false
        m.seriesCatalogScreen.message = "Tempo de conexao esgotado."
        PRINT "GET_SERIES_ERROR"
    end if
end sub

sub onCategorySelected(event as object)
    if m.catalogLoading or m.loadingCategoriesForLogin then return
    cat = event.getData()
    m.catalogLoading = true
    m.seriesCatalogScreen.loading = true
    m.seriesCatalogScreen.message = "Carregando series..."
    m.catalogTimeoutTimer.control = "stop"
    m.catalogTimeoutTimer.control = "start"
    m.xtreamService.callFunc("getSeries", { account: m.credentials, category_id: cat.category_id })
end sub

sub onLoginBackRequested()
    if m.connecting or m.loadingCategoriesForLogin then return
    m.top.getScene().close = true
end sub

sub onCatalogBackRequested()
    m.catalogLoading = false
    m.catalogTimeoutTimer.control = "stop"
    showLogin()
end sub
