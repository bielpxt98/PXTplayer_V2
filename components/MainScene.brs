sub init()
  m.loginScreen = m.top.findNode("loginScreen")
  m.seriesCatalogScreen = m.top.findNode("seriesCatalogScreen")
  m.xtreamService = m.top.findNode("xtreamService")

  m.loginScreen.observeField("loginRequest", "onLoginRequest")
  m.xtreamService.observeField("connectResult", "onConnectResult")
  m.seriesCatalogScreen.observeField("backToLogin", "onBackToLogin")

  m.seriesCatalogScreen.service = m.xtreamService
  showLogin()
end sub

sub showLogin()
  m.loginScreen.visible = true
  m.seriesCatalogScreen.visible = false
  m.loginScreen.setFocus(true)
end sub

sub showSeriesCatalog()
  m.loginScreen.visible = false
  m.seriesCatalogScreen.visible = true
  m.seriesCatalogScreen.setFocus(true)
  m.seriesCatalogScreen.callFunc("loadCategories")
end sub

sub onLoginRequest()
  request = m.loginScreen.loginRequest
  if request <> invalid then
    m.xtreamService.callFunc("connect", request)
  end if
end sub

sub onConnectResult()
  result = m.xtreamService.connectResult
  if result <> invalid and result.success = true then
    m.seriesCatalogScreen.account = result.account
    showSeriesCatalog()
  else if m.loginScreen <> invalid then
    m.loginScreen.loginResult = result
  end if
end sub

sub onBackToLogin()
  if m.seriesCatalogScreen.backToLogin = true then
    showLogin()
  end if
end sub
