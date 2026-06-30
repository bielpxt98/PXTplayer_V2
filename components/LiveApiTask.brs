sub init()
    m.top.functionName = "run"
end sub

sub run()
    credentials = m.top.credentials
    action = m.top.action
    result = { success: false, status: "network", message: "Não foi possível conectar.", action: action, requestId: m.top.requestId }

    if credentials = invalid or credentials.dns = invalid or credentials.username = invalid or credentials.password = invalid
        m.top.result = result
        return
    end if

    if action <> "get_live_categories" and action <> "get_live_streams"
        result.message = "Requisição inválida."
        result.status = "invalid"
        m.top.result = result
        return
    end if

    url = credentials.dns + "/player_api.php?username=" + escape(credentials.username) + "&password=" + escape(credentials.password) + "&action=" + action
    if action = "get_live_streams"
        url = url + "&category_id=" + escape(m.top.categoryId)
    end if

    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetMinimumTransferRate(1, 20)

    response = transfer.GetToString()
    code = transfer.GetResponseCode()

    if code = 0
        m.top.result = result
        return
    else if response = invalid or response = ""
        result.status = "timeout"
        result.message = "Tempo de conexão esgotado."
        m.top.result = result
        return
    else if code < 200 or code >= 300
        result.status = "network"
        m.top.result = result
        return
    end if

    data = ParseJson(response)
    if data = invalid
        result.status = "invalid"
        result.message = "Não foi possível conectar."
        m.top.result = result
        return
    end if

    m.top.result = { success: true, status: "ok", message: "", action: action, requestId: m.top.requestId, items: data }
end sub

function escape(value as dynamic) as string
    if value = invalid then return ""
    return CreateObject("roUrlTransfer").Escape(value.ToStr())
end function
