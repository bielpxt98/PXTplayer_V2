sub init()
    m.background = m.top.findNode("background")
    m.titleLabel = m.top.findNode("titleLabel")
    m.helpLabel = m.top.findNode("helpLabel")
    m.categoryTitleLabel = m.top.findNode("categoryTitleLabel")
    m.channelsTitleLabel = m.top.findNode("channelsTitleLabel")
    m.counterLabel = m.top.findNode("counterLabel")
    m.categoryPanel = m.top.findNode("categoryPanel")
    m.channelPanel = m.top.findNode("channelPanel")
    m.categoryRows = m.top.findNode("categoryRows")
    m.channelRows = m.top.findNode("channelRows")
    m.messageLabel = m.top.findNode("messageLabel")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoPlayer.observeField("state", "onVideoStateChanged")

    m.categories = []
    m.channels = []
    m.categoryIndex = 0
    m.channelIndex = 0
    m.focusArea = "categories"
    m.requestId = 0
    m.loadingChannels = false
    m.playerOpen = false

    m.top.observeField("width", "layoutLiveTV")
    m.top.observeField("height", "layoutLiveTV")
    layoutLiveTV()
end sub

sub setLiveTVFocus()
    m.top.setFocus(true)
    if m.categories.count() = 0 and m.top.credentials <> invalid
        loadCategories()
    else
        renderAll()
    end if
end sub

sub onCredentialsChanged()
    m.categories = []
    m.channels = []
    m.categoryIndex = 0
    m.channelIndex = 0
    m.focusArea = "categories"
    if m.top.visible = true then loadCategories()
end sub

sub layoutLiveTV()
    width = m.top.width
    height = m.top.height
    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.background.width = width
    m.background.height = height
    m.titleLabel.translation = [70, 42]
    m.titleLabel.width = 420
    m.helpLabel.translation = [70, height - 56]
    m.helpLabel.width = width - 140
    m.categoryTitleLabel.translation = [70, 130]
    m.channelsTitleLabel.translation = [540, 130]
    m.channelsTitleLabel.width = 700
    m.counterLabel.translation = [width - 420, 136]
    m.counterLabel.width = 350
    m.categoryPanel.translation = [70, 180]
    m.categoryPanel.width = 420
    m.categoryPanel.height = height - 270
    m.channelPanel.translation = [540, 180]
    m.channelPanel.width = width - 610
    m.channelPanel.height = height - 270
    m.categoryRows.translation = [90, 198]
    m.channelRows.translation = [560, 198]
    m.messageLabel.translation = [540, 500]
    m.messageLabel.width = width - 610
    m.videoPlayer.width = width
    m.videoPlayer.height = height
end sub

sub loadCategories()
    m.channels = []
    m.messageLabel.text = "Carregando categorias..."
    renderAll()
    runLiveTask("get_live_categories", "")
end sub

sub loadChannelsForSelectedCategory()
    if m.categories.count() = 0 then return
    category = m.categories[m.categoryIndex]
    m.channels = []
    m.channelIndex = 0
    m.loadingChannels = true
    m.messageLabel.text = "Carregando canais..."
    renderAll()
    runLiveTask("get_live_streams", getString(category, "category_id"))
end sub

sub runLiveTask(action as string, categoryId as string)
    if m.liveTask <> invalid then m.liveTask.control = "STOP"
    m.requestId = m.requestId + 1
    task = CreateObject("roSGNode", "LiveApiTask")
    task.credentials = m.top.credentials
    task.action = action
    task.categoryId = categoryId
    task.requestId = m.requestId
    task.observeField("result", "onLiveTaskResult")
    m.liveTask = task
    task.control = "RUN"
end sub

sub onLiveTaskResult(event as object)
    result = event.getData()
    if result = invalid or result.requestId <> m.requestId then return

    if result.success <> true
        m.loadingChannels = false
        m.messageLabel.text = result.message + " Pressione OK para tentar novamente."
        renderAll()
        return
    end if

    if result.action = "get_live_categories"
        m.categories = normalizeCategories(result.items)
        m.categoryIndex = 0
        if m.categories.count() = 0
            m.messageLabel.text = "Nenhuma categoria encontrada. Pressione OK para tentar novamente."
        else
            m.messageLabel.text = ""
            loadChannelsForSelectedCategory()
        end if
    else if result.action = "get_live_streams"
        m.loadingChannels = false
        m.channels = normalizeChannels(result.items)
        if m.channels.count() = 0
            m.messageLabel.text = "Nenhum canal encontrado. Pressione OK para tentar novamente."
        else
            m.messageLabel.text = ""
        end if
    end if
    renderAll()
end sub

function normalizeCategories(items as dynamic) as object
    output = []
    if items = invalid then return output
    for each item in items
        output.push({ category_id: getString(item, "category_id"), category_name: getString(item, "category_name") })
    end for
    return output
end function

function normalizeChannels(items as dynamic) as object
    output = []
    if items = invalid then return output
    for each item in items
        output.push({ name: getString(item, "name"), stream_id: getString(item, "stream_id"), stream_icon: getString(item, "stream_icon"), category_name: getString(item, "category_name") })
    end for
    return output
end function

function getString(item as dynamic, key as string) as string
    if item <> invalid and item[key] <> invalid then return item[key].ToStr()
    return ""
end function

