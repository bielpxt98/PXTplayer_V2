sub init()
    m.top.functionName = "connect"
end sub

sub onRequestChanged()
    if m.top.request <> invalid then m.top.control = "RUN"
end sub

sub connect()
    request = m.top.request
    dns = NormalizeDns(request.dns)
    if dns = ""
        m.top.result = { success: false, code: "invalid_response", message: "O servidor retornou uma resposta inválida." }
        return
    end if

    url = dns + "/player_api.php?username=" + UrlEncodeParam(request.username) + "&password=" + UrlEncodeParam(request.password)
    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(url)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetRequest("GET")
    transfer.SetMinimumTransferRate(1, 15)
    transfer.RetainBodyOnError(false)

    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    if not transfer.AsyncGetToString()
        m.top.result = { success: false, code: "network", message: "Não foi possível conectar ao servidor." }
        return
    end if

    msg = wait(15000, port)
    if msg = invalid
        transfer.AsyncCancel()
        m.top.result = { success: false, code: "timeout", message: "Tempo de conexão esgotado. Verifique o servidor." }
        return
    end if

    statusCode = msg.GetResponseCode()
    if statusCode < 200 or statusCode >= 300
        m.top.result = { success: false, code: "network", message: "Não foi possível conectar ao servidor." }
        return
    end if

    body = msg.GetString()
    if body = invalid or body.Trim() = ""
        m.top.result = { success: false, code: "invalid_response", message: "O servidor retornou uma resposta inválida." }
        return
    end if

    json = ParseJson(body)
    if json = invalid or json.user_info = invalid
        m.top.result = { success: false, code: "invalid_response", message: "O servidor retornou uma resposta inválida." }
        return
    end if

    if isValidXtreamAuth(json.user_info)
        m.top.result = { success: true, code: "success", dns: dns, username: PxtTrim(request.username), password: PxtTrim(request.password) }
    else
        m.top.result = { success: false, code: "invalid_credentials", message: "Usuário ou senha inválidos." }
    end if
end sub

function isValidXtreamAuth(userInfo as object) as boolean
    if userInfo.auth <> invalid
        authText = LCase(userInfo.auth.ToStr())
        if authText = "1" or authText = "true" then return true
    end if
    if userInfo.status <> invalid
        if LCase(userInfo.status.ToStr()) = "active" then return true
    end if
    return false
end function
