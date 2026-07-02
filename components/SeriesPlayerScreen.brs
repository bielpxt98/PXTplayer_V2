sub init()
    m.video = m.top.FindNode("video")
    m.message = m.top.FindNode("message")
    m.top.ObserveField("streamUrl", "playEpisode")
    m.top.ObserveField("episode", "syncTitle")
    syncTitle()
    playEpisode()
end sub

sub syncTitle()
    episode = m.top.episode
    if episode <> invalid
        if episode.title <> invalid
            m.message.text = episode.title
        else if episode.name <> invalid
            m.message.text = episode.name
        end if
    end if
end sub

sub playEpisode()
    url = Trim(m.top.streamUrl)
    if url = "" then return

    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.streamFormat = "hls"
    m.video.content = content
    m.video.control = "play"
    m.video.SetFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    normalizedKey = NormalizeRemoteKey(key)
    if normalizedKey = "back"
        m.video.control = "stop"
        m.top.closePlayer = true
        return true
    end if
    return false
end function
