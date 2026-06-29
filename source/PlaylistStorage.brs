function LoadPlaylistAccount() as object
    section = CreateObject("roRegistrySection", "playlist")
    return {
        dns: section.Read("dns")
        username: section.Read("username")
        password: section.Read("password")
        status: section.Read("status")
    }
end function

function HasValidPlaylistAccount(account as dynamic) as boolean
    if account = invalid then return false
    return PxtTrim(account.dns) <> "" and PxtTrim(account.username) <> "" and PxtTrim(account.password) <> ""
end function

sub SavePlaylistAccount(dns as string, username as string, password as string)
    section = CreateObject("roRegistrySection", "playlist")
    section.Write("dns", dns)
    section.Write("username", username)
    section.Write("password", password)
    section.Write("status", "Conectado")
    section.Flush()
end sub

sub ClearPlaylistAccountAndSeriesCache()
    section = CreateObject("roRegistrySection", "playlist")
    section.Delete("dns")
    section.Delete("username")
    section.Delete("password")
    section.Delete("status")
    section.Flush()
    ClearSeriesCache()
end sub

function LoadSeriesCategoriesCache() as dynamic
    return ReadJsonCache("series_categories")
end function

sub SaveSeriesCategoriesCache(categories as dynamic)
    WriteJsonCache("series_categories", categories)
end sub

function LoadSeriesAllCache() as dynamic
    return ReadJsonCache("series_all")
end function

sub SaveSeriesAllCache(series as dynamic)
    WriteJsonCache("series_all", series)
end sub

function LoadSeriesCategoryCache(categoryId as string) as dynamic
    return ReadJsonCache("series_by_category_" + SafeCacheKey(categoryId))
end function

sub SaveSeriesCategoryCache(categoryId as string, series as dynamic)
    WriteJsonCache("series_by_category_" + SafeCacheKey(categoryId), series)
end sub

sub ClearSeriesCache()
    section = CreateObject("roRegistrySection", "series_cache")
    index = section.Read("cache_index")
    if index <> invalid and index <> ""
        keys = index.Split("|")
        for each key in keys
            DeleteChunkedValue(section, key)
        end for
    end if
    section.Delete("cache_index")
    section.Flush()
end sub

function ReadJsonCache(key as string) as dynamic
    section = CreateObject("roRegistrySection", "series_cache")
    raw = ReadChunkedValue(section, key)
    if raw = invalid or raw = "" then return invalid
    return ParseJson(raw)
end function

sub WriteJsonCache(key as string, value as dynamic)
    if value = invalid then return
    raw = FormatJson(value)
    if raw = invalid or raw = "" then return
    section = CreateObject("roRegistrySection", "series_cache")
    DeleteChunkedValue(section, key)
    chunkSize = 3500
    chunkCount = Int((Len(raw) + chunkSize - 1) / chunkSize)
    section.Write(key + "_chunks", chunkCount.ToStr())
    for i = 0 to chunkCount - 1
        startPos = (i * chunkSize) + 1
        section.Write(key + "_" + i.ToStr(), Mid(raw, startPos, chunkSize))
    end for
    AddCacheIndexKey(section, key)
    section.Flush()
end sub

function ReadChunkedValue(section as object, key as string) as dynamic
    chunkCountText = section.Read(key + "_chunks")
    if chunkCountText = invalid or chunkCountText = "" then return invalid
    chunkCount = Val(chunkCountText)
    if chunkCount <= 0 then return invalid
    raw = ""
    for i = 0 to chunkCount - 1
        part = section.Read(key + "_" + i.ToStr())
        if part = invalid then return invalid
        raw = raw + part
    end for
    return raw
end function

sub DeleteChunkedValue(section as object, key as string)
    chunkCountText = section.Read(key + "_chunks")
    chunkCount = Val(chunkCountText)
    if chunkCount > 0
        for i = 0 to chunkCount - 1
            section.Delete(key + "_" + i.ToStr())
        end for
    end if
    section.Delete(key + "_chunks")
end sub

sub AddCacheIndexKey(section as object, key as string)
    index = section.Read("cache_index")
    if index = invalid or index = ""
        section.Write("cache_index", key)
        return
    end if
    keys = index.Split("|")
    for each existing in keys
        if existing = key then return
    end for
    section.Write("cache_index", index + "|" + key)
end sub

function SafeCacheKey(value as string) as string
    safeValue = PxtTrim(value)
    safeValue = safeValue.Replace("|", "_")
    safeValue = safeValue.Replace("/", "_")
    safeValue = safeValue.Replace("\\", "_")
    safeValue = safeValue.Replace(Chr(10), "_")
    safeValue = safeValue.Replace(Chr(13), "_")
    return safeValue
end function
