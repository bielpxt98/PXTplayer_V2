sub init()
    m.categoryList = m.top.findNode("categoryList")
    m.seriesGrid = m.top.findNode("seriesGrid")
    m.spinner = m.top.findNode("spinner")
    m.messageLabel = m.top.findNode("messageLabel")
    m.focusArea = "categories"
    m.loading = false
    m.categoriesLoaded = false
    m.top.ObserveField("account", "onAccountChanged")
end sub

sub onAccountChanged()
    m.account = m.top.account
    if m.account <> invalid then
        PRINT "SERIES_ACCOUNT_RECEIVED"
        loadCategories()
    else
        showError("Conta nao encontrada.")
    end if
end sub

sub loadCategories()
    PRINT "LOAD_CATEGORIES_REQUESTED"
    m.top.loadCategoriesRequested = true
    showLoading("Carregando categorias...")
end sub

sub showLoading(message as string)
    m.top.message = message
    m.top.loading = true
end sub

sub hideLoading()
    m.top.loading = false
end sub

sub showError(message as string)
    m.top.message = message
    m.top.loading = false
end sub

sub setCategories(categories as object)
    m.categories = []

    m.categories.Push({
        id: "all",
        name: "TODAS"
    })

    if categories <> invalid then
        for each category in categories
            if category.category_id <> invalid and category.category_name <> invalid then
                m.categories.Push({
                    id: category.category_id.ToStr(),
                    name: category.category_name.ToStr()
                })
            end if
        end for
    end if

    renderCategories()
    hideLoading()
end sub

sub renderCategories()
    m.categoriesLoaded = true
    root = CreateObject("roSGNode", "ContentNode")
    for each cat in m.categories
        n = root.createChild("ContentNode")
        n.title = safe(cat.name, "Categoria")
        n.category_id = safe(cat.id, "")
    end for
    m.categoryList.content = root
    if m.categories.Count() <= 1 then
        m.top.message = "Nenhuma categoria encontrada."
    else
        m.top.message = "Selecione uma categoria e pressione OK."
    end if
    PRINT "SERIES_CATEGORIES_RENDERED"
end sub
sub onCategoriesChanged()
    setCategories(m.top.categories)
end sub
sub onSeriesChanged()
    root = CreateObject("roSGNode", "ContentNode")
    for each s in m.top.series
        n = root.createChild("ContentNode")
        n.name = safe(s.name, "Serie") : n.title = n.name : n.cover = safe(s.cover, safe(s.stream_icon, "")) : n.stream_icon = safe(s.stream_icon, n.cover) : n.series_id = safe(s.series_id, "") : n.category_id = safe(s.category_id, "")
    end for
    m.seriesGrid.content = root
end sub
sub onLoadingChanged()
    m.loading = m.top.loading
    m.spinner.visible = m.loading
    if m.loading then m.spinner.control = "start" else m.spinner.control = "stop"
end sub
sub onMessageChanged()
    m.messageLabel.text = m.top.message
end sub
sub setCatalogFocus()
    if m.focusArea = "series" then m.seriesGrid.setFocus(true) else m.categoryList.setFocus(true)
end sub

sub resetForLoading()
    m.categoriesLoaded = false
    m.focusArea = "categories"
    m.categoryList.content = CreateObject("roSGNode", "ContentNode")
    m.seriesGrid.content = CreateObject("roSGNode", "ContentNode")
end sub
function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.loading then return true
    if key = "right" and m.focusArea = "categories" then m.focusArea = "series" : m.seriesGrid.setFocus(true) : return true
    if key = "left" and m.focusArea = "series" then m.focusArea = "categories" : m.categoryList.setFocus(true) : return true
    if key = "OK"
        if not m.categoriesLoaded or m.categoryList.content = invalid or m.categoryList.content.getChildCount() = 0
            loadCategories()
            return true
        end if
        if m.focusArea = "categories"
            item = focusedNode(m.categoryList)
            if item <> invalid then m.top.categorySelected = { category_id: safe(item.category_id, ""), name: item.title }
        else
            m.top.message = "Selecione uma categoria para carregar o catalogo."
        end if
        return true
    else if key = "back"
        if m.focusArea = "series" then m.focusArea = "categories" : m.categoryList.setFocus(true) else m.top.backRequested = true
        return true
    end if
    return false
end function
function focusedNode(list as object) as dynamic
    if list.content = invalid then return invalid
    idx = list.itemFocused
    if idx < 0 or idx >= list.content.getChildCount() then return invalid
    return list.content.getChild(idx)
end function
function safe(v as dynamic, fallback as string) as string
    if v = invalid then return fallback
    t = v.ToStr()
    if t = "" or LCase(t) = "invalid" or LCase(t) = "null" or LCase(t) = "undefined" then return fallback
    return t
end function
