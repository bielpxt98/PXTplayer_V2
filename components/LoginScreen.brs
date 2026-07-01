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
    m.editOriginalValue = ""
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

function getFocusedInput() as object
    if m.focusIndex = 0 then return m.dnsInput
    if m.focusIndex = 1 then return m.usernameInput
    if m.focusIndex = 2 then return m.passwordInput
    return invalid
end function

function getEditingInput() as object
    if m.editingIndex = 0 then return m.dnsInput
    if m.editingIndex = 1 then return m.usernameInput
    if m.editingIndex = 2 then return m.passwordInput
    return invalid
end function

sub openKeyboard()
    input = getFocusedInput()
    if input = invalid
        m.editingIndex = -1
        return
    end if

    m.editingIndex = m.focusIndex
    m.editOriginalValue = input.text
    input.active = true
    input.SetFocus(true)
end sub

sub closeKeyboard(applyValue as boolean)
    input = getEditingInput()
    if input <> invalid and applyValue <> true
        input.text = m.editOriginalValue
    end if
    if m.editingIndex >= 0 then m.focusIndex = m.editingIndex
    m.editingIndex = -1
    m.editOriginalValue = ""
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


function textCharacterFromKey(key as string) as string
    if key = invalid then return ""

    rawKey = key
    lowerKey = LCase(rawKey)

    if Len(rawKey) = 1
        code = Asc(rawKey)
        if (code >= 32 and code <= 126) then return rawKey
    end if

    if Left(lowerKey, 4) = "lit_" and Len(rawKey) = 5
        return Mid(rawKey, 5, 1)
    end if

    if Left(lowerKey, 4) = "key" and Len(rawKey) = 4
        digit = Mid(rawKey, 4, 1)
        if digit >= "0" and digit <= "9" then return digit
    end if

    if Left(lowerKey, 6) = "numpad" and Len(rawKey) = 7
        digit = Mid(rawKey, 7, 1)
        if digit >= "0" and digit <= "9" then return digit
    end if

    if lowerKey = "space" then return " "
    if lowerKey = "period" or lowerKey = "numpaddecimal" or lowerKey = "decimal" or lowerKey = "kpdecimal" then return "."
    if lowerKey = "slash" or lowerKey = "forwardslash" then return "/"
    if lowerKey = "colon" then return ":"
    if lowerKey = "semicolon" then return ":"
    if lowerKey = "minus" or lowerKey = "hyphen" or lowerKey = "dash" then return "-"

    return ""
end function

function handleTextEditingKey(key as string, normalizedKey as string) as boolean
    input = getEditingInput()
    if input = invalid then return false

    if normalizedKey = "ok"
        closeKeyboard(true)
        return true
    else if normalizedKey = "back" and LCase(key) <> "backspace"
        closeKeyboard(false)
        return true
    else if LCase(key) = "escape"
        closeKeyboard(false)
        return true
    else if LCase(key) = "backspace"
        if Len(input.text) > 0 then input.text = Left(input.text, Len(input.text) - 1)
        return true
    else if normalizedKey = "delete"
        if Len(input.text) > 0 then input.text = Left(input.text, Len(input.text) - 1)
        return true
    end if

    char = textCharacterFromKey(key)
    if char <> ""
        input.text = input.text + char
        return true
    end if

    return false
end function

function isPointInsideNode(node as object, x as float, y as float) as boolean
    bounds = node.boundingRect()
    return x >= bounds.x and x <= (bounds.x + bounds.width) and y >= bounds.y and y <= (bounds.y + bounds.height)
end function

function onMouseEvent(event as object) as boolean
    if event = invalid then return false
    if event.isButtonPressed() <> true then return false

    x = event.getX()
    y = event.getY()

    if isPointInsideNode(m.dnsInput, x, y)
        m.focusIndex = 0
        updateFocus()
        openKeyboard()
        return true
    else if isPointInsideNode(m.usernameInput, x, y)
        m.focusIndex = 1
        updateFocus()
        openKeyboard()
        return true
    else if isPointInsideNode(m.passwordInput, x, y)
        m.focusIndex = 2
        updateFocus()
        openKeyboard()
        return true
    else if isPointInsideNode(m.enterBg, x, y)
        m.focusIndex = 3
        updateFocus()
        if m.loginInProgress <> true then submitLogin()
        return true
    else if isPointInsideNode(m.backBg, x, y)
        m.focusIndex = 4
        updateFocus()
        m.top.closeLogin = true
        return true
    end if

    return false
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = NormalizeRemoteKey(key)

    if m.editingIndex >= 0
        return handleTextEditingKey(key, normalizedKey)
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
