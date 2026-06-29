sub init()
    m.cover = m.top.findNode("cover") : m.placeholder = m.top.findNode("coverPlaceholder")
    m.nameLabel = m.top.findNode("nameLabel") : m.metaLabel = m.top.findNode("metaLabel") : m.plotLabel = m.top.findNode("plotLabel")
    m.spinner = m.top.findNode("spinner") : m.messageLabel = m.top.findNode("messageLabel")
    m.seasonGrid = m.top.findNode("seasonGrid") : m.episodeList = m.top.findNode("episodeList") : m.episodesTitle = m.top.findNode("episodesTitle")
    m.focusArea = "seasons" : m.seasons = [] : m.episodesBySeason = {}
end sub
sub onSelectedSeriesChanged()
    s = m.top.selectedSeries : showBasics(s, invalid) : setContent([], {})
end sub
sub onDetailsChanged()
    d = m.top.details : showBasics(m.top.selectedSeries, d) : buildLists(d)
end sub
sub onLoadingChanged()
    loading = m.top.loading
    m.spinner.visible = loading
    if loading then m.spinner.control = "start" else m.spinner.control = "stop"
end sub
sub onMessageChanged()
    m.messageLabel.text = m.top.message
end sub
sub showBasics(s as dynamic, d as dynamic)
    info = invalid : if d <> invalid and d.info <> invalid then info = d.info
    m.nameLabel.text = pick(info, s, ["name"], "Serie")
    cover = pick(info, s, ["cover", "movie_image", "stream_icon"], "")
    m.cover.uri = cover : m.placeholder.visible = cover = ""
    rating = pick(info, invalid, ["rating", "rating_5based"], "Sem avaliacao")
    year = extractYear(pick(info, invalid, ["releaseDate", "release_date", "year"], "")) : if year = "" then year = "Ano nao informado"
    genre = pick(info, invalid, ["genre"], "Genero nao informado")
    m.metaLabel.text = rating + " • " + year + " • " + genre
    m.plotLabel.text = pick(info, invalid, ["plot", "description", "overview"], "Descricao nao disponivel.")
end sub
sub buildLists(d as dynamic)
    seasons = [] : epsBy = {}
    if d <> invalid and d.episodes <> invalid then epsBy = normalizeEpisodes(d.episodes)
    if d <> invalid and d.seasons <> invalid
        for each ss in d.seasons
            num = toInt(ss.season_number, toInt(ss.season, -1))
            if num >= 0 then seasons.push({ number: num, title: seasonTitle(num) })
        end for
    end if
    for each k in epsBy
        exists = false : n = toInt(k, -1)
        for each ss in seasons : if ss.number = n then exists = true
        end for
        if n >= 0 and not exists then seasons.push({ number: n, title: seasonTitle(n) })
    end for
    seasons.sortBy("number")
    setContent(seasons, epsBy)
end sub
sub setContent(seasons as object, epsBy as object)
    m.seasons = seasons : m.episodesBySeason = epsBy
    root = CreateObject("roSGNode", "ContentNode")
    for each ss in seasons
        n = root.createChild("ContentNode") : n.title = ss.title : n.season = ss.number.ToStr()
    end for
    m.seasonGrid.content = root
    idx = 0
    for i = 0 to seasons.count() - 1
        if seasons[i].number = 1 and epsBy["1"] <> invalid then idx = i
    end for
    if seasons.count() > 0 then m.seasonGrid.jumpToItem = idx : updateEpisodes(idx) else updateEpisodes(-1)
end sub
sub updateEpisodes(idx as integer)
    if idx < 0 or idx >= m.seasons.count()
        m.episodesTitle.text = "EPISODIOS" : fillEpisodes([], "Nenhuma temporada encontrada.") : return
    end if
    seasonNum = m.seasons[idx].number.ToStr() : m.episodesTitle.text = "EPISODIOS — " + m.seasons[idx].title
    eps = m.episodesBySeason[seasonNum] : if eps = invalid then eps = []
    fillEpisodes(eps, "Nenhum episodio encontrado nesta temporada.")
