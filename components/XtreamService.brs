sub init()
    m.top.functionName = "runRequest"
end sub

function connect(account as object) as void
  if account = invalid then return
  response = requestXtream(account, "", invalid)
  if response.success = true then
    m.top.connectResult = { success: true, account: account, data: response.data }
  else
    m.top.connectResult = { success: false, message: response.message }
  end if
end function

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

  if type(response.data) <> "roArray" then
    m.top.seriesCategoriesResult = { success: false, message: "Nao foi possivel carregar as categorias." }
    return
  end if

  categories = []
  for each item in response.data
    if type(item) = "roAssociativeArray" and item.category_id <> invalid and item.category_name <> invalid then
      id = item.category_id.toStr()
      name = item.category_name.toStr()
      if id <> "" and name <> "" then categories.push({ id: id, name: name })
    end if
  end for

  m.top.seriesCategoriesResult = { success: true, categories: categories }
end function

function getSeries(account as object, categoryId = invalid as dynamic) as void
  params = invalid
  if categoryId <> invalid and categoryId <> "" and categoryId <> "all" then
    params = { category_id: categoryId.toStr() }
  end if

  response = requestXtream(account, "get_series", params)
  if response.success <> true then
    m.top.seriesResult = { success: false, message: response.message, categoryId: categoryId }
    return
  end if

  if type(response.data) <> "roArray" then
    m.top.seriesResult = { success: false, message: "Nao foi possivel carregar as series.", categoryId: categoryId }
    return
  end if

  series = []
  for each item in response.data
    if type(item) = "roAssociativeArray" and item.series_id <> invalid and item.name <> invalid then
      imageUri = ""
      if item.cover <> invalid and item.cover.toStr() <> "" then
        imageUri = item.cover.toStr()
      else if item.stream_icon <> invalid and item.stream_icon.toStr() <> "" then
        imageUri = item.stream_icon.toStr()
      end if
      series.push({ seriesId: item.series_id.toStr(), title: item.name.toStr(), imageUri: imageUri, categoryId: item.category_id })
    end if
  end for

  m.top.seriesResult = { success: true, series: series, categoryId: categoryId }
end function

function requestXtream(account as object, action as string, params = invalid as dynamic) as object
  if not isValidAccount(account) then return { success: false, message: "Nao foi possivel carregar as series." }

  url = account.dns.toStr() + "/player_api.php?username=" + escape(account.username.toStr()) + "&password=" + escape(account.password.toStr())
  if action <> "" then url = url + "&action=" + action
  if params <> invalid then
    for each key in params
      value = params[key]
      if value <> invalid and value.toStr() <> "" then url = url + "&" + key + "=" + escape(value.toStr())
    end for
  end if

  transfer = createObject("roUrlTransfer")
  transfer.setUrl(url)
  port = createObject("roMessagePort")
  transfer.setMessagePort(port)
  if transfer.asyncGetToString() <> true then return { success: false, message: "Nao foi possivel carregar as series." }

  msg = wait(m.timeoutSeconds * 1000, port)
  if msg = invalid then
    transfer.asyncCancel()
    return { success: false, message: "Tempo de conexao esgotado." }
  end if

  if type(msg) <> "roUrlEvent" or msg.getResponseCode() < 200 or msg.getResponseCode() >= 300 then
    return { success: false, message: "Nao foi possivel carregar as series." }
  end if

  body = msg.getString()
  if body = invalid or body = "" then return { success: false, message: "Nao foi possivel carregar as series." }

  data = parseJson(body)
  if data = invalid then return { success: false, message: "Nao foi possivel carregar as series." }

  return { success: true, data: data }
end function

function isValidAccount(account as object) as boolean
  return account <> invalid and account.dns <> invalid and account.username <> invalid and account.password <> invalid
end function

function escape(value as string) as string
  return createObject("roUrlTransfer").escape(value)
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
