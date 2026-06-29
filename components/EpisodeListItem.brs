sub init()
    m.bg = m.top.findNode("bg")
    m.label = m.top.findNode("label")
end sub
sub onItemContentChanged()
    item = m.top.itemContent
    if item <> invalid then m.label.text = item.title
end sub
sub onFocusChanged()
    if m.top.focusPercent > 0.5 then m.bg.color = "0x2A73D9FF" else m.bg.color = "0x00000000"
end sub
