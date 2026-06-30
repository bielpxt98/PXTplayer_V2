sub init()
    m.top.functionName = "run"
end sub

sub run()
    credentials = m.top.credentials

    if credentials = invalid or credentials.dns = invalid or credentials.username = invalid or credentials.password = invalid
        finishAuth(false, "Usuário ou senha inválidos.", "invalid")
        return
    end if

    dns = normalizeDns(credentials.dns)
    if dns = ""
        finishAuth(false, "Usuário ou senha inválidos.", "invalid")
        return
    end if

    url = dns + "/player_api.php?username=" + credentials.username + "&password=" + credentials.password
    transfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetMinimumTransferRate(1, 10)

    if transfer.AsyncGetToString() <> true
        finishAuth(false, "Erro de rede. Verifique sua conexão.", "network")
        return
    end if

    event = wait(10000, port)
    if event = invalid
        transfer.AsyncCancel()
        finishAuth(false, "Tempo de conexão esgotado.", "timeout")
        return
    end if

    if type(event) <> "roUrlEvent"
        transfer.AsyncCancel()
        finishAuth(false, "Erro de rede. Verifique sua conexão.", "network")
        return
    end if

    code = event.GetResponseCode()
    if code = invalid then code = 0

    if code = 0
        finishAuth(false, "Erro de rede. Verifique sua conexão.", "network")
        return
    else if code = 401 or code = 403
        finishAuth(false, "Usuário ou senha inválidos.", "invalid")
        return
    else if code < 200 or code >= 300
        finishAuth(false, "Servidor indisponível. Tente novamente mais tarde.", "server")
        return
    end if

    response = event.GetString()
    if response = invalid or response = ""
        finishAuth(false, "Servidor indisponível. Tente novamente mais tarde.", "server")
        return
    end if

    data = ParseJson(response)
    if data <> invalid and data.user_info <> invalid and data.user_info.auth <> invalid and data.user_info.auth = 1
        m.top.result = { success: true, message: "Conectado com sucesso.", status: "ok", credentials: { dns: dns, username: credentials.username, password: credentials.password } }
    else
        finishAuth(false, "Usuário ou senha inválidos.", "invalid")
    end if
end sub

sub finishAuth(success as boolean, message as string, status as string)
    m.top.result = { success: success, message: message, status: status }
end sub

function normalizeDns(value as string) as string
    dns = Trim(value)
    if dns = "" then return ""

    lowerDns = LCase(dns)
    if Left(lowerDns, 7) <> "http://" and Left(lowerDns, 8) <> "https://"
        dns = "http://" + dns
    end if

    while Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while

    return dns
end function
