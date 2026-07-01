sub init()
    m.top.functionName = "run"
end sub

sub run()
    dns = normalizeDns(m.top.dns)
    username = m.top.username
    password = m.top.password

    m.top.progress = "Preparando conexão"
    m.top.debug = "Preparando conexão" + Chr(10) + "DNS usado: " + dns

    if dns = "" or username = "" or password = ""
        m.top.result = buildError("Preencha DNS, usuário e senha.", "validação", invalid, invalid, invalid)
        return
    end if

    m.top.progress = "Enviando login"
    account = fetchXtreamJson(dns, username, password)
    if account.success <> true
        m.top.result = account
        return
    end if

    data = account.data
    m.top.progress = "Aguardando resposta"
    authenticated = false
    authValue = invalid
    if data.user_info <> invalid
        if data.user_info.auth <> invalid
            authValue = data.user_info.auth
            authenticated = data.user_info.auth = 1 or data.user_info.auth = "1"
        end if
    end if

    if not authenticated
        m.top.result = buildError("Falha de autenticação: user_info.auth diferente de 1 (valor: " + safeToString(authValue) + ").", "Aguardando resposta", account.httpCode, invalid, account.rawResponseSnippet)
        return
    end if

    m.top.progress = "Login realizado com sucesso"
    m.top.debug = "Login realizado com sucesso"
    m.top.result = {
        success: true
        dns: dns
        username: username
        password: password
        errorMessage: ""
        httpCode: account.httpCode
        rawResponseSnippet: account.rawResponseSnippet
    }
end sub

function fetchXtreamJson(dns as string, username as string, password as string) as object
    transfer = CreateObject("roUrlTransfer")
    if transfer = invalid
        return buildError("Não foi possível conectar no simulador. Teste na Roku real.", "Preparando conexão", invalid, "roUrlTransfer indisponível", invalid)
    end if

    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()

    url = dns + "/player_api.php?username=" + transfer.Escape(username) + "&password=" + transfer.Escape(password)
    safeUrl = dns + "/player_api.php?username=" + transfer.Escape(username) + "&password=" + maskPassword(password)

    m.top.progress = "Enviando login"
    m.top.debug = "Enviando login" + Chr(10) + "DNS usado: " + dns + Chr(10) + "URL: " + safeUrl

    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetHeaders({ "Accept": "application/json" })
    transfer.SetMinimumTransferRate(1, 10)

    if not transfer.AsyncGetToString()
        return buildError("Não foi possível conectar no simulador. Teste na Roku real.", "Enviando login", invalid, "AsyncGetToString retornou false", invalid)
    end if

    m.top.progress = "Aguardando resposta"
    m.top.debug = "Aguardando resposta" + Chr(10) + "DNS usado: " + dns + Chr(10) + "URL: " + safeUrl

    event = wait(8000, port)
    if event = invalid
        transfer.AsyncCancel()
        return buildError("Timeout ao conectar no Xtream após 8 segundos.", "Aguardando resposta", invalid, "timeout", invalid)
    end if

    code = event.GetResponseCode()
    body = event.GetString()
    failure = event.GetFailureReason()
    preview = makePreview(body)

    m.top.progress = "Aguardando resposta"
    m.top.debug = "Aguardando resposta" + Chr(10) + "DNS usado: " + dns + Chr(10) + "URL: " + safeUrl + Chr(10) + "Etapa: resposta recebida" + Chr(10) + "HTTP: " + safeToString(code) + Chr(10) + "roUrlTransfer: " + safeToString(failure) + Chr(10) + "Resposta: " + preview

    if body = invalid or body = ""
        return buildError("Resposta vazia do servidor Xtream.", "resposta vazia", code, failure, preview)
    end if

    if code < 200 or code >= 300
        return buildError("Erro HTTP no login Xtream: " + safeToString(code) + ".", "http", code, failure, preview)
    end if

    data = ParseJson(body)
    if data = invalid
        return buildError("JSON inválido retornado pelo servidor Xtream.", "json", code, failure, preview)
    end if

    return { success: true, data: data, httpCode: code, rawResponseSnippet: preview, preview: preview, errorMessage: "" }
end function

function buildError(message as string, stage as string, httpCode as dynamic, transferError as dynamic, preview as dynamic) as object
    debug = stage + Chr(10) + "Erro: " + message
    if httpCode <> invalid then debug = debug + Chr(10) + "HTTP: " + safeToString(httpCode)
    if transferError <> invalid and transferError <> "" then debug = debug + Chr(10) + "roUrlTransfer: " + safeToString(transferError)
    if preview <> invalid and preview <> "" then debug = debug + Chr(10) + "Resposta: " + safeToString(preview)
    m.top.debug = debug
    print "erro ocorrido: " + message
    return { success: false, errorMessage: message, message: message, httpCode: httpCode, rawResponseSnippet: preview, debug: debug }
end function

function normalizeDns(value as string) as string
    dns = Trim(value)
    while Len(dns) > 0 and Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while
    return dns
end function

function maskPassword(password as string) as string
    if password = invalid or password = "" then return ""
    if Len(password) <= 2 then return "**"
    return Left(password, 2) + "***"
end function

function makePreview(body as dynamic) as string
    if body = invalid then return ""
    cleaned = Left(body, 180)
    return cleaned
end function

function safeToString(value as dynamic) as string
    if value = invalid then return "invalid"
    return value.ToStr()
end function
