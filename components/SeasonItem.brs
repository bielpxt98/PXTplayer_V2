sub init()
    m.box = m.top.findNode("box")
    m.label = m.top.findNode("label")
end sub
sub onItemContentChanged()
    item = m.top.itemContent
    if item <> invalid then m.label.text = item.title
end sub
sub onFocusChanged()
    if m.top.focusPercent > 0.5 then m.box.color = "0x2A73D9FF" else m.box.color = "0x1E4D8BFF"
end sub
