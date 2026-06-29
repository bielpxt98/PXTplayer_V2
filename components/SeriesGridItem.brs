sub init()
    m.poster = m.top.findNode("poster")
    m.placeholder = m.top.findNode("placeholder")
    m.title = m.top.findNode("title")
    m.focusBox = m.top.findNode("focusBox")
end sub

sub onItemContentChanged()
    item = m.top.itemContent
    if item = invalid then return
    m.title.text = getField(item, "name", "Serie")
    cover = getField(item, "cover", getField(item, "stream_icon", ""))
    m.poster.uri = cover
    m.placeholder.visible = cover = ""
end sub

sub onFocusChanged()
    m.focusBox.visible = m.top.focusPercent > 0.5
end sub

function getField(item as object, key as string, fallback as string) as string
    value = item[key]
    if value = invalid then return fallback
    text = value.ToStr()
    if text = "" or LCase(text) = "invalid" or LCase(text) = "null" then return fallback
    return text
end function
