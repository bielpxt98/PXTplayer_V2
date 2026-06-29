sub init()
  m.timeoutSeconds = 15
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

function getSeriesCategories(account as object) as void
  response = requestXtream(account, "get_series_categories", invalid)
  if response.success <> true then
    m.top.seriesCategoriesResult = { success: false, message: response.message }
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