sub renderAll()
    renderCategories()
    renderChannels()
    if m.categories.count() > 0
        m.channelsTitleLabel.text = getString(m.categories[m.categoryIndex], "category_name")
    else
        m.channelsTitleLabel.text = "Canais"
    end if
    m.counterLabel.text = m.channels.count().ToStr() + " canais"
end sub

sub renderCategories()
    m.categoryRows.removeChildrenIndex(m.categoryRows.getChildCount(), 0)
    maxRows = 10
    startIndex = getStartIndex(m.categoryIndex, m.categories.count(), maxRows)
    for row = 0 to maxRows - 1
        index = startIndex + row
        if index >= m.categories.count() then exit for
        category = m.categories[index]
        label = CreateObject("roSGNode", "Label")
        label.translation = [0, row * 58]
        label.width = 380
        label.height = 48
        label.vertAlign = "center"
        label.font = "font:MediumSystemFont"
        label.text = getString(category, "category_name")
        label.color = getRowColor(index = m.categoryIndex, m.focusArea = "categories")
        m.categoryRows.appendChild(label)
    end for
end sub

sub renderChannels()
    m.channelRows.removeChildrenIndex(m.channelRows.getChildCount(), 0)
    maxRows = 8
    startIndex = getStartIndex(m.channelIndex, m.channels.count(), maxRows)
    for row = 0 to maxRows - 1
        index = startIndex + row
        if index >= m.channels.count() then exit for
        channel = m.channels[index]
        y = row * 78
        icon = CreateObject("roSGNode", "Poster")
        icon.translation = [0, y + 7]
        icon.width = 64
        icon.height = 64
        icon.uri = getString(channel, "stream_icon")
        m.channelRows.appendChild(icon)

        name = CreateObject("roSGNode", "Label")
        name.translation = [84, y]
        name.width = 920
        name.height = 38
        name.font = "font:MediumBoldSystemFont"
        name.color = getRowColor(index = m.channelIndex, m.focusArea = "channels")
        name.text = getString(channel, "name")
        m.channelRows.appendChild(name)

        group = CreateObject("roSGNode", "Label")
        group.translation = [84, y + 38]
        group.width = 920
        group.height = 30
        group.font = "font:SmallSystemFont"
        group.color = "0x8EA4C2FF"
        group.text = getString(channel, "category_name")
        m.channelRows.appendChild(group)
    end for
end sub

function getStartIndex(selected as integer, total as integer, maxRows as integer) as integer
    if total <= maxRows then return 0
    startIndex = selected - Int(maxRows / 2)
    if startIndex < 0 then startIndex = 0
    if startIndex > total - maxRows then startIndex = total - maxRows
    return startIndex
end function

function getRowColor(selected as boolean, focused as boolean) as string
    if selected and focused then return "0xFFFFFFFF"
    if selected then return "0xBFD7FFFF"
    return "0x8EA4C2FF"
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.playerOpen then return handlePlayerKey(key)

    if key = "back"
        m.top.backRequested = true
        return true
    else if key = "left"
        m.focusArea = "categories"
        renderAll()
        return true
    else if key = "right"
        if m.channels.count() > 0 then m.focusArea = "channels"
        renderAll()
        return true
    else if key = "up"
        moveSelection(-1)
        return true
    else if key = "down"
        moveSelection(1)
        return true
    else if key = "OK"
        if m.focusArea = "categories"
            if m.categories.count() = 0 then loadCategories() else loadChannelsForSelectedCategory()
        else if m.channels.count() > 0
            openPlayer()
        else if m.categories.count() > 0 and not m.loadingChannels
            loadChannelsForSelectedCategory()
        end if
        return true
    end if

    return false
end function

sub moveSelection(delta as integer)
    if m.focusArea = "categories"
        if m.categories.count() = 0 then return
        m.categoryIndex = clamp(m.categoryIndex + delta, 0, m.categories.count() - 1)
        loadChannelsForSelectedCategory()
    else
        if m.channels.count() = 0 then return
        m.channelIndex = clamp(m.channelIndex + delta, 0, m.channels.count() - 1)
        renderAll()
    end if
end sub

function clamp(value as integer, minValue as integer, maxValue as integer) as integer
    if value < minValue then return minValue
    if value > maxValue then return maxValue
    return value
end function

sub openPlayer()
    channel = m.channels[m.channelIndex]
    streamId = getString(channel, "stream_id")
    if streamId = ""
        m.messageLabel.text = "Não foi possível reproduzir este canal."
        return
    end if

    content = CreateObject("roSGNode", "ContentNode")
    content.url = m.top.credentials.dns + "/live/" + m.top.credentials.username + "/" + m.top.credentials.password + "/" + streamId + ".ts"
    content.streamFormat = "hls"
    content.title = getString(channel, "name")
    m.videoPlayer.content = content
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
    m.playerOpen = true
end sub

function handlePlayerKey(key as string) as boolean
    if key = "back" or key = "stop"
        closePlayer()
        return true
    else if key = "play" or key = "OK"
        if m.videoPlayer.state = "playing" then m.videoPlayer.control = "pause" else m.videoPlayer.control = "play"
        return true
    end if
    return false
end function

sub onVideoStateChanged()
    if m.playerOpen and m.videoPlayer.state = "error"
        closePlayer()
        m.messageLabel.text = "Não foi possível reproduzir este canal."
    end if
end sub

sub closePlayer()
    m.videoPlayer.control = "stop"
    m.videoPlayer.visible = false
    m.playerOpen = false
    m.top.setFocus(true)
    renderAll()
end sub
