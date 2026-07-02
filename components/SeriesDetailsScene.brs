sub init()
    m.title = m.top.FindNode("title")
    m.playBg = m.top.FindNode("playBg")
    m.playLabel = m.top.FindNode("playLabel")
    m.status = m.top.FindNode("status")
    m.seasonList = m.top.FindNode("seasonList")
    m.episodeList = m.top.FindNode("episodeList")

    m.focusSection = "play"
    m.focusSeasonIndex = 0
    m.focusEpisodeIndex = 0
    m.selectedSeason = invalid
    m.selectedEpisode = invalid
    m.seasons = []
    m.episodes = []
    m.player = invalid

    onSeriesChanged()
    updateFocus()
end sub

sub onSeriesChanged()
    series = m.top.series
    if series = invalid then series = {}

    if series.title <> invalid
        m.title.text = series.title
    else if series.name <> invalid
        m.title.text = series.name
    else
        m.title.text = "Série"
    end if

    m.seasons = getSeasons(series)
    m.focusSeasonIndex = clampIndex(m.focusSeasonIndex, m.seasons.Count())
    selectSeasonByIndex(m.focusSeasonIndex)
    renderSeasons()
    renderEpisodes()
    updateFocus()
end sub

function getSeasons(series as object) as object
    if series = invalid then return []
    if series.seasons <> invalid then return series.seasons
    if series.episodes <> invalid then return [{ title: "Temporada 1", seasonNumber: 1, episodes: series.episodes }]
    return []
end function

function clampIndex(index as integer, total as integer) as integer
    if total <= 0 then return 0
    if index < 0 then return 0
    if index >= total then return total - 1
    return index
end function

sub selectSeasonByIndex(index as integer)
    m.focusSeasonIndex = clampIndex(index, m.seasons.Count())
    if m.seasons.Count() > 0
        m.selectedSeason = m.seasons[m.focusSeasonIndex]
        print "selectedSeason: "; m.selectedSeason
        if m.selectedSeason.episodes <> invalid
            m.episodes = m.selectedSeason.episodes
        else
            m.episodes = []
        end if
    else
        m.selectedSeason = invalid
        m.episodes = []
    end if

    ' Keep the season and episode selections independent. Changing season
    ' only resets the focused episode to the first real episode in that season.
    m.focusEpisodeIndex = 0
    selectEpisodeByIndex(m.focusEpisodeIndex)
end sub

sub selectEpisodeByIndex(index as integer)
    m.focusEpisodeIndex = clampIndex(index, m.episodes.Count())
    if m.episodes.Count() > 0
        m.selectedEpisode = m.episodes[m.focusEpisodeIndex]
    else
        m.selectedEpisode = invalid
    end if
    print "selectedEpisode: "; m.selectedEpisode
end sub

function getItemTitle(item as object, fallback as string) as string
    if item = invalid then return fallback
    if item.title <> invalid and item.title <> "" then return item.title
    if item.name <> invalid and item.name <> "" then return item.name
    return fallback
end function

sub renderSeasons()
    m.seasonList.RemoveChildren(m.seasonList.GetChildren(-1, 0))
    for i = 0 to m.seasons.Count() - 1
        label = CreateObject("roSGNode", "Label")
        label.id = "season" + i.ToStr()
        label.text = getItemTitle(m.seasons[i], "Temporada " + (i + 1).ToStr())
        label.translation = [0, i * 54]
        label.width = 360
        label.height = 44
        label.color = "#FFFFFF"
        label.font = "font:MediumSystemFont"
        m.seasonList.AppendChild(label)
    end for
end sub

sub renderEpisodes()
    m.episodeList.RemoveChildren(m.episodeList.GetChildren(-1, 0))
    for i = 0 to m.episodes.Count() - 1
        label = CreateObject("roSGNode", "Label")
        label.id = "episode" + i.ToStr()
        label.text = getItemTitle(m.episodes[i], "Episódio " + (i + 1).ToStr())
        label.translation = [0, i * 54]
        label.width = 920
        label.height = 44
        label.color = "#FFFFFF"
        label.font = "font:MediumSystemFont"
        m.episodeList.AppendChild(label)
    end for
end sub

