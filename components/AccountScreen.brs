sub init()
    m.focusIndex = 0
    m.background = m.top.findNode("background")
    m.titleLabel = m.top.findNode("titleLabel")
    m.contentGroup = m.top.findNode("contentGroup")
    m.serverLabel = m.top.findNode("serverLabel")
    m.userLabel = m.top.findNode("userLabel")
    m.statusLabel = m.top.findNode("statusLabel")
    m.buttons = [m.top.findNode("removeButton"), m.top.findNode("backButton")]

    m.top.observeField("width", "layoutAccount")
    m.top.observeField("height", "layoutAccount")
    layoutAccount()
    onAccountChanged()
    updateFocus()
end sub

sub setAccountFocus()
    m.top.setFocus(true)
    updateFocus()
end sub

sub layoutAccount()
    width = m.top.width
    height = m.top.height
    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.background.width = width
    m.background.height = height
    m.titleLabel.width = width
    m.titleLabel.translation = [0, 190]
    m.contentGroup.translation = [(width - 760) / 2, 330]
    m.serverLabel.translation = [0, 0]
    m.userLabel.translation = [0, 62]
    m.statusLabel.translation = [0, 124]
    m.buttons[0].translation = [100, 230]
    m.buttons[1].translation = [100, 326]
end sub

sub onAccountChanged()
    account = m.top.account
    if account = invalid then account = {}

    server = ""
    user = ""
    status = "Conectado"
    if account.dns <> invalid then server = account.dns
    if account.username <> invalid then user = account.username
    if account.status <> invalid then status = account.status

    m.serverLabel.text = "Servidor: " + server
    m.userLabel.text = "Usuário: " + user
    m.statusLabel.text = "Status da conexão: " + status
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up"
        if m.focusIndex > 0 then m.focusIndex = m.focusIndex - 1
        updateFocus()
        return true
    else if key = "down"
        if m.focusIndex < m.buttons.count() - 1 then m.focusIndex = m.focusIndex + 1
        updateFocus()
        return true
    else if key = "OK"
        if m.focusIndex = 0
            m.top.removeRequested = true
        else
            m.top.backRequested = true
        end if
        return true
    else if key = "back"
        m.top.backRequested = true
        return true
    end if

    return false
end function

sub updateFocus()
    for i = 0 to m.buttons.count() - 1
        m.buttons[i].selected = (i = m.focusIndex)
    end for
end sub
