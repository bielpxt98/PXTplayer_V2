sub init()
    m.top.functionName = "run"
end sub

sub run()
    credentials = m.top.credentials
    result = { success: false, message: "Usuário ou senha inválidos.", status: "invalid" }

    if credentials = invalid or credentials.dns = invalid or credentials.username = invalid or credentials.password = invalid
        m.top.result = result
        return
    end if

    dns = normalizeDns(credentials.dns)
    if dns = ""
        m.top.result = result
        return
    end if

    url = dns + "/player_api.php?username=" + credentials.username + "&password=" + credentials.password
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetMinimumTransferRate(1, 20)

    response = transfer.GetToString()
    code = transfer.GetResponseCode()

    if code = 0
        m.top.result = { success: false, message: "Não foi possível conectar ao servidor.", status: "network" }
        return
    else if code < 200 or code >= 300
        m.top.result = { success: false, message: "Usuário ou senha inválidos.", status: "invalid" }
        return
    end if

    if response = invalid or response = ""
        m.top.result = { success: false, message: "Tempo de conexão esgotado.", status: "timeout" }
        return
    end if

    data = ParseJson(response)
    if data <> invalid and data.user_info <> invalid and data.user_info.auth <> invalid and data.user_info.auth = 1
        m.top.result = { success: true, message: "Conectado com sucesso.", status: "ok", credentials: { dns: dns, username: credentials.username, password: credentials.password } }
    else
        m.top.result = result
    end if
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
