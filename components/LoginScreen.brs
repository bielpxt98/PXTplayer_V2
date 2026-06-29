sub init()
    m.dns = ""
    m.username = ""
    m.password = ""
    m.focusIndex = 0
    m.loading = false
    m.keyboardField = ""
    m.boxes = [m.top.findNode("dnsBox"), m.top.findNode("userBox"), m.top.findNode("passwordBox"), m.top.findNode("enterButton"), m.top.findNode("backButton")]
    m.spinner = m.top.findNode("spinner")
    m.messageLabel = m.top.findNode("messageLabel")
    m.top.setFocus(true)
    updateTexts()
    updateFocus()
end sub

sub onAccountChanged()
    account = m.top.account
    if account <> invalid
        m.dns = PxtTrim(account.dns)
        m.username = PxtTrim(account.username)
        m.password = PxtTrim(account.password)
        updateTexts()
    end if
end sub

sub onLoadingChanged()
    m.loading = m.top.loading
    m.spinner.visible = m.loading
    if m.loading then
        m.spinner.control = "start"
    else
        m.spinner.control = "stop"
    end if
    updateFocus()
end sub

sub onMessageChanged()
    m.messageLabel.text = m.top.message
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.loading then return true

    if key = "up"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
        if m.focusIndex = 4 then m.focusIndex = 3
        updateFocus()
        return true
    else if key = "down"
        if m.focusIndex < 3 then m.focusIndex = m.focusIndex + 1
        updateFocus()
        return true
    else if key = "left" or key = "right"
        if m.focusIndex = 3 then m.focusIndex = 4 else if m.focusIndex = 4 then m.focusIndex = 3
        updateFocus()
        return true
    else if key = "OK"
        activateFocused()
        return true
    else if key = "back"
        m.top.backRequested = true
        return true
    end if
    return false
end function

sub activateFocused()
    if m.focusIndex = 0 then openKeyboard("dns")
    if m.focusIndex = 1 then openKeyboard("username")
    if m.focusIndex = 2 then openKeyboard("password")
    if m.focusIndex = 3 then submitLogin()
    if m.focusIndex = 4 then m.top.backRequested = true
end sub

sub openKeyboard(fieldName as string)
    m.keyboardField = fieldName
    dialog = CreateObject("roSGNode", "StandardKeyboardDialog")
    dialog.title = fieldName
    if fieldName = "dns" then dialog.text = m.dns
    if fieldName = "username" then dialog.text = m.username
    if fieldName = "password"
        dialog.text = m.password
        dialog.secureMode = true
    end if
    dialog.buttons = ["OK", "Cancelar"]
    dialog.observeField("buttonSelected", "onKeyboardButtonSelected")
    m.top.getScene().dialog = dialog
end sub

sub onKeyboardButtonSelected(event as object)
    dialog = event.getRoSGNode()
    if dialog.buttonSelected = 0
        value = PxtTrim(dialog.text)
        if m.keyboardField = "dns" then m.dns = Left(value, 200)
        if m.keyboardField = "username" then m.username = Left(value, 100)
        if m.keyboardField = "password" then m.password = Left(value, 100)
        updateTexts()
    end if
    m.top.getScene().dialog = invalid
end sub

sub submitLogin()
    dns = PxtTrim(m.dns)
    username = PxtTrim(m.username)
    password = PxtTrim(m.password)
    if dns = "" or username = "" or password = ""
        m.top.message = "Preencha DNS, usuário e senha."
        return
    end if
    m.top.submit = { dns: dns, username: username, password: password }
end sub

sub updateTexts()
    m.top.findNode("dnsText").text = m.dns
    m.top.findNode("userText").text = m.username
    m.top.findNode("passwordText").text = MaskText(m.password)
end sub

sub updateFocus()
    for i = 0 to m.boxes.count() - 1
        if i = m.focusIndex and not m.loading
            m.boxes[i].color = "0x2A73D9FF"
        else
            m.boxes[i].color = "0x102C55FF"
        end if
    end for
end sub
