sub init()
    m.top.functionName = "runRequest"
end sub

sub onRequestChanged()
    if m.top.request <> invalid then m.top.control = "RUN"
end sub

sub runRequest()
    request = m.top.request
    action = PxtTrim(request.action)
    if action = "get_series_categories"
        getSeriesCategories(request)
    else if action = "get_series"
        getSeries(request)
    else if action = "get_series_info"
        getSeriesInfo(request)
    else
        connect(request)
    end if
end sub

sub connect(request as object)
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

sub getSeriesCategories(request as object)
    json = fetchJson(request, "get_series_categories", invalid)
    if json = invalid then return
    if Type(json) <> "roArray"
        m.top.result = { success: false, action: "get_series_categories", code: "invalid_response", message: "O servidor retornou categorias invalidas." }
        return
    end if
    m.top.result = { success: true, action: "get_series_categories", categories: json }
end sub

sub getSeries(request as object)
    params = invalid
    if PxtTrim(request.category_id) <> "" then params = { category_id: PxtTrim(request.category_id) }
    json = fetchJson(request, "get_series", params)
    if json = invalid then return
    if Type(json) <> "roArray"
        m.top.result = { success: false, action: "get_series", code: "invalid_response", message: "O servidor retornou series invalidas." }
        return
    end if
    m.top.result = { success: true, action: "get_series", series: json, category_id: PxtTrim(request.category_id) }
end sub

sub getSeriesInfo(request as object)
    seriesId = PxtTrim(request.series_id)
    if seriesId = ""
        m.top.result = { success: false, action: "get_series_info", code: "invalid_response", message: "Esta serie nao possui detalhes disponiveis." }
        return
    end if
    json = fetchJson(request, "get_series_info", { series_id: seriesId })
    if json = invalid then return
    if Type(json) <> "roAssociativeArray"
        m.top.result = { success: false, action: "get_series_info", code: "invalid_json", message: "O servidor retornou detalhes invalidos." }
        return
    end if
    m.top.result = { success: true, action: "get_series_info", details: json, series_id: seriesId }
end sub

function fetchJson(request as object, action as string, params as dynamic) as dynamic
    dns = NormalizeDns(request.dns)
    if dns = ""
        m.top.result = { success: false, action: action, code: "invalid_response", message: "O servidor retornou uma resposta inválida." }
        return invalid
    end if
    url = dns + "/player_api.php?username=" + UrlEncodeParam(request.username) + "&password=" + UrlEncodeParam(request.password) + "&action=" + UrlEncodeParam(action)
    if params <> invalid
        for each k in params
            url = url + "&" + k + "=" + UrlEncodeParam(params[k])
        end for
    end if
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
        m.top.result = { success: false, action: action, code: "network", message: networkMessage(action) }
        return invalid
    end if
    msg = wait(15000, port)
    if msg = invalid
        transfer.AsyncCancel()
        m.top.result = { success: false, action: action, code: "timeout", message: timeoutMessage(action) }
        return invalid
    end if
    statusCode = msg.GetResponseCode()
    if statusCode < 200 or statusCode >= 300
        m.top.result = { success: false, action: action, code: "network", message: networkMessage(action) }
        return invalid
    end if
    body = msg.GetString()
    if body = invalid or body.Trim() = ""
        m.top.result = { success: false, action: action, code: "invalid_json", message: invalidMessage(action) }
        return invalid
    end if
    json = ParseJson(body)
    if json = invalid
        m.top.result = { success: false, action: action, code: "invalid_json", message: invalidMessage(action) }
        return invalid
    end if
    return json
end function

function networkMessage(action as string) as string
    if action = "get_series_info" then return "Nao foi possivel carregar os detalhes da serie."
    return "Não foi possível conectar ao servidor."
end function
function timeoutMessage(action as string) as string
    if action = "get_series_info" then return "Tempo de conexao esgotado ao carregar os detalhes."
    return "Tempo de conexão esgotado. Verifique o servidor."
end function
function invalidMessage(action as string) as string
    if action = "get_series_info" then return "O servidor retornou detalhes invalidos."
    return "O servidor retornou uma resposta inválida."
end function
