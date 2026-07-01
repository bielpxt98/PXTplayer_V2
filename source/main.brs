sub Main()
    PRINT "PXT_MAIN_START"

    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    PRINT "PXT_SCENE_CREATED"

    screen.Show()
    PRINT "PXT_SCREEN_SHOWN"

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent"
            if msg.IsScreenClosed()
                PRINT "PXT_MAIN_EXIT"
                return
            end if
        end if
    end while
end sub
