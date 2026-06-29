sub init()
    m.top.functionName = "runRequest"
end sub

function connect(account as object) as void
    if account = invalid then return
    m.top.request = { action: "connect", dns: account.dns, username: account.username, password: account.password }
    m.top.control = "RUN"
end function

function getSeriesCategories(account as object) as void
    if account = invalid then return
    m.top.request = { action: "get_series_categories", dns: account.dns, username: account.username, password: account.password }
    m.top.control = "RUN"
end function

function getSeries(options as object) as void
    if options = invalid or options.account = invalid then return
    m.top.request = { action: "get_series", dns: options.account.dns, username: options.account.username, password: options.account.password, category_id: options.category_id }
    m.top.control = "RUN"
end function

sub runRequest()
    request = m.top.request
    if request = invalid then return

    action = PxtTrim(request.action)
    if action = "connect"
        connectRequest(request)
    else if action = "get_series_categories"
        getSeriesCategoriesRequest(request)
    else if action = "get_series"
        getSeriesRequest(request)
    end if
end sub

sub connectRequest(request as object)
    json = fetchJson(request, "", invalid)
    if json = invalid then return

    auth = invalid
    if Type(json) = "roAssociativeArray" then auth = json.user_info
    if Type(auth) = "roAssociativeArray" and auth.auth <> invalid and auth.auth.ToStr() = "1"
        m.top.result = { success: true, action: "connect", account: { dns: NormalizeDns(request.dns), username: PxtTrim(request.username), password: PxtTrim(request.password) } }
    else
        m.top.result = { success: false, action: "connect", code: "invalid_login", message: "Login inválido. Verifique usuário e senha." }
    end if
end sub

sub getSeriesCategoriesRequest(request as object)
    json = fetchJson(request, "get_series_categories", invalid)
    if json = invalid then return
    if Type(json) <> "roArray"
        m.top.result = { success: false, action: "get_series_categories", code: "invalid_response", message: "O servidor retornou categorias invalidas." }
        return
    end if
    m.top.result = { success: true, action: "get_series_categories", categories: json }
end sub

sub getSeriesRequest(request as object)
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

function fetchJson(request as object, action as string, params as dynamic) as dynamic
    dns = NormalizeDns(request.dns)
    if dns = ""
        m.top.result = { success: false, action: action, code: "invalid_response", message: "O servidor retornou uma resposta inválida." }
        return invalid
    end if

    url = dns + "/player_api.php?username=" + UrlEncodeParam(PxtTrim(request.username)) + "&password=" + UrlEncodeParam(PxtTrim(request.password))
    if action <> "" then url = url + "&action=" + UrlEncodeParam(action)
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
    return "Não foi possível conectar ao servidor."
end function

function timeoutMessage(action as string) as string
    return "Tempo de conexão esgotado. Verifique o servidor."
end function

function invalidMessage(action as string) as string
    if action = "get_series_categories" then return "O servidor retornou categorias invalidas."
    if action = "get_series" then return "O servidor retornou series invalidas."
    return "O servidor retornou uma resposta inválida."
end function
