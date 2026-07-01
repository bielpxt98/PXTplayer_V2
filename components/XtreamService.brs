sub init()
    m.top.functionName = "run"
end sub

sub run()
    dns = normalizeDns(m.top.dns)
    username = m.top.username
    password = m.top.password

    if dns = "" or username = "" or password = ""
        m.top.result = { success: false, message: "Preencha DNS, usuário e senha." }
        return
    end if

    transfer = CreateObject("roUrlTransfer")
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.SetUrl(dns + "/player_api.php?username=" + transfer.Escape(username) + "&password=" + transfer.Escape(password))
    transfer.SetRequest("GET")
    transfer.SetHeaders({ "Accept": "application/json" })

    body = transfer.GetToString()
    code = transfer.GetResponseCode()

    if code < 200 or code >= 300 or body = invalid or body = ""
        m.top.result = { success: false, message: "Servidor não respondeu. Confira o DNS informado." }
        return
    end if

    data = ParseJson(body)
    if data = invalid
        m.top.result = { success: false, message: "Resposta inválida do servidor Xtream." }
        return
    end if

    authenticated = false
    if data.user_info <> invalid
        if data.user_info.auth <> invalid
            authenticated = data.user_info.auth = 1 or data.user_info.auth = "1"
        end if
        if data.user_info.status <> invalid and LCase(data.user_info.status) = "active"
            authenticated = true
        end if
    end if

    if authenticated
        m.top.result = {
            success: true
            dns: dns
            username: username
            password: password
        }
    else
        m.top.result = { success: false, message: "Login Xtream inválido ou usuário inativo." }
    end if
end sub

function normalizeDns(value as string) as string
    dns = Trim(value)
    while Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while
    return dns
end function
