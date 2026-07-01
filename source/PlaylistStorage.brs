function SaveXtreamCredentials(dns as string, username as string, password as string) as void
    section = CreateObject("roRegistrySection", "pxt_player_xtream")
    section.Write("dns", dns)
    section.Write("username", username)
    section.Write("password", password)
    section.Flush()
end function

function LoadXtreamCredentials() as object
    section = CreateObject("roRegistrySection", "pxt_player_xtream")
    return {
        dns: section.Read("dns")
        username: section.Read("username")
        password: section.Read("password")
    }
end function
