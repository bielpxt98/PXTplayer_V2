sub init()
    m.top.functionName = "run"
end sub

sub run()
    transfer = CreateObject("roUrlTransfer")
    if transfer = invalid
        m.top.result = { success: false, errorMessage: "Conexão indisponível." }
        return
    end if

    dns = normalizeDns(m.top.dns)
    if dns = "" or m.top.username = "" or m.top.password = ""
        m.top.result = { success: false, errorMessage: "Faça login para carregar filmes." }
        return
    end if

    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    url = dns + "/player_api.php?username=" + transfer.Escape(m.top.username) + "&password=" + transfer.Escape(m.top.password) + "&action=get_vod_streams"
    transfer.SetUrl(url)
    transfer.SetRequest("GET")
    transfer.SetHeaders({ "Accept": "application/json" })
    body = transfer.GetToString()

    if body = invalid or body = ""
        m.top.result = { success: false, errorMessage: "Lista de filmes vazia ou indisponível." }
        return
    end if

    movies = ParseJson(body)
    if movies = invalid
        m.top.result = { success: false, errorMessage: "Não foi possível ler a lista de filmes." }
        return
    end if

    m.top.result = { success: true, movies: movies }
end sub

function normalizeDns(value as string) as string
    dns = Trim(value)
    while Len(dns) > 0 and Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while
    return dns
end function
