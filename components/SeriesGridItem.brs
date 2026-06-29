sub init()
  m.focusRect = m.top.findNode("focusRect")
  m.poster = m.top.findNode("poster")
  m.placeholder = m.top.findNode("placeholder")
  m.titleLabel = m.top.findNode("titleLabel")
end sub

sub onContentChanged()
  content = m.top.itemContent
  if content = invalid then return

  m.titleLabel.text = content.title
  if content.url <> invalid and content.url.toStr() <> "" then
    m.poster.uri = content.url.toStr()
    m.poster.visible = true
    m.placeholder.visible = false
  else
    m.poster.uri = ""
    m.poster.visible = false
    m.placeholder.visible = true
  end if
end sub

sub onFocusChanged()
  if m.top.focusPercent > 0.5 then
    m.focusRect.opacity = 1
  else
    m.focusRect.opacity = 0
  end if
end sub
