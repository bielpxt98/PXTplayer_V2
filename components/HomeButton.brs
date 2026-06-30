sub init()
    m.buttonGroup = m.top.findNode("buttonGroup")
    m.background = m.top.findNode("background")
    m.buttonLabel = m.top.findNode("buttonLabel")
    m.focusAnimation = m.top.findNode("focusAnimation")
    m.scaleInterpolator = m.top.findNode("scaleInterpolator")

    m.buttonGroup.scaleRotateCenter = [280, 36]
    m.normalScale = [1.0, 1.0]
    m.focusScale = [1.05, 1.05]

    onLabelTextChanged()
    onSelectedChanged()
end sub

sub onLabelTextChanged()
    m.buttonLabel.text = m.top.labelText
end sub

sub onSelectedChanged()
    if m.top.selected = true
        m.background.color = "0x2A73D9FF"
        m.buttonLabel.color = "0xFFFFFFFF"
        animateScale(m.focusScale)
    else
        m.background.color = "0x102033FF"
        m.buttonLabel.color = "0xD8E6FFFF"
        animateScale(m.normalScale)
    end if
end sub

sub animateScale(targetScale as object)
    currentScale = m.buttonGroup.scale
    if currentScale = invalid then currentScale = m.normalScale

    m.focusAnimation.control = "stop"
    m.scaleInterpolator.key = [0.0, 1.0]
    m.scaleInterpolator.keyValue = [currentScale, targetScale]
    m.focusAnimation.control = "start"
end sub
