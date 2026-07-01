sub init()
    m.home = m.top.FindNode("home")
    m.login = m.top.FindNode("login")

    m.home.ObserveField("openLogin", "showLogin")
    m.login.ObserveField("closeLogin", "showHome")
    m.login.ObserveField("loginSuccess", "onLoginSuccess")

    showHome()
end sub

sub showHome()
    m.login.visible = false
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

sub onLoginSuccess()
    m.home.callFunc("setStatus", "Login realizado com sucesso")
    showHome()
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
