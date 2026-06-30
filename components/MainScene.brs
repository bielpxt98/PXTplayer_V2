sub init()
    m.blackRect = m.top.findNode("blackRect")
    m.titleLabel = m.top.findNode("titleLabel")

    m.top.observeField("width", "layoutScene")
    m.top.observeField("height", "layoutScene")
    layoutScene()

    m.top.setFocus(true)
end sub

sub layoutScene()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.blackRect.width = width
    m.blackRect.height = height

    m.titleLabel.width = width
    m.titleLabel.height = height
    m.titleLabel.translation = [0, 0]
    m.titleLabel.font = "font:MediumBoldSystemFont"
end sub