end sub
sub fillEpisodes(eps as object, emptyMessage as string)
    root = CreateObject("roSGNode", "ContentNode")
    if eps.count() = 0 then n = root.createChild("ContentNode") : n.title = emptyMessage
    for each ep in eps
        n = root.createChild("ContentNode") : n.title = ep.display : n.id = safe(ep.id, "") : n.stream_id = safe(ep.stream_id, "") : n.episode_num = safe(ep.episode_num, "") : n.season = safe(ep.season, "") : n.container_extension = safe(ep.container_extension, "")
    end for
    m.episodeList.content = root
end sub
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        if m.focusArea = "episodes" then m.focusArea = "seasons" : m.seasonGrid.setFocus(true) else m.top.backRequested = true
        return true
    else if key = "down" and m.focusArea = "seasons"
        m.focusArea = "episodes" : m.episodeList.setFocus(true) : return true
    else if key = "up" and m.focusArea = "episodes" and m.episodeList.itemFocused <= 0
        m.focusArea = "seasons" : m.seasonGrid.setFocus(true) : return true
    else if key = "OK"
        if m.top.loading then return true
        if m.top.details = invalid then m.top.retryRequested = m.top.selectedSeries
        return true
    end if
    if m.focusArea = "seasons" then updateEpisodes(m.seasonGrid.itemFocused)
    return false
end function
sub setDetailFocus()
    m.focusArea = "seasons" : m.seasonGrid.setFocus(true)
end sub
function normalizeEpisodes(src as dynamic) as object
    out = {}
    if Type(src) = "roAssociativeArray"
        for each k in src : out[k.ToStr()] = episodeArray(src[k], k.ToStr()) : end for
    else if Type(src) = "roArray"
        for each ep in src
            sn = safe(ep.season, "1") : if out[sn] = invalid then out[sn] = []
            out[sn].push(makeEp(ep))
        end for
    end if
    for each k in out : out[k].sortBy("num") : end for
    return out
end function
function episodeArray(arr as dynamic, season as string) as object
    out = [] : if Type(arr) <> "roArray" then return out
    for each ep in arr
        e = makeEp(ep)
        if e.season = "" then e.season = season
        out.push(e)
    end for
    return out
end function
function makeEp(ep as dynamic) as object
    num = toInt(ep.episode_num, 0) : title = safe(ep.title, "Episodio " + num.ToStr())
    return { id: safe(ep.id, ""), stream_id: safe(ep.stream_id, ""), episode_num: num.ToStr(), num: num, title: title, season: safe(ep.season, ""), container_extension: safe(ep.container_extension, ""), display: "E" + pad2(num) + " — " + title }
end function
function seasonTitle(n as integer) as string
    if n = 0 then return "ESPECIAIS"
    return "T" + n.ToStr()
end function
function pad2(n as integer) as string
    if n < 10 then return "0" + n.ToStr()
    return n.ToStr()
end function
function toInt(v as dynamic, fallback as integer) as integer
    if v = invalid then return fallback
    return Val(v.ToStr())
end function
function extractYear(v as string) as string
    if Len(v) >= 4 then return Left(v, 4)
    return ""
end function
function pick(info as dynamic, fallbackObj as dynamic, keys as object, fallback as string) as string
    for each k in keys
        if info <> invalid then t = safe(info[k], "") : if t <> "" then return t
        if fallbackObj <> invalid then t = safe(fallbackObj[k], "") : if t <> "" then return t
    end for
    return fallback
end function
function safe(v as dynamic, fallback as string) as string
    if v = invalid then return fallback
    t = v.ToStr() : l = LCase(t)
    if t = "" or l = "invalid" or l = "null" or l = "undefined" then return fallback
    return t
end function
