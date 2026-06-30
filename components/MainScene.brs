sub init()
    m.loginScreen = m.top.findNode("loginScreen")
    m.successScreen = m.top.findNode("successScreen")
    m.xtreamService = m.top.findNode("xtreamService")
    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.successScreen.observeField("backRequested", "onSuccessBackRequested")
    m.xtreamService.observeField("result", "onXtreamResult")
    m.connecting = false
    m.loginScreen.account = LoadPlaylistAccount()
    showLogin()
end sub

sub showLogin()
    m.successScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.setFocus(true)
end sub

sub showSuccess()
    m.loginScreen.visible = false
    m.successScreen.visible = true
    m.successScreen.setFocus(true)
end sub

sub onLoginSubmit(event as object)
    if m.connecting then return
    credentials = event.getData()
    dns = NormalizeDns(credentials.dns)
    if dns = "" or PxtTrim(credentials.username) = "" or PxtTrim(credentials.password) = ""
        m.loginScreen.message = "Preencha DNS, usuário e senha."
        return
    end if
    m.connecting = true
    m.loginScreen.loading = true
    m.loginScreen.message = "Conectando..."
    m.xtreamService.request = { dns: dns, username: credentials.username, password: credentials.password }
end sub

sub onXtreamResult(event as object)
    result = event.getData()
    m.connecting = false
    m.loginScreen.loading = false
    if result.success = true
        SavePlaylistAccount(result.dns, result.username, result.password)
        m.loginScreen.message = ""
        showSuccess()
    else
        m.loginScreen.message = result.message
        showLogin()
    end if
end sub

sub onLoginBackRequested()
    if m.connecting then return
    m.top.getScene().close = true
end sub

sub onSuccessBackRequested()
    showLogin()
end sub
