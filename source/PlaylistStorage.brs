function LoadPlaylistAccount() as object
    section = CreateObject("roRegistrySection", "playlist")
    return {
        dns: section.Read("dns")
        username: section.Read("username")
        password: section.Read("password")
        status: section.Read("status")
    }
end function

sub SavePlaylistAccount(dns as string, username as string, password as string)
    section = CreateObject("roRegistrySection", "playlist")
    section.Write("dns", dns)
    section.Write("username", username)
    section.Write("password", password)
    section.Write("status", "Conectado")
    section.Flush()
end sub
