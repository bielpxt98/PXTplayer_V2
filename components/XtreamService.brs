sub init()
    m.top.functionName = "run"
end sub

sub run()
    dns = normalizeDns(m.top.dns)
    username = m.top.username
    password = m.top.password

    if dns = "" or username = "" or password = ""
        m.top.result = buildError("Preencha DNS, usuário e senha.")
        return
    end if

    print "conectando Xtream"
    m.top.progress = "Conectando..."
    account = fetchXtreamJson(dns, username, password, "")
    if account.success <> true
        m.top.result = account
        return
    end if

    data = account.data
    authenticated = false
    if data.user_info <> invalid
        if data.user_info.auth <> invalid
            authenticated = data.user_info.auth = 1 or data.user_info.auth = "1"
        end if
        if data.user_info.status <> invalid and LCase(data.user_info.status) = "active"
            authenticated = true
        end if
    end if

    if not authenticated
        m.top.result = buildError("Login Xtream inválido ou usuário inativo.")
        return
    end if

    m.top.progress = "Login realizado com sucesso"
    m.top.result = {
        success: true
        dns: dns
        username: username
        password: password
    }
end sub

function fetchXtreamJson(dns as string, username as string, password as string, action as string) as object
    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()

    url = dns + "/player_api.php?username=" + transfer.Escape(username) + "&password=" + transfer.Escape(password)
    if action <> "" then url = url + "&action=" + action

    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetHeaders({ "Accept": "application/json" })
    transfer.SetMinimumTransferRate(1, 30)

    body = transfer.GetToString()
    code = transfer.GetResponseCode()

    if code < 200 or code >= 300 or body = invalid or body = ""
        return buildError("Servidor não respondeu. Confira o DNS informado.")
    end if

    data = ParseJson(body)
    if data = invalid
        return buildError("Resposta inválida do servidor Xtream.")
    end if

    return { success: true, data: data }
end function

function buildError(message as string) as object
    print "erro ocorrido: " + message
    return { success: false, message: message }
end function

function countItems(value as object) as integer
    if value = invalid then return 0
    if GetInterface(value, "ifArray") <> invalid then return value.Count()
    return 0
end function

function normalizeDns(value as string) as string
    dns = Trim(value)
    while Len(dns) > 0 and Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while
    return dns
end function
