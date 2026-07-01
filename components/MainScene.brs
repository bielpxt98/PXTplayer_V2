sub init()
    m.home = m.top.FindNode("home")
    m.login = m.top.FindNode("login")
    m.loading = m.top.FindNode("loading")
    m.loadingStatus = m.top.FindNode("loadingStatus")
    m.startupService = m.top.FindNode("startupService")
    m.startupTimeout = m.top.FindNode("startupTimeout")
    m.startupSuccessDelay = m.top.FindNode("startupSuccessDelay")
    m.startupFinished = false

    m.home.ObserveField("openLogin", "showLogin")
    m.login.ObserveField("closeLogin", "showHome")
    m.login.ObserveField("loginSuccess", "onLoginSuccess")
    m.startupService.ObserveField("progress", "onStartupProgress")
    m.startupService.ObserveField("result", "onStartupResult")
    m.startupTimeout.ObserveField("fire", "onStartupTimeout")
    m.startupSuccessDelay.ObserveField("fire", "onStartupSuccessDelay")

    startInitialLoad()
end sub

sub startInitialLoad()
    print "iniciando login automático"
    m.startupFinished = false
    credentials = EnsureXtreamCredentialsForTest()
    showLoading("Conectando...")
    m.startupService.dns = credentials.dns
    m.startupService.username = credentials.username
    m.startupService.password = credentials.password
    m.startupService.control = "RUN"
    m.startupTimeout.control = "start"
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
    m.home.callFunc("setStatus", "Login realizado com sucesso")
    showHome()
end sub

sub onStartupProgress()
    if m.startupService.progress <> invalid and m.startupService.progress <> ""
        m.loadingStatus.color = "#FFFFFF"
        m.loadingStatus.text = m.startupService.progress
    end if
end sub

sub onStartupResult()
    if m.startupFinished = true then return
    m.startupFinished = true
    m.startupTimeout.control = "stop"
    result = m.startupService.result
    if result <> invalid and result.success = true
        SaveXtreamCredentials(result.dns, result.username, result.password)
        m.loadingStatus.color = "#7CFC98"
        m.loadingStatus.text = "Login realizado com sucesso"
        m.home.callFunc("setStatus", "Login realizado com sucesso")
        m.startupSuccessDelay.control = "start"
    else
        m.loadingStatus.color = "#FF6B6B"
        if result <> invalid and result.message <> invalid and result.message <> ""
            m.loadingStatus.text = result.message
        else
            m.loadingStatus.text = "Não foi possível conectar. Confira DNS, usuário e senha."
        end if
        m.home.navigationEnabled = true
        showLogin()
        print "erro ocorrido: " + m.loadingStatus.text
        m.login.callFunc("setStatus", m.loadingStatus.text)
    end if
end sub

sub onStartupSuccessDelay()
    showHome()
end sub

sub onStartupTimeout()
    if m.startupFinished = true then return
    m.startupFinished = true
    m.startupService.control = "STOP"
    message = "Tempo esgotado ao conectar. Confira a conexão ou revise sua conta."
    print "erro ocorrido: " + message
    m.loadingStatus.color = "#FF6B6B"
    m.loadingStatus.text = message
    m.home.navigationEnabled = true
    showLogin()
    m.login.callFunc("setStatus", message)
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
