sub init()
    m.dnsInput = m.top.FindNode("dnsInput")
    m.usernameInput = m.top.FindNode("usernameInput")
    m.passwordInput = m.top.FindNode("passwordInput")
    m.enterBg = m.top.FindNode("enterBg")
    m.backBg = m.top.FindNode("backBg")
    m.status = m.top.FindNode("status")
    m.service = m.top.FindNode("service")
    m.service.ObserveField("result", "onServiceResult")

    saved = LoadXtreamCredentials()
    m.dnsInput.text = saved.dns
    m.usernameInput.text = saved.username
    m.passwordInput.text = saved.password

    m.focusIndex = 0
    updateFocus()
end sub

sub resetStatus()
    m.status.text = ""
    m.focusIndex = 0
    updateFocus()
end sub

sub setStatus(message as string)
    m.status.color = "#FF6B6B"
    m.status.text = message
end sub

sub updateFocus()
    m.dnsInput.active = false
    m.usernameInput.active = false
    m.passwordInput.active = false
    if m.focusIndex = 0 then m.dnsInput.active = true
    if m.focusIndex = 1 then m.usernameInput.active = true
    if m.focusIndex = 2 then m.passwordInput.active = true
    if m.focusIndex = 3
        m.enterBg.color = "#2F75FF"
    else
        m.enterBg.color = "#243B65"
    end if

    if m.focusIndex = 4
        m.backBg.color = "#2F75FF"
    else
        m.backBg.color = "#303038"
    end if

    if m.focusIndex = 0 then m.dnsInput.SetFocus(true)
    if m.focusIndex = 1 then m.usernameInput.SetFocus(true)
    if m.focusIndex = 2 then m.passwordInput.SetFocus(true)
    if m.focusIndex > 2 then m.top.SetFocus(true)
end sub

sub moveFocus(delta as integer)
    m.focusIndex = m.focusIndex + delta
    if m.focusIndex < 0 then m.focusIndex = 4
    if m.focusIndex > 4 then m.focusIndex = 0
    updateFocus()
end sub

sub submitLogin()
    dns = Trim(m.dnsInput.text)
    username = Trim(m.usernameInput.text)
    password = m.passwordInput.text

    if dns = "" or username = "" or password = ""
        m.status.color = "#FFB347"
        m.status.text = "Preencha DNS, usuário e senha."
        return
    end if

    m.status.color = "#FFFFFF"
    m.status.text = "Conectando..."
    m.service.dns = dns
    m.service.username = username
    m.service.password = password
    m.service.control = "RUN"
end sub

sub onServiceResult()
    result = m.service.result
    if result <> invalid and result.success = true
        SaveXtreamCredentials(result.dns, result.username, result.password)
        m.status.color = "#7CFC98"
        m.status.text = "Login realizado com sucesso"
        m.top.loginSuccess = true
    else
        m.status.color = "#FF6B6B"
        if result <> invalid and result.message <> invalid and result.message <> ""
            m.status.text = result.message
        else
            m.status.text = "Não foi possível conectar. Confira DNS, usuário e senha."
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = LCase(key)
    if normalizedKey = "enter" then normalizedKey = "ok"
    if normalizedKey = "escape" or normalizedKey = "backspace" then normalizedKey = "back"

    if normalizedKey = "back"
        m.top.closeLogin = true
        return true
    else if normalizedKey = "down"
        moveFocus(1)
        return true
    else if normalizedKey = "up"
        moveFocus(-1)
        return true
    else if normalizedKey = "left" and m.focusIndex = 4
        moveFocus(-1)
        return true
    else if normalizedKey = "right" and m.focusIndex = 3
        moveFocus(1)
        return true
    else if normalizedKey = "ok"
        if m.focusIndex = 3
            submitLogin()
            return true
        else if m.focusIndex = 4
            m.top.closeLogin = true
            return true
        end if
    end if

    return false
end function
