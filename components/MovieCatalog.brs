sub init()
    m.grid = m.top.FindNode("grid")
    m.status = m.top.FindNode("status")
    m.searchText = m.top.FindNode("searchText")
    m.service = m.top.FindNode("service")
    m.debounce = m.top.FindNode("searchDebounce")
    m.service.ObserveField("result", "onMoviesLoaded")
    m.debounce.ObserveField("fire", "applySearch")
    m.allMovies = []
    m.filteredMovies = []
    m.renderedCount = 0
    m.focusIndex = 0
    m.searchQuery = ""
    m.batchSize = 36
    m.columns = 6
    m.cardW = 190
    m.cardH = 300
end sub

sub open()
    m.top.visible = true
    m.top.SetFocus(true)
    if m.allMovies.Count() = 0 then loadMovies() else resetList()
end sub

sub loadMovies()
    credentials = LoadXtreamCredentials()
    if credentials = invalid
        m.status.text = "Faça login para carregar filmes."
        return
    end if
    m.status.text = "Carregando filmes..."
    m.service.dns = credentials.dns
    m.service.username = credentials.username
    m.service.password = credentials.password
    m.service.control = "RUN"
end sub

sub onMoviesLoaded()
    result = m.service.result
    if result = invalid then return
    if result.success <> true
        m.status.text = result.errorMessage
        return
    end if
    m.allMovies = result.movies
    resetList()
end sub

sub clearGrid()
    while m.grid.GetChildCount() > 0
        m.grid.RemoveChild(m.grid.GetChild(0))
    end while
end sub

sub resetList()
    m.filteredMovies = filterMovies(m.searchQuery)
    clearGrid()
    m.renderedCount = 0
    m.focusIndex = 0
    appendMovieBatch()
    updateFocus()
    updateStatus()
end sub

function filterMovies(query as string) as object
    if query = "" then return m.allMovies
    result = []
    q = LCase(query)
    for each movie in m.allMovies
        name = getMovieName(movie)
        if Instr(1, LCase(name), q) > 0 then result.Push(movie)
    end for
    return result
end function

sub appendMovieBatch()
    total = m.filteredMovies.Count()
    if m.renderedCount >= total then return
    endIndex = m.renderedCount + m.batchSize - 1
    if endIndex >= total then endIndex = total - 1
    for i = m.renderedCount to endIndex
        m.grid.AppendChild(createCard(m.filteredMovies[i], i))
    end for
    m.renderedCount = endIndex + 1
end sub

function createCard(movie as object, index as integer) as object
    card = CreateObject("roSGNode", "Group")
    col = index mod m.columns
    row = Int(index / m.columns)
    card.translation = [col * m.cardW, row * m.cardH]

    bg = CreateObject("roSGNode", "Rectangle")
    bg.id = "bg"
    bg.width = 160
    bg.height = 238
    bg.color = "#1F2E4A"
    card.AppendChild(bg)

    poster = getPoster(movie)
    if poster <> ""
        img = CreateObject("roSGNode", "Poster")
        img.uri = poster
        img.width = 160
        img.height = 238
        img.loadDisplayMode = "scaleToFill"
        card.AppendChild(img)
    else
        ph = CreateObject("roSGNode", "Label")
        ph.text = "Sem poster"
        ph.translation = [24, 102]
        ph.width = 120
        ph.color = "#B9C7E6"
        ph.font = "font:SmallSystemFont"
        card.AppendChild(ph)
    end if

    title = CreateObject("roSGNode", "Label")
    title.text = Left(getMovieName(movie), 24)
    title.translation = [0, 246]
    title.width = 170
    title.height = 48
    title.color = "#FFFFFF"
    title.wrap = true
    title.font = "font:SmallSystemFont"
    card.AppendChild(title)
    return card
end function

sub updateFocus()
    for i = 0 to m.grid.GetChildCount() - 1
        card = m.grid.GetChild(i)
        bg = card.FindNode("bg")
        if bg <> invalid
            if i = m.focusIndex then bg.color = "#2F75FF" else bg.color = "#1F2E4A"
        end if
    end for
    row = Int(m.focusIndex / m.columns)
    m.grid.translation = [80, 195 - (row * m.cardH)]
end sub

sub updateStatus()
    m.status.text = m.filteredMovies.Count().ToStr() + " filmes • exibindo " + m.renderedCount.ToStr()
end sub

sub moveFocus(delta as integer)
    if m.renderedCount = 0 then return
    m.focusIndex = m.focusIndex + delta
    if m.focusIndex < 0 then m.focusIndex = 0
    if m.focusIndex >= m.renderedCount then m.focusIndex = m.renderedCount - 1
    if m.renderedCount - m.focusIndex <= 12
        appendMovieBatch()
        updateStatus()
    end if
    updateFocus()
end sub

sub scheduleSearch()
    m.debounce.control = "stop"
    m.debounce.control = "start"
    m.searchText.text = "Busca: " + m.searchQuery
end sub

sub applySearch()
    resetList()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    normalizedKey = NormalizeRemoteKey(key)
    if normalizedKey = "back"
        if m.searchQuery <> ""
            m.searchQuery = ""
            scheduleSearch()
        else
            m.top.closeCatalog = true
        end if
        return true
    else if normalizedKey = "down"
        moveFocus(m.columns)
        return true
    else if normalizedKey = "up"
        moveFocus(-m.columns)
        return true
    else if normalizedKey = "right"
        moveFocus(1)
        return true
    else if normalizedKey = "left"
        moveFocus(-1)
        return true
    end if

    if Len(key) = 1
        m.searchQuery = m.searchQuery + key
        scheduleSearch()
        return true
    end if
    return false
end function

function getMovieName(movie as object) as string
    if movie <> invalid and movie.name <> invalid then return movie.name.ToStr()
    return "Filme"
end function

function getPoster(movie as object) as string
    if movie = invalid then return ""
    if movie.stream_icon <> invalid then return movie.stream_icon.ToStr()
    if movie.cover <> invalid then return movie.cover.ToStr()
    return ""
end function
