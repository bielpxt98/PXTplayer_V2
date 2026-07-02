sub init()
    m.home = m.top.FindNode("home")
    m.login = m.top.FindNode("login")
    m.movies = m.top.FindNode("movies")

    m.home.ObserveField("openLogin", "showLogin")
    m.home.ObserveField("openMovies", "showMovies")
    m.login.ObserveField("closeLogin", "showHome")
    m.login.ObserveField("loginSuccess", "onLoginSuccess")
    m.movies.ObserveField("closeCatalog", "showHome")
    m.movies.ObserveField("contentLoaded", "onContentLoaded")

    showHome()
end sub

sub showHome()
    m.login.visible = false
    m.movies.visible = false
    m.home.visible = true
    m.home.navigationEnabled = true
    m.home.SetFocus(true)
end sub

sub showLogin()
    if m.home.navigationEnabled <> true then return
    m.home.visible = false
    m.login.visible = true
    m.login.callFunc("resetStatus")
    m.login.SetFocus(true)
end sub


sub showMovies()
    if m.home.navigationEnabled <> true then return
    m.home.visible = false
    m.login.visible = false
    m.movies.visible = true
    m.movies.callFunc("open")
end sub

sub onLoginSuccess()
    ClearAccountErrors()
    m.home.callFunc("setStatus", "Login realizado com sucesso")
    showHome()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = NormalizeRemoteKey(key)
    if normalizedKey = "back"
        if m.login.visible
            showHome()
            return true
        else if m.movies.visible
            showHome()
            return true
        end if
    end if

    return false
end function

sub onContentLoaded()
    ClearAccountErrors()
    m.home.callFunc("clearAccountStatus")
end sub
