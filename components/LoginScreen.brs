sub init()
    m.dns = ""
    m.username = ""
    m.password = ""
    m.keyboardField = ""
    m.keyboardValue = ""
    m.keyboardActive = false
    m.keyboardIndex = 0
    m.keyboardColumns = 12
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
    m.statusLabel = m.top.findNode("statusLabel")
    m.enterButton = m.top.findNode("enterButton")
    m.backButton = m.top.findNode("backButton")
    m.keyboardGroup = m.top.findNode("keyboardGroup")
    m.keyboardBackground = m.top.findNode("keyboardBackground")
    m.keyboardTitle = m.top.findNode("keyboardTitle")
    m.keyboardInputBox = m.top.findNode("keyboardInputBox")
    m.keyboardInputText = m.top.findNode("keyboardInputText")
    m.keyboardKeysGroup = m.top.findNode("keyboardKeysGroup")

    m.boxes = [m.dnsBox, m.usernameBox, m.passwordBox]
    m.labels = [m.dnsLabel, m.usernameLabel, m.passwordLabel]
    m.keyboardKeys = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "/", ":", "-", "_", "APAGAR", "ESPAÇO", "OK", "CANCELAR"]
    m.keyboardKeyGroups = []
    m.keyboardKeyBoxes = []
    m.keyboardKeyLabels = []

    createKeyboardKeys()
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

    m.statusLabel.translation = [0, (rowSpacing * 3) + 5]
    buttonY = (rowSpacing * 3) + 65
    m.enterButton.translation = [0, buttonY]
    m.backButton.translation = [600, buttonY]

    m.keyboardGroup.translation = [(width - 1120) / 2, (height - 560) / 2]
    m.keyboardTitle.translation = [0, 18]
    m.keyboardInputBox.translation = [50, 92]
    m.keyboardInputText.translation = [70, 92]
    m.keyboardKeysGroup.translation = [50, 190]
    layoutKeyboardKeys()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.top.busy = true then return true
    if m.keyboardActive = true then return handleKeyboardKey(key)

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
    m.keyboardActive = true
    m.keyboardIndex = 0

    if fieldName = "dns"
        m.keyboardTitle.text = "DNS"
        m.keyboardValue = m.dns
        PRINT "CUSTOM_KEYBOARD_OPEN field=dns"
    else if fieldName = "username"
        m.keyboardTitle.text = "USUÁRIO"
        m.keyboardValue = m.username
        PRINT "CUSTOM_KEYBOARD_OPEN field=username"
    else if fieldName = "password"
        m.keyboardTitle.text = "SENHA"
        m.keyboardValue = m.password
        PRINT "CUSTOM_KEYBOARD_OPEN field=password"
    end if

    m.keyboardGroup.visible = true
    updateKeyboardText()
    updateKeyboardFocus()
end sub

function handleKeyboardKey(key as string) as boolean
    if key = "left"
        if m.keyboardIndex > 0 then m.keyboardIndex = m.keyboardIndex - 1
        updateKeyboardFocus()
        return true
    else if key = "right"
        if m.keyboardIndex < m.keyboardKeys.count() - 1 then m.keyboardIndex = m.keyboardIndex + 1
        updateKeyboardFocus()
        return true
    else if key = "up"
        if m.keyboardIndex - m.keyboardColumns >= 0 then m.keyboardIndex = m.keyboardIndex - m.keyboardColumns
        updateKeyboardFocus()
        return true
    else if key = "down"
        if m.keyboardIndex + m.keyboardColumns < m.keyboardKeys.count() then m.keyboardIndex = m.keyboardIndex + m.keyboardColumns
        updateKeyboardFocus()
        return true
    else if key = "OK"
        chooseKeyboardKey()
        return true
    else if key = "back"
        closeKeyboard(false)
        return true
    end if

    return true
end function

sub chooseKeyboardKey()
    selectedKey = m.keyboardKeys[m.keyboardIndex]

    if selectedKey = "APAGAR"
        if Len(m.keyboardValue) > 0 then m.keyboardValue = Left(m.keyboardValue, Len(m.keyboardValue) - 1)
    else if selectedKey = "ESPAÇO"
        m.keyboardValue = m.keyboardValue + " "
    else if selectedKey = "OK"
        closeKeyboard(true)
        return
    else if selectedKey = "CANCELAR"
        closeKeyboard(false)
        return
    else
        m.keyboardValue = m.keyboardValue + selectedKey
    end if

    updateKeyboardText()
end sub

sub closeKeyboard(saveValue as boolean)
    if saveValue = true
        if m.keyboardField = "dns"
            m.dns = Left(m.keyboardValue, 200)
        else if m.keyboardField = "username"
            m.username = Left(m.keyboardValue, 100)
        else if m.keyboardField = "password"
            m.password = Left(m.keyboardValue, 100)
        end if

        PRINT "CUSTOM_KEYBOARD_SAVE"
        updateTexts()
    end if

    m.keyboardActive = false
    m.keyboardGroup.visible = false
    m.top.setFocus(true)
    updateFocus()
end sub

sub submitLogin()
    if m.top.busy = true then return
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

sub createKeyboardKeys()
    for i = 0 to m.keyboardKeys.count() - 1
        keyGroup = CreateObject("roSGNode", "Group")
        keyBox = CreateObject("roSGNode", "Rectangle")
        keyLabel = CreateObject("roSGNode", "Label")

        keyBox.width = 76
        keyBox.height = 42
        keyBox.color = "0x102033FF"
        keyLabel.width = 76
        keyLabel.height = 42
        keyLabel.text = m.keyboardKeys[i]
        keyLabel.color = "0xFFFFFFFF"
        keyLabel.horizAlign = "center"
        keyLabel.vertAlign = "center"
        keyLabel.font = "font:SmallBoldSystemFont"

        keyGroup.appendChild(keyBox)
        keyGroup.appendChild(keyLabel)
        m.keyboardKeysGroup.appendChild(keyGroup)
        m.keyboardKeyGroups.push(keyGroup)
        m.keyboardKeyBoxes.push(keyBox)
        m.keyboardKeyLabels.push(keyLabel)
    end for
end sub

sub layoutKeyboardKeys()
    for i = 0 to m.keyboardKeyGroups.count() - 1
        row = Int(i / m.keyboardColumns)
        col = i MOD m.keyboardColumns
        keyWidth = 76
        if m.keyboardKeys[i] = "APAGAR" or m.keyboardKeys[i] = "ESPAÇO" or m.keyboardKeys[i] = "CANCELAR" then keyWidth = 130
        m.keyboardKeyBoxes[i].width = keyWidth
        m.keyboardKeyLabels[i].width = keyWidth
        m.keyboardKeyGroups[i].translation = [col * 86, row * 54]
    end for
end sub

sub updateKeyboardFocus()
    for i = 0 to m.keyboardKeyBoxes.count() - 1
        if i = m.keyboardIndex
            m.keyboardKeyBoxes[i].color = "0x2A73D9FF"
        else
            m.keyboardKeyBoxes[i].color = "0x102033FF"
        end if
    end for
end sub

sub updateKeyboardText()
    if m.keyboardField = "password"
        m.keyboardInputText.text = maskText(m.keyboardValue)
    else
        m.keyboardInputText.text = m.keyboardValue
    end if
end sub

sub onBusyChanged()
    updateFocus()
end sub

sub onStatusMessageChanged()
    if m.top.statusMessage = invalid
        m.statusLabel.text = ""
    else
        m.statusLabel.text = m.top.statusMessage
    end if
end sub
