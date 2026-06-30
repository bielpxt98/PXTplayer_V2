sub init()
    m.dns = ""
    m.username = ""
    m.password = ""
    m.keyboardField = ""
    m.focusIndex = 0

    m.background = m.top.findNode("background")
    m.titleLabel = m.top.findNode("titleLabel")
    m.formGroup = m.top.findNode("formGroup")
    m.dnsLabel = m.top.findNode("dnsLabel")
    m.dnsBox = m.top.findNode("dnsBox")
    m.dnsText = m.top.findNode("dnsText")
    m.usernameLabel = m.top.findNode("usernameLabel")
    m.usernameBox = m.top.findNode("usernameBox")
    m.usernameText = m.top.findNode("usernameText")
    m.passwordLabel = m.top.findNode("passwordLabel")
    m.passwordBox = m.top.findNode("passwordBox")
    m.passwordText = m.top.findNode("passwordText")
    m.enterButton = m.top.findNode("enterButton")
    m.backButton = m.top.findNode("backButton")

    m.boxes = [m.dnsBox, m.usernameBox, m.passwordBox]
    m.labels = [m.dnsLabel, m.usernameLabel, m.passwordLabel]

    m.top.observeField("width", "layoutLogin")
    m.top.observeField("height", "layoutLogin")
    layoutLogin()
    updateTexts()
    updateFocus()
end sub

sub setLoginFocus()
    m.top.setFocus(true)
    updateFocus()
end sub

sub layoutLogin()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.background.width = width
    m.background.height = height
    m.titleLabel.width = width
    m.titleLabel.translation = [0, 170]
    m.formGroup.translation = [(width - 720) / 2, 300]

    rowSpacing = 138
    for i = 0 to m.boxes.count() - 1
        labelY = i * rowSpacing
        boxY = labelY + 42
        m.labels[i].translation = [0, labelY]
        m.boxes[i].translation = [0, boxY]
    end for

    m.dnsText.translation = [20, 42]
    m.usernameText.translation = [20, 42 + rowSpacing]
    m.passwordText.translation = [20, 42 + (rowSpacing * 2)]

    buttonY = (rowSpacing * 3) + 55
    m.enterButton.translation = [0, buttonY]
    m.backButton.translation = [600, buttonY]
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

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
        if m.focusIndex = 3
            m.focusIndex = 4
        else if m.focusIndex = 4
            m.focusIndex = 3
        end if
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
    dialog.buttons = ["OK", "Cancelar"]

    if fieldName = "dns"
        dialog.title = "DNS"
        dialog.text = m.dns
    else if fieldName = "username"
        dialog.title = "USUÁRIO"
        dialog.text = m.username
    else if fieldName = "password"
        dialog.title = "SENHA"
        dialog.text = m.password
        dialog.secureMode = true
    end if

    dialog.observeField("buttonSelected", "onKeyboardButtonSelected")
    m.top.getScene().dialog = dialog
end sub

sub onKeyboardButtonSelected(event as object)
    dialog = event.getRoSGNode()

    if dialog.buttonSelected = 0
        value = dialog.text
        if value = invalid then value = ""

        if m.keyboardField = "dns"
            m.dns = Left(value, 200)
        else if m.keyboardField = "username"
            m.username = Left(value, 100)
        else if m.keyboardField = "password"
            m.password = Left(value, 100)
        end if

        updateTexts()
    end if

    m.top.getScene().dialog = invalid
    m.top.setFocus(true)
end sub

sub submitLogin()
    m.top.submit = {
        dns: m.dns
        username: m.username
        password: m.password
    }
end sub

sub updateTexts()
    if m.dns = ""
        m.dnsText.text = "http://servidor.com"
        m.dnsText.color = "0x7C8EA8FF"
    else
        m.dnsText.text = m.dns
        m.dnsText.color = "0xFFFFFFFF"
    end if

    m.usernameText.text = m.username
    m.usernameText.color = "0xFFFFFFFF"
    m.passwordText.text = maskText(m.password)
    m.passwordText.color = "0xFFFFFFFF"
end sub

sub updateFocus()
    for i = 0 to m.boxes.count() - 1
        if i = m.focusIndex
            m.boxes[i].color = "0x2A73D9FF"
            m.labels[i].color = "0xFFFFFFFF"
        else
            m.boxes[i].color = "0x102033FF"
            m.labels[i].color = "0xD8E6FFFF"
        end if
    end for

    m.enterButton.selected = (m.focusIndex = 3)
    m.backButton.selected = (m.focusIndex = 4)
end sub

function maskText(value as string) as string
    masked = ""
    if value = invalid then return masked

    for i = 1 to Len(value)
        masked = masked + "*"
    end for

    return masked
end function
