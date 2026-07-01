sub init()
    m.home = m.top.FindNode("home")
    m.login = m.top.FindNode("login")
    m.loading = m.top.FindNode("loading")
    m.loadingStatus = m.top.FindNode("loadingStatus")
    m.startupService = m.top.FindNode("startupService")

    m.home.ObserveField("openLogin", "showLogin")
    m.login.ObserveField("closeLogin", "showHome")
    m.login.ObserveField("loginSuccess", "onLoginSuccess")
    m.startupService.ObserveField("progress", "onStartupProgress")
    m.startupService.ObserveField("result", "onStartupResult")

    startInitialLoad()
end sub

sub startInitialLoad()
    credentials = EnsureXtreamCredentialsForTest()
    showLoading("Carregando lista...")
    m.startupService.dns = credentials.dns
    m.startupService.username = credentials.username
    m.startupService.password = credentials.password
    m.startupService.control = "RUN"
end sub

sub showLoading(message as string)
    m.login.visible = false
    m.home.visible = false
    m.loading.visible = true
    m.loadingStatus.color = "#FFFFFF"
    m.loadingStatus.text = message
    m.top.SetFocus(true)
end sub

sub showHome()
    m.loading.visible = false
    m.login.visible = false
    m.home.visible = true
    m.home.navigationEnabled = true
    m.home.SetFocus(true)
end sub

sub showLogin()
    if m.home.navigationEnabled <> true then return
    m.home.visible = false
    m.loading.visible = false
    m.login.visible = true
    m.login.callFunc("resetStatus")
    m.login.SetFocus(true)
end sub

sub onLoginSuccess()
    m.home.callFunc("setStatus", "Conectado")
    showHome()
end sub

sub onStartupProgress()
    if m.startupService.progress <> invalid and m.startupService.progress <> ""
        m.loadingStatus.color = "#FFFFFF"
        m.loadingStatus.text = m.startupService.progress
    end if
end sub

sub onStartupResult()
    result = m.startupService.result
    if result <> invalid and result.success = true
        SaveXtreamCredentials(result.dns, result.username, result.password)
        m.home.callFunc("setStatus", "Lista carregada com sucesso")
        showHome()
    else
        m.loadingStatus.color = "#FF6B6B"
        if result <> invalid and result.message <> invalid and result.message <> ""
            m.loadingStatus.text = result.message
        else
            m.loadingStatus.text = "Não foi possível carregar a lista. Abra Conta para revisar o login."
        end if
        m.home.navigationEnabled = true
        showLogin()
        m.login.callFunc("setStatus", m.loadingStatus.text)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = LCase(key)
    if normalizedKey = "enter" then normalizedKey = "ok"
    if normalizedKey = "escape" or normalizedKey = "backspace" then normalizedKey = "back"

    if normalizedKey = "back"
        if m.login.visible
            showHome()
            return true
        end if
    end if

    return false
end function