sub updateFocus()
    m.playBg.color = "#243B65"
    seasonNodes = m.seasonList.GetChildren(-1, 0)
    for i = 0 to seasonNodes.Count() - 1
        seasonNodes[i].color = "#FFFFFF"
    end for
    episodeNodes = m.episodeList.GetChildren(-1, 0)
    for i = 0 to episodeNodes.Count() - 1
        episodeNodes[i].color = "#FFFFFF"
    end for

    if m.focusSection = "play"
        m.playBg.color = "#2F75FF"
    else if m.focusSection = "season" and seasonNodes.Count() > 0
        seasonNodes[m.focusSeasonIndex].color = "#7CFC98"
    else if m.focusSection = "episode" and episodeNodes.Count() > 0
        episodeNodes[m.focusEpisodeIndex].color = "#2F75FF"
    end if
    m.top.SetFocus(true)
end sub

function getFieldAsString(item as object, fieldName as string) as string
    if item = invalid then return ""
    value = item[fieldName]
    if value = invalid then return ""
    return Trim(value.ToStr())
end function

function getEpisodeUrl(episode as object) as string
    if episode = invalid then return ""
    streamUrl = getFieldAsString(episode, "streamUrl")
    if streamUrl <> "" then return streamUrl
    url = getFieldAsString(episode, "url")
    if url <> "" then return url
    return ""
end function

function isSeasonItem(item as object) as boolean
    return item <> invalid and item.episodes <> invalid
end function

sub openSeriesPlayer()
    episode = m.selectedEpisode
    url = getEpisodeUrl(episode)
    print "selectedSeason: "; m.selectedSeason
    print "selectedEpisode: "; episode
    print "episode.url/streamUrl: "; url

    if episode = invalid or isSeasonItem(episode) or url = ""
        m.status.text = "Não foi possível abrir este episódio: link de vídeo indisponível."
        print "openSeriesPlayer chamado: bloqueado sem episódio/URL válida"
        return
    end if

    print "openSeriesPlayer chamado"
    player = CreateObject("roSGNode", "SeriesPlayerScreen")
    player.episode = episode
    player.streamUrl = url
    player.ObserveField("closePlayer", "onPlayerClosed")
    m.top.AppendChild(player)
    m.player = player
    player.SetFocus(true)
end sub

sub onPlayerClosed()
    if m.player <> invalid
        m.player.UnobserveField("closePlayer")
        m.top.RemoveChild(m.player)
        m.player = invalid
    end if
    m.top.SetFocus(true)
    updateFocus()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    normalizedKey = NormalizeRemoteKey(key)

    if normalizedKey = "back"
        m.top.closeDetails = true
        return true
    else if normalizedKey = "down"
        if m.focusSection = "play"
            m.focusSection = "season"
            selectSeasonByIndex(m.focusSeasonIndex)
        else if m.focusSection = "season"
            selectSeasonByIndex(m.focusSeasonIndex)
            renderEpisodes()
            if m.episodes.Count() > 0
                m.focusSection = "episode"
                selectEpisodeByIndex(0)
            else
                m.status.text = "Esta temporada não possui episódios disponíveis."
            end if
        else if m.focusSection = "episode"
            selectEpisodeByIndex(m.focusEpisodeIndex + 1)
        end if
        updateFocus()
        return true
    else if normalizedKey = "up"
        if m.focusSection = "episode" and m.focusEpisodeIndex > 0
            selectEpisodeByIndex(m.focusEpisodeIndex - 1)
        else if m.focusSection = "episode"
            m.focusSection = "season"
        else if m.focusSection = "season"
            m.focusSection = "play"
        end if
        updateFocus()
        return true
    else if normalizedKey = "left" or normalizedKey = "right"
        if m.focusSection = "season"
            delta = 1
            if normalizedKey = "left" then delta = -1
            selectSeasonByIndex(m.focusSeasonIndex + delta)
            renderEpisodes()
            updateFocus()
            return true
        end if
    else if normalizedKey = "ok"
        if m.focusSection = "play"
            openSeriesPlayer()
        else if m.focusSection = "season"
            selectSeasonByIndex(m.focusSeasonIndex)
            renderEpisodes()
            if m.episodes.Count() > 0
                m.status.text = "Temporada selecionada. Escolha um episódio."
            else
                m.status.text = "Esta temporada não possui episódios disponíveis."
            end if
            updateFocus()
        else if m.focusSection = "episode"
            selectEpisodeByIndex(m.focusEpisodeIndex)
            openSeriesPlayer()
        end if
        return true
    end if

    return false
end function
