sub init()
    m.top.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press and key = "back"
        m.top.backRequested = true
        return true
    end if
    return false
end function
