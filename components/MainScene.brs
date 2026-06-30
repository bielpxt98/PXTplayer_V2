sub init()
    m.homeScreen = m.top.findNode("homeScreen")
    m.loginScreen = m.top.findNode("loginScreen")
    m.loadingScreen = m.top.findNode("loadingScreen")
    m.accountScreen = m.top.findNode("accountScreen")
    m.liveTVScreen = m.top.findNode("liveTVScreen")
    m.currentCredentials = invalid
    m.authMode = ""

    m.homeScreen.observeField("openLiveTV", "onOpenLiveTV")
    m.homeScreen.observeField("openAccount", "onOpenAccount")
    m.loginScreen.observeField("submit", "onLoginSubmit")
    m.loginScreen.observeField("backRequested", "onLoginBackRequested")
    m.loadingScreen.observeField("loadingFinished", "onLoadingFinished")
    m.accountScreen.observeField("backRequested", "onAccountBackRequested")
    m.accountScreen.observeField("removeRequested", "onRemoveAccountRequested")
    m.liveTVScreen.observeField("backRequested", "onLiveTVBackRequested")

    m.top.observeField("width", "layoutScene")
    m.top.observeField("height", "layoutScene")
    layoutScene()

    savedCredentials = loadSavedCredentials()
    if savedCredentials <> invalid
        validateCredentials(savedCredentials, "startup")
    else
        showLoginScreen("")
    end if
end sub

sub layoutScene()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.homeScreen.width = width
    m.homeScreen.height = height
    m.loginScreen.width = width
    m.loginScreen.height = height
    m.loadingScreen.width = width
    m.loadingScreen.height = height
    m.accountScreen.width = width
    m.accountScreen.height = height
    m.liveTVScreen.width = width
    m.liveTVScreen.height = height
end sub

sub validateCredentials(credentials as object, mode as string)
    m.authMode = mode
    m.loginScreen.busy = true
    m.loginScreen.statusMessage = "Conectando..."
    task = CreateObject("roSGNode", "XtreamService")
    task.action = "connect"
    task.dns = credentials.dns
    task.username = credentials.username
    task.password = credentials.password
    task.observeField("result", "onAuthResult")
    m.authTask = task
    task.control = "RUN"
end sub

sub onAuthResult(event as object)
    result = event.getData()
    m.loginScreen.busy = false
    PRINT "LOGIN_LOADING_OFF"
    if result = invalid then result = { success: false, message: "Não foi possível conectar ao servidor.", error: "network" }

    if result.success = true
        m.currentCredentials = result.credentials
        saveCredentials(m.currentCredentials)
        m.loginScreen.statusMessage = "Conectado com sucesso."
        showLoadingScreen()
    else
        if m.authMode = "startup" then clearSavedCredentials()
        m.loginScreen.statusMessage = result.message
        showLoginScreen(result.message)
    end if

    m.authTask = invalid
end sub

sub showHomeScreen()
    m.loginScreen.visible = false
    m.loadingScreen.visible = false
    m.accountScreen.visible = false
    m.liveTVScreen.visible = false
    m.homeScreen.visible = true
    m.homeScreen.callFunc("setHomeFocus")
    PRINT "HOME_SCREEN_OPENED"
end sub

sub showLoadingScreen()
    m.homeScreen.visible = false
    m.loginScreen.visible = false
    m.accountScreen.visible = false
    m.liveTVScreen.visible = false
    m.loadingScreen.visible = true
    m.loadingScreen.callFunc("startLoading")
end sub

sub showLoginScreen(message as string)
    m.homeScreen.visible = false
    m.loadingScreen.visible = false
    m.accountScreen.visible = false
    m.liveTVScreen.visible = false
    m.loginScreen.visible = true
    m.loginScreen.statusMessage = message
    m.loginScreen.callFunc("setLoginFocus")
    PRINT "LOGIN_SCREEN_OPENED"
end sub

sub showAccountScreen()
    m.homeScreen.visible = false
    m.loginScreen.visible = false
    m.loadingScreen.visible = false
    m.liveTVScreen.visible = false
    m.accountScreen.visible = true
    account = { status: "Conectado" }
    if m.currentCredentials <> invalid
        account.dns = m.currentCredentials.dns
        account.username = m.currentCredentials.username
    end if
    m.accountScreen.account = account
    m.accountScreen.callFunc("setAccountFocus")
    PRINT "ACCOUNT_SCREEN_OPENED"
end sub


sub showLiveTVScreen()
    m.homeScreen.visible = false
    m.loginScreen.visible = false
    m.loadingScreen.visible = false
    m.accountScreen.visible = false
    m.liveTVScreen.visible = true
    m.liveTVScreen.credentials = m.currentCredentials
    m.liveTVScreen.callFunc("setLiveTVFocus")
    PRINT "LIVE_TV_SCREEN_OPENED"
end sub

sub onLoadingFinished()
    showHomeScreen()
end sub

sub onOpenLiveTV()
    showLiveTVScreen()
end sub

sub onOpenAccount()
    showAccountScreen()
end sub

sub onLoginSubmit(event as object)
    loginData = event.getData()
    PRINT "LOGIN_SUBMIT"
    validateCredentials(loginData, "login")
end sub

sub onLoginBackRequested()
    PRINT "LOGIN_BACK_REQUESTED"
end sub

sub onAccountBackRequested()
    showHomeScreen()
end sub

sub onLiveTVBackRequested()
    showHomeScreen()
end sub

sub onRemoveAccountRequested()
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Deseja remover esta conta?"
    dialog.buttons = ["SIM", "NÃO"]
    dialog.observeField("buttonSelected", "onRemoveDialogButtonSelected")
    m.top.dialog = dialog
end sub

sub onRemoveDialogButtonSelected(event as object)
    dialog = event.getRoSGNode()
    selected = dialog.buttonSelected
    m.top.dialog = invalid

    if selected = 0
        clearSavedCredentials()
        m.currentCredentials = invalid
        showLoginScreen("")
    else
        m.accountScreen.callFunc("setAccountFocus")
    end if
end sub

function loadSavedCredentials() as object
    section = CreateObject("roRegistrySection", "pxtplayer_auth")
    if section.Exists("dns") and section.Exists("username") and section.Exists("password")
        return { dns: section.Read("dns"), username: section.Read("username"), password: section.Read("password") }
    end if
    return invalid
end function

sub saveCredentials(credentials as object)
    section = CreateObject("roRegistrySection", "pxtplayer_auth")
    section.Write("dns", credentials.dns)
    section.Write("username", credentials.username)
    section.Write("password", credentials.password)
    section.Flush()
end sub

sub clearSavedCredentials()
    section = CreateObject("roRegistrySection", "pxtplayer_auth")
    section.Delete("dns")
    section.Delete("username")
    section.Delete("password")
    section.Flush()
end sub
