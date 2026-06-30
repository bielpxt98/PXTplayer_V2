sub init()
    m.background = m.top.findNode("background")
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.stepsGroup = m.top.findNode("stepsGroup")
    m.stepTimer = m.top.findNode("stepTimer")
    m.stepTimer.observeField("fire", "onStepTimerFire")

    m.stepLabels = [
        m.top.findNode("connectLabel"),
        m.top.findNode("liveLabel"),
        m.top.findNode("moviesLabel"),
        m.top.findNode("seriesLabel"),
        m.top.findNode("finishLabel")
    ]
    m.statusLabels = [
        m.top.findNode("connectStatus"),
        m.top.findNode("liveStatus"),
        m.top.findNode("moviesStatus"),
        m.top.findNode("seriesStatus"),
        m.top.findNode("finishStatus")
    ]
    m.currentStep = 0

    m.top.observeField("width", "layoutLoading")
    m.top.observeField("height", "layoutLoading")
    layoutLoading()
    resetLoadingSteps()
end sub

sub startLoading()
    resetLoadingSteps()
    m.top.setFocus(true)
    m.stepTimer.control = "stop"
    m.stepTimer.control = "start"
    PRINT "LOADING_SCREEN_OPENED"
end sub

sub layoutLoading()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.background.width = width
    m.background.height = height
    m.titleLabel.width = width
    m.titleLabel.translation = [0, 240]
    m.subtitleLabel.width = width
    m.subtitleLabel.translation = [0, 330]

    groupWidth = 760
    m.stepsGroup.translation = [(width - groupWidth) / 2, 440]

    rowSpacing = 64
    for i = 0 to m.stepLabels.count() - 1
        y = i * rowSpacing
        m.stepLabels[i].width = 560
        m.stepLabels[i].height = 44
        m.stepLabels[i].translation = [0, y]
        m.statusLabels[i].width = 160
        m.statusLabels[i].height = 44
        m.statusLabels[i].translation = [600, y]
    end for
end sub

sub resetLoadingSteps()
    m.currentStep = 0
    for i = 0 to m.stepLabels.count() - 1
        m.statusLabels[i].text = ""
        if i = 0
            m.stepLabels[i].color = "0xFFFFFFFF"
        else
            m.stepLabels[i].color = "0xA8B7CCFF"
        end if
    end for
end sub

sub onStepTimerFire()
    if m.currentStep < m.statusLabels.count()
        m.statusLabels[m.currentStep].text = "OK"
        m.stepLabels[m.currentStep].color = "0xFFFFFFFF"
        m.currentStep = m.currentStep + 1
    end if

    if m.currentStep < m.stepLabels.count()
        m.stepLabels[m.currentStep].color = "0xFFFFFFFF"
        m.stepTimer.control = "start"
    else
        m.top.loadingFinished = true
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    return true
end function
