sub init()
    m.dnsInput = m.top.FindNode("dnsInput")
    m.usernameInput = m.top.FindNode("usernameInput")
    m.passwordInput = m.top.FindNode("passwordInput")
    m.enterBg = m.top.FindNode("enterBg")
    m.enterLabel = m.top.FindNode("enterLabel")
    m.backBg = m.top.FindNode("backBg")
    m.status = m.top.FindNode("status")
    m.service = m.top.FindNode("service")
    m.keyboard = m.top.FindNode("keyboard")
    m.service.ObserveField("result", "onServiceResult")
    m.service.ObserveField("progress", "onServiceProgress")
    m.service.ObserveField("debug", "onServiceDebug")
    m.keyboard.ObserveField("buttonSelected", "onKeyboardButton")

    saved = LoadXtreamCredentials()
    m.dnsInput.text = saved.dns
    m.usernameInput.text = saved.username
    m.passwordInput.text = saved.password

    m.focusIndex = 0
    m.editingIndex = -1
    m.loginInProgress = false
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
    if m.loginInProgress = true
        m.enterBg.color = "#4B4B55"
        m.enterLabel.text = "AGUARDE"
    else if m.focusIndex = 3
        m.enterBg.color = "#2F75FF"
        m.enterLabel.text = "ENTRAR"
    else
        m.enterBg.color = "#243B65"
        m.enterLabel.text = "ENTRAR"
    end if

    if m.focusIndex = 4
        m.backBg.color = "#2F75FF"
    else
        m.backBg.color = "#303038"
    end if

    m.top.SetFocus(true)
end sub

sub moveFocus(delta as integer)
    m.focusIndex = m.focusIndex + delta
    if m.focusIndex < 0 then m.focusIndex = 4
    if m.focusIndex > 4 then m.focusIndex = 0
    updateFocus()
end sub

sub openKeyboard()
    m.editingIndex = m.focusIndex
    if m.focusIndex = 0
        m.dnsInput.SetFocus(true)
    else if m.focusIndex = 1
        m.usernameInput.SetFocus(true)
    else if m.focusIndex = 2
        m.passwordInput.SetFocus(true)
    else
        m.editingIndex = -1
        return
    end if
end sub

sub closeKeyboard(applyValue as boolean)
    if m.top.GetScene().dialog <> invalid
        if applyValue
            if m.editingIndex = 0 then m.dnsInput.text = m.keyboard.text
            if m.editingIndex = 1 then m.usernameInput.text = m.keyboard.text
            if m.editingIndex = 2 then m.passwordInput.text = m.keyboard.text
        end if
        m.top.GetScene().dialog = invalid
    end if
    if m.editingIndex >= 0 then m.focusIndex = m.editingIndex
    m.editingIndex = -1
    updateFocus()
end sub

sub onKeyboardButton()
    if m.keyboard.buttonSelected = 0
        closeKeyboard(true)
    else if m.keyboard.buttonSelected = 1
        closeKeyboard(false)
    end if
end sub

sub submitLogin()
    if m.loginInProgress = true then return

    dns = Trim(m.dnsInput.text)
    username = Trim(m.usernameInput.text)
    password = m.passwordInput.text

    if dns = "" or username = "" or password = ""
        m.status.color = "#FFB347"
        m.status.text = "Preencha DNS, usuário e senha."
        return
    end if

    m.loginInProgress = true
    updateFocus()
    m.status.color = "#FFFFFF"
    m.status.text = "Conectando..." + Chr(10) + "Preparando conexão" + Chr(10) + "DNS usado: " + dns
    m.service.control = "STOP"
    m.service.dns = dns
    m.service.username = username
    m.service.password = password
    m.service.control = "RUN"
end sub

sub onServiceProgress()
    if m.service.progress <> invalid and m.service.progress <> ""
        m.status.color = "#FFFFFF"
        m.status.text = m.service.progress
    end if
end sub

sub onServiceDebug()
    if m.service.debug <> invalid and m.service.debug <> ""
        m.status.color = "#FFFFFF"
        m.status.text = m.service.debug
    end if
end sub

sub onServiceResult()
    result = m.service.result
    m.loginInProgress = false
    updateFocus()
    if result <> invalid and result.success = true
        SaveXtreamCredentials(result.dns, result.username, result.password)
        m.status.color = "#7CFC98"
        m.status.text = "Login realizado com sucesso"
        m.top.loginSuccess = true
    else
        m.status.color = "#FF6B6B"
        if result <> invalid and result.debug <> invalid and result.debug <> ""
            m.status.text = result.debug
        else if result <> invalid and result.errorMessage <> invalid and result.errorMessage <> ""
            m.status.text = "Erro: " + result.errorMessage
        else if result <> invalid and result.message <> invalid and result.message <> ""
            m.status.text = result.message
        else
            m.status.text = "Falha desconhecida no login Xtream."
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = NormalizeRemoteKey(key)

    if m.editingIndex >= 0
        if normalizedKey = "ok"
            closeKeyboard(true)
            return true
        else if normalizedKey = "back" and LCase(key) <> "backspace"
            closeKeyboard(false)
            return true
        end if

        ' Let TextEditBox handle normal typing plus Backspace/Delete while editing.
        return false
    end if

    if m.top.GetScene().dialog <> invalid
        if normalizedKey = "back"
            closeKeyboard(false)
            return true
        end if
        return false
    end if

    if normalizedKey = "back"
        m.top.closeLogin = true
        return true
    else if normalizedKey = "down"
        moveFocus(1)
        return true
    else if normalizedKey = "up"
        moveFocus(-1)
        return true
    else if normalizedKey = "left"
        moveFocus(-1)
        return true
    else if normalizedKey = "right"
        moveFocus(1)
        return true
    else if normalizedKey = "ok"
        if m.focusIndex >= 0 and m.focusIndex <= 2
            openKeyboard()
            return true
        else if m.focusIndex = 3
            if m.loginInProgress <> true then submitLogin()
            return true
        else if m.focusIndex = 4
            m.top.closeLogin = true
            return true
        end if
    end if

    return false
end function
