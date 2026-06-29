sub init()
    m.focusIndex = 0
    m.seriesButton = m.top.findNode("seriesButton")
    m.accountButton = m.top.findNode("accountButton")
    m.accountLabel = m.top.findNode("accountLabel")
    m.messageLabel = m.top.findNode("messageLabel")
    updateFocus()
end sub

sub onAccountChanged()
    account = m.top.account
    m.account = account
    m.accountLabel.text = ""
    m.messageLabel.text = ""
end sub

sub setHomeFocus()
    m.top.setFocus(true)
    updateFocus()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "up" or key = "down"
        if m.focusIndex = 0 then m.focusIndex = 1 else m.focusIndex = 0
        updateFocus()
        return true
    else if key = "OK"
        if m.focusIndex = 0
            m.top.seriesSelected = true
        else
            if m.account <> invalid
                m.accountLabel.text = "Conta: " + PxtTrim(m.account.username) + " @ " + PxtTrim(m.account.dns)
            else
                m.accountLabel.text = "Conta nao encontrada."
            end if
            m.messageLabel.text = m.accountLabel.text
            m.top.accountSelected = true
        end if
        return true
    else if key = "back"
        m.top.backRequested = true
        return true
    end if

    return false
end function

sub updateFocus()
    if m.focusIndex = 0
        m.seriesButton.color = "0x2A73D9FF"
        m.accountButton.color = "0x102C55FF"
    else
        m.seriesButton.color = "0x102C55FF"
        m.accountButton.color = "0x2A73D9FF"
    end if
end sub
