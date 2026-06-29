sub init()
    m.top.functionName = "runRequest"
end sub

function connect(account as object) as void
    if account = invalid then return
    m.top.action = "connect"
    m.top.dns = account.dns
    m.top.username = account.username
    m.top.password = account.password
    m.top.request = { action: "connect", dns: account.dns, username: account.username, password: account.password }
    m.top.control = "RUN"
end function

function getSeriesCategories(account as object) as void
    if account = invalid then return
    m.top.action = "getSeriesCategories"
    m.top.dns = account.dns
    m.top.username = account.username
    m.top.password = account.password
    m.top.request = { action: "getSeriesCategories", dns: account.dns, username: account.username, password: account.password }
    m.top.control = "RUN"
end function

function getSeries(options as object) as void
    if options = invalid or options.account = invalid then return
    m.top.action = "getSeries"
    m.top.dns = options.account.dns
    m.top.username = options.account.username
    m.top.password = options.account.password
    m.top.category_id = options.category_id
    m.top.request = { action: "getSeries", dns: options.account.dns, username: options.account.username, password: options.account.password, category_id: options.category_id }
    m.top.control = "RUN"
end function

sub runRequest()
    request = m.top.request
    action = PxtTrim(m.top.action)
    if action <> "" then
        request = { action: action, dns: m.top.dns, username: m.top.username, password: m.top.password, category_id: m.top.category_id }
    end if
    if request = invalid then return

    action = PxtTrim(request.action)
    if action = "connect"
        connectRequest(request)
    else if action = "getSeriesCategories"
        getSeriesCategoriesRequest(request)
    else if action = "getSeries"
        getSeriesRequest(request)
    end if
end sub

sub connectRequest(request as object)
    json = fetchJson(request, "connect", invalid)
    if json = invalid then return

    auth = invalid
    if Type(json) = "roAssociativeArray" then auth = json.user_info
    if Type(auth) = "roAssociativeArray" and auth.auth <> invalid and auth.auth.ToStr() = "1"
        publishResult({ request: "connect", success: true, account: { dns: NormalizeDns(request.dns), username: PxtTrim(request.username), password: PxtTrim(request.password) } })
    else
        publishResult({ request: "connect", success: false, code: "invalid_login", message: "Usuario ou senha invalidos." })
    end if
end sub

sub getSeriesCategoriesRequest(request as object)
    json = fetchJson(request, "get_series_categories", invalid)
    if json = invalid then return
    if Type(json) <> "roArray"
        publishResult({ request: "getSeriesCategories", success: false, code: "invalid_response", error: "O servidor retornou categorias invalidas.", message: "O servidor retornou categorias invalidas." })
        return
    end if
    publishResult({ request: "getSeriesCategories", success: true, data: json })
end sub

sub getSeriesRequest(request as object)
    params = invalid
    if PxtTrim(request.category_id) <> "" then params = { category_id: PxtTrim(request.category_id) }
    json = fetchJson(request, "get_series", params)
    if json = invalid then return
    if Type(json) <> "roArray"
        publishResult({ request: "getSeries", success: false, code: "invalid_response", error: "O servidor retornou series invalidas.", message: "O servidor retornou series invalidas." })
        return
    end if
    publishResult({ request: "getSeries", success: true, data: json, category_id: PxtTrim(request.category_id) })
end sub

sub publishResult(result as object)
    if result = invalid then return
    if result.request = "getSeriesCategories" then PRINT "XTREAM_GET_SERIES_CATEGORIES_RESULT"
    m.top.result = result
end sub

function fetchJson(request as object, action as string, params as dynamic) as dynamic
    dns = NormalizeDns(request.dns)
    if dns = ""
        publishResult({ success: false, request: requestNameForAction(action), code: "invalid_response", error: "O servidor retornou uma resposta inválida.", message: "O servidor retornou uma resposta inválida." })
        return invalid
    end if

    url = dns + "/player_api.php?username=" + UrlEncodeParam(PxtTrim(request.username)) + "&password=" + UrlEncodeParam(PxtTrim(request.password))
    if action <> "" and action <> "connect" then url = url + "&action=" + UrlEncodeParam(action)
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
    timeoutMs = requestTimeoutMs(action)
    transfer.SetMinimumTransferRate(1, timeoutMs / 1000)
    transfer.RetainBodyOnError(false)
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)

    if not transfer.AsyncGetToString()
        publishResult({ success: false, request: requestNameForAction(action), code: "network", error: networkMessage(action), message: networkMessage(action) })
        return invalid
    end if

    msg = wait(timeoutMs, port)
    if msg = invalid
        transfer.AsyncCancel()
        publishResult({ success: false, request: requestNameForAction(action), code: "timeout", error: timeoutMessage(action), message: timeoutMessage(action) })
        return invalid
    end if

    statusCode = msg.GetResponseCode()
    if statusCode < 200 or statusCode >= 300
        publishResult({ success: false, request: requestNameForAction(action), code: "network", error: networkMessage(action), message: networkMessage(action) })
        return invalid
    end if

    body = msg.GetString()
    if body = invalid or body.Trim() = ""
        publishResult({ success: false, request: requestNameForAction(action), code: "invalid_json", error: invalidMessage(action), message: invalidMessage(action) })
        return invalid
    end if

    json = ParseJson(body)
    if json = invalid
        publishResult({ success: false, request: requestNameForAction(action), code: "invalid_json", error: invalidMessage(action), message: invalidMessage(action) })
        return invalid
    end if

    return json
end function

function requestNameForAction(action as string) as string
    if action = "get_series_categories" then return "getSeriesCategories"
    if action = "get_series" then return "getSeries"
    return action
end function

function networkMessage(action as string) as string
    return "Não foi possível conectar ao servidor."
end function

function timeoutMessage(action as string) as string
    if action = "get_series_categories" then return "Tempo esgotado ao carregar categorias."
    return "Tempo de conexão esgotado. Verifique o servidor."
end function

function requestTimeoutMs(action as string) as integer
    if action = "get_series_categories" then return 30000
    return 15000
end function

function invalidMessage(action as string) as string
    if action = "get_series_categories" then return "O servidor retornou categorias invalidas."
    if action = "get_series" then return "O servidor retornou series invalidas."
    return "O servidor retornou uma resposta inválida."
end function
