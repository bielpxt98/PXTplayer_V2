sub init()
    m.dnsInput = m.top.FindNode("dnsInput")
    m.usernameInput = m.top.FindNode("usernameInput")
    m.passwordInput = m.top.FindNode("passwordInput")
    m.enterBg = m.top.FindNode("enterBg")
    m.enterLabel = m.top.FindNode("enterLabel")
    m.backBg = m.top.FindNode("backBg")
    m.status = m.top.FindNode("status")
    m.service = m.top.FindNode("service")
    m.keyboard = invalid
    m.service.ObserveField("result", "onServiceResult")
    m.service.ObserveField("progress", "onServiceProgress")
    m.service.ObserveField("debug", "onServiceDebug")

    saved = LoadXtreamCredentials()
    m.dnsValue = saved.dns
    m.usernameValue = saved.username
    m.passwordValue = saved.password
    syncInputText()

    m.focusIndex = 0
    m.editingIndex = -1
    m.loginInProgress = false
    m.editOriginalValue = ""
    m.closingKeyboard = false
    updateFocus()
end sub

function maskText(value as string) as string
    if value = invalid or value = "" then return ""
    masked = ""
    for i = 1 to Len(value)
        masked = masked + "*"
    end for
    return masked
end function

sub syncInputText()
    m.dnsInput.text = m.dnsValue
    m.usernameInput.text = m.usernameValue
    m.passwordInput.text = maskText(m.passwordValue)
end sub

function getValueForIndex(index as integer) as string
    if index = 0 then return m.dnsValue
    if index = 1 then return m.usernameValue
    if index = 2 then return m.passwordValue
    return ""
end function

sub setValueForIndex(index as integer, value as string)
    if value = invalid then value = ""
    if index = 0
        m.dnsValue = value
    else if index = 1
        m.usernameValue = value
    else if index = 2
        m.passwordValue = value
    end if
    syncInputText()
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
    m.editOriginalValue = getValueForIndex(m.editingIndex)

    if m.keyboard <> invalid
        m.keyboard.UnobserveField("buttonSelected")
    end if

    m.keyboard = CreateObject("roSGNode", "KeyboardDialog")
    if m.editingIndex = 0
        m.keyboard.title = "DNS"
    else if m.editingIndex = 1
        m.keyboard.title = "Usuário"
    else
        m.keyboard.title = "Senha"
    end if
    m.keyboard.text = m.editOriginalValue
    m.keyboard.buttons = ["OK", "Cancelar"]
    m.keyboard.ObserveField("buttonSelected", "onKeyboardButton")
    m.keyboard.ObserveField("wasClosed", "onKeyboardClosed")

    input.active = true
    scene = m.top.GetScene()
    scene.dialog = m.keyboard
end sub

sub closeKeyboard(applyValue as boolean)
    if m.closingKeyboard = true then return
    m.closingKeyboard = true

    if m.editingIndex >= 0
        if applyValue = true and m.keyboard <> invalid
            setValueForIndex(m.editingIndex, m.keyboard.text)
        else
            setValueForIndex(m.editingIndex, m.editOriginalValue)
        end if
        m.focusIndex = m.editingIndex
    end if

    scene = m.top.GetScene()
    if scene <> invalid then scene.dialog = invalid
    if m.keyboard <> invalid
        m.keyboard.UnobserveField("buttonSelected")
        m.keyboard.UnobserveField("wasClosed")
    end if
    m.keyboard = invalid
    m.editingIndex = -1
    m.editOriginalValue = ""
    m.closingKeyboard = false
    updateFocus()
end sub

sub onKeyboardClosed()
    if m.closingKeyboard <> true then closeKeyboard(false)
end sub

sub onKeyboardButton()
    if m.keyboard = invalid then return
    if m.keyboard.buttonSelected = 0
        closeKeyboard(true)
    else if m.keyboard.buttonSelected = 1
        closeKeyboard(false)
    end if
end sub

sub submitLogin()
    if m.loginInProgress = true then return

    dns = Trim(m.dnsValue)
    username = Trim(m.usernameValue)
    password = m.passwordValue

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

    if m.top.GetScene().dialog <> invalid
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
