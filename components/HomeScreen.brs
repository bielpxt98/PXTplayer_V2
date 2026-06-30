sub init()
    m.background = m.top.findNode("background")
    m.logoLabel = m.top.findNode("logoLabel")
    m.buttons = [m.top.findNode("liveTVButton"), m.top.findNode("accountButton")]
    m.focusIndex = 0

    m.top.observeField("width", "layoutHome")
    m.top.observeField("height", "layoutHome")
    layoutHome()
    updateFocus()
end sub

sub setHomeFocus()
    m.top.setFocus(true)
    updateFocus()
end sub

sub layoutHome()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.background.width = width
    m.background.height = height

    m.logoLabel.width = width
    m.logoLabel.translation = [0, 310]

    buttonX = (width - 560) / 2
    firstButtonY = 480

    for i = 0 to m.buttons.count() - 1
        m.buttons[i].translation = [buttonX, firstButtonY + (i * 92)]
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up"
        m.focusIndex = m.focusIndex - 1
        if m.focusIndex < 0 then m.focusIndex = m.buttons.count() - 1
        updateFocus()
        return true
    else if key = "down"
        m.focusIndex = m.focusIndex + 1
        if m.focusIndex >= m.buttons.count() then m.focusIndex = 0
        updateFocus()
        return true
    else if key = "OK"
        if m.focusIndex = 0 then m.top.openLiveTV = true else m.top.openAccount = true
        return true
    end if

    return false
end function

sub updateFocus()
    for i = 0 to m.buttons.count() - 1
        m.buttons[i].selected = (i = m.focusIndex)
    end for
end sub
