sub init()
    PRINT "XTREAM_TASK_INIT"
    m.top.functionName = "executeXtreamRequest"
end sub

sub executeXtreamRequest()
    PRINT "XTREAM_TASK_EXECUTE"
    PRINT "STEP 1 - START"
    result = { success: false, error: "network", message: "Não foi possível conectar ao servidor." }

    if m.top.action <> "connect"
        publishResult({ success: false, error: "network", message: "Não foi possível conectar ao servidor." })
        return
    end if

    dns = normalizeDns(m.top.dns)
    PRINT "STEP 2 - DNS=" + dns
    username = m.top.username
    password = m.top.password

    if dns = "" or username = invalid or username = "" or password = invalid or password = ""
        publishResult({ success: false, error: "invalid_credentials", message: "Usuário ou senha inválidos." })
        return
    end if

    PRINT "XTREAM_CONNECT_START"

    PRINT "STEP 3 - CREATE TRANSFER"
    transfer = CreateObject("roUrlTransfer")
    url = dns + "/player_api.php?username=" + transfer.Escape(username) + "&password=" + transfer.Escape(password)
    PRINT "STEP 4 - URL=" + url
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetMinimumTransferRate(1, 10)

    PRINT "STEP 5 - REQUEST"
    if transfer.AsyncGetToString() <> true
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult(result)
        return
    end if
    PRINT "STEP 6 - REQUEST SENT"

    event = wait(10000, port)
    PRINT "STEP 7 - EVENT RECEIVED"
    if event = invalid
        transfer.AsyncCancel()
        PRINT "STEP 7A - TIMEOUT"
        PRINT "XTREAM_CONNECT_TIMEOUT"
        publishResult({ success: false, error: "timeout", message: "Tempo de conexão esgotado." })
        return
    end if

    PRINT "EVENT TYPE=" + type(event)

    if type(event) <> "roUrlEvent"
        transfer.AsyncCancel()
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult(result)
        return
    end if

    code = event.GetResponseCode()
    if code = invalid then code = 0
    PRINT "HTTP CODE=" + Str(code)
    PRINT "XTREAM_CONNECT_HTTP_DONE code="; code

    if code = 0
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult(result)
        return
    else if code < 200 or code >= 300
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult({ success: false, error: "server_unavailable", message: "Servidor indisponível. Tente novamente mais tarde." })
        return
    end if

    response = event.GetString()
    PRINT event.GetString()
    PRINT "STEP 8 - JSON"
    data = invalid
    if response <> invalid and response <> ""
        data = ParseJson(response)
    end if

    if data = invalid
        PRINT "STEP 8A - INVALID JSON"
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult({ success: false, error: "invalid_json", message: "O servidor retornou uma resposta inválida." })
        return
    end if

    if isAuthenticated(data)
        PRINT "STEP 9 - LOGIN SUCCESS"
        PRINT "XTREAM_CONNECT_SUCCESS"
        publishResult({ success: true, error: "", message: "Conectado com sucesso.", credentials: { dns: dns, username: username, password: password } })
    else
        PRINT "STEP 9A - LOGIN FAILED"
        PRINT "XTREAM_CONNECT_ERROR"
        publishResult({ success: false, error: "invalid_credentials", message: "Usuário ou senha inválidos." })
    end if
end sub

sub publishResult(result as object)
    m.top.result = result
end sub

function isAuthenticated(data as object) as boolean
    if data = invalid or data.user_info = invalid then return false

    userInfo = data.user_info
    if userInfo.auth <> invalid
        if userInfo.auth = 1 then return true
        if userInfo.auth = "1" then return true
    end if

    if userInfo.status <> invalid and userInfo.status = "Active" then return true

    return false
end function

function normalizeDns(value as dynamic) as string
    if value = invalid then return ""

    dns = Trim(value)
    if dns = "" then return ""

    lowerDns = LCase(dns)
    if Left(lowerDns, 7) <> "http://" and Left(lowerDns, 8) <> "https://"
        dns = "http://" + dns
    end if

    while Len(dns) > 0 and Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while

    return dns
end function
