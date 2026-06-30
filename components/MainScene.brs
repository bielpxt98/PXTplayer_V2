sub init()
    m.homeScreen = m.top.findNode("homeScreen")

    m.homeScreen.observeField("openLive", "onOpenLive")
    m.homeScreen.observeField("openMovies", "onOpenMovies")
    m.homeScreen.observeField("openSeries", "onOpenSeries")
    m.homeScreen.observeField("openPlaylist", "onOpenPlaylist")

    m.top.observeField("width", "layoutScene")
    m.top.observeField("height", "layoutScene")
    layoutScene()

    m.homeScreen.visible = true
    m.homeScreen.callFunc("setHomeFocus")
    PRINT "HOME_SCREEN_OPENED"
end sub

sub layoutScene()
    width = m.top.width
    height = m.top.height

    if width = invalid or width <= 0 then width = 1920
    if height = invalid or height <= 0 then height = 1080

    m.homeScreen.width = width
    m.homeScreen.height = height
end sub

sub onOpenLive()
    PRINT "HOME_OPEN_LIVE"
end sub

sub onOpenMovies()
    PRINT "HOME_OPEN_MOVIES"
end sub

sub onOpenSeries()
    PRINT "HOME_OPEN_SERIES"
end sub

sub onOpenPlaylist()
    PRINT "HOME_OPEN_PLAYLIST"
end sub
