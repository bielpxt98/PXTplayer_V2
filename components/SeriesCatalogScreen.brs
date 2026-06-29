sub init()
  m.categoryList = m.top.findNode("categoryList")
  m.seriesGrid = m.top.findNode("seriesGrid")
  m.spinner = m.top.findNode("spinner")
  m.messageLabel = m.top.findNode("messageLabel")
  m.selectedCategoryId = "all"
  m.loadedCategoryId = invalid
  m.categoriesLoading = false
  m.seriesLoading = false
  m.categories = []

  m.categoryList.observeField("itemSelected", "onCategorySelected")
  m.categoryList.observeField("itemFocused", "onCategoryFocused")
  m.seriesGrid.observeField("itemSelected", "onSeriesSelected")
  m.top.observeField("service", "onServiceChanged")
end sub

sub onServiceChanged()
  service = m.top.service
  if service <> invalid then
    service.observeField("seriesCategoriesResult", "onCategoriesResult")
    service.observeField("seriesResult", "onSeriesResult")
  end if
end sub

function loadCategories() as void
  if m.categoriesLoading = true then return
  if m.top.service = invalid or m.top.account = invalid then return
  m.categoriesLoading = true
  showLoading("Carregando categorias...")
  m.top.service.callFunc("getSeriesCategories", m.top.account)
end function

sub onCategoriesResult()
  m.categoriesLoading = false
  hideLoading()
  result = m.top.service.seriesCategoriesResult
  if result = invalid or result.success <> true then
    m.messageLabel.text = "Nao foi possivel carregar as categorias."
    return
  end if

  m.categories = [{ id: "all", name: "TODAS" }]
  for each category in result.categories
    if category.id <> invalid and category.name <> invalid then m.categories.push(category)
  end for

  if m.categories.count() = 1 then
    m.messageLabel.text = "Nenhuma categoria de serie encontrada."
  else
    m.messageLabel.text = ""
  end if
  renderCategories()
  m.categoryList.setFocus(true)
end sub

sub renderCategories()
  content = createObject("roSGNode", "ContentNode")
  for each category in m.categories
    item = content.createChild("ContentNode")
    item.title = category.name
    item.addField("categoryId", "string", false)
    item.categoryId = category.id
  end for
  m.categoryList.content = content
end sub

sub onCategoryFocused()
  index = m.categoryList.itemFocused
  if index >= 0 and index < m.categories.count() then m.selectedCategoryId = m.categories[index].id
end sub

sub onCategorySelected()
  if m.seriesLoading = true or m.categoriesLoading = true then return
  index = m.categoryList.itemSelected
  if index < 0 or index >= m.categories.count() then return
  categoryId = m.categories[index].id
  m.selectedCategoryId = categoryId
  if m.loadedCategoryId <> invalid and m.loadedCategoryId = categoryId then return
  m.seriesLoading = true
  showLoading("Carregando series...")
  if categoryId = "all" then
    m.top.service.callFunc("getSeries", m.top.account, "all")
  else
    m.top.service.callFunc("getSeries", m.top.account, categoryId)
  end if
end sub

sub onSeriesResult()
  m.seriesLoading = false
  hideLoading()
  result = m.top.service.seriesResult
  if result = invalid or result.success <> true then
    m.messageLabel.text = "Nao foi possivel carregar as series."
    return
  end if

  renderSeries(result.series)
  m.loadedCategoryId = result.categoryId
  if result.series = invalid or result.series.count() = 0 then
    m.messageLabel.text = "Nenhuma serie encontrada nesta categoria."
  else
    m.messageLabel.text = ""
  end if
end sub

sub renderSeries(series as object)
  content = createObject("roSGNode", "ContentNode")
  if series <> invalid then
    for each show in series
      item = content.createChild("ContentNode")
      item.title = show.title
      item.url = show.imageUri
      item.addField("seriesId", "string", false)
      item.seriesId = show.seriesId
    end for
  end if
  m.seriesGrid.content = content
end sub

sub onSeriesSelected()
end sub

sub showLoading(message as string)
  m.messageLabel.text = message
  m.spinner.visible = true
  m.spinner.control = "start"
end sub

sub hideLoading()
  m.spinner.control = "stop"
  m.spinner.visible = false
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if press = false then return false
  if m.categoriesLoading = true or m.seriesLoading = true then return true

  if key = "back" then
    if m.seriesGrid.hasFocus() then
      m.categoryList.setFocus(true)
    else
      m.top.backToLogin = true
    end if
    return true
  else if key = "right" and m.categoryList.hasFocus() then
    if m.seriesGrid.content <> invalid and m.seriesGrid.content.getChildCount() > 0 then m.seriesGrid.setFocus(true)
    return true
  else if key = "left" and m.seriesGrid.hasFocus() then
    if m.seriesGrid.itemFocused mod 4 = 0 then
      m.categoryList.setFocus(true)
      return true
    end if
  end if

  return false
end function
