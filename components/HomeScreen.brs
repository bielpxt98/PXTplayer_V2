sub init()
    m.buttons = [
        m.top.FindNode("button0Bg")
        m.top.FindNode("button1Bg")
        m.top.FindNode("button2Bg")
        m.top.FindNode("button3Bg")
        m.top.FindNode("button4Bg")
    ]
    m.status = m.top.FindNode("status")
    m.focusIndex = 0
    m.top.ObserveField("navigationEnabled", "updateFocus")
    m.top.SetFocus(true)
    updateFocus()
end sub

sub setStatus(message as string)
    if isReconnectMessage(message) and HasLoadedContentCache()
        m.status.text = ""
        ClearAccountErrors()
        return
    end if
    m.status.text = message
end sub

sub clearAccountStatus()
    m.status.text = ""
    ClearAccountErrors()
end sub

function isReconnectMessage(message as string) as boolean
    if message = invalid then return false
    text = LCase(message)
    return Instr(1, text, "reconectar") > 0 or Instr(1, text, "conta") > 0 or Instr(1, text, "reconnect") > 0
end function

sub updateFocus()
    for i = 0 to m.buttons.Count() - 1
        if m.top.navigationEnabled = true and i = m.focusIndex
            m.buttons[i].color = "#2F75FF"
        else
            m.buttons[i].color = "#243B65"
        end if
    end for
end sub

sub moveFocus(delta as integer)
    m.focusIndex = m.focusIndex + delta
    if m.focusIndex < 0 then m.focusIndex = m.buttons.Count() - 1
    if m.focusIndex >= m.buttons.Count() then m.focusIndex = 0
    updateFocus()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = NormalizeRemoteKey(key)

    if m.top.navigationEnabled <> true
        return true
    end if

    if normalizedKey = "down"
        moveFocus(1)
        return true
    else if normalizedKey = "up"
        moveFocus(-1)
        return true
    else if normalizedKey = "ok"
        if m.focusIndex = 1
            m.top.openMovies = true
        else if m.focusIndex = 4
            m.top.openLogin = true
        else
            m.status.color = "#FFB347"
            m.status.text = "Em breve"
        end if
        return true
    end if

    return false
end function
