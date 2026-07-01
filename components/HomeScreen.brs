sub init()
    m.buttonBg = m.top.FindNode("playlistButtonBg")
    m.status = m.top.FindNode("status")
    m.top.SetFocus(true)
end sub

sub setStatus(message as string)
    m.status.text = message
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    normalizedKey = LCase(key)
    if normalizedKey = "enter" then normalizedKey = "ok"

    if normalizedKey = "ok"
        m.top.openLogin = true
        return true
    end if

    return false
end function
