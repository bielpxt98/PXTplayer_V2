' TEMPORÁRIO PARA TESTE: remova este bloco antes de publicar o app.
' Credenciais usadas somente para facilitar testes no Roku/simulador sem digitação repetida.
function GetTemporaryTestXtreamCredentials() as object
    return {
        TEST_DNS: "http://alphapublic.top"
        TEST_USERNAME: "175214928"
        TEST_PASSWORD: "371951665"
    }
end function

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

function EnsureXtreamCredentialsForTest() as object
    saved = LoadXtreamCredentials()
    if HasValidXtreamCredentials(saved)
        return saved
    end if

    ' TEMPORÁRIO PARA TESTE: salva as credenciais de teste como se o usuário tivesse digitado.
    testCredentials = GetTemporaryTestXtreamCredentials()
    SaveXtreamCredentials(testCredentials.TEST_DNS, testCredentials.TEST_USERNAME, testCredentials.TEST_PASSWORD)
    return {
        dns: testCredentials.TEST_DNS
        username: testCredentials.TEST_USERNAME
        password: testCredentials.TEST_PASSWORD
    }
end function

function HasValidXtreamCredentials(credentials as object) as boolean
    return credentials <> invalid and credentials.dns <> invalid and credentials.dns <> "" and credentials.username <> invalid and credentials.username <> "" and credentials.password <> invalid and credentials.password <> ""
end function

function MarkContentLoaded() as void
    section = CreateObject("roRegistrySection", "pxt_player_state")
    section.Write("hasLoadedContent", "1")
    section.Delete("accountError")
    section.Delete("reconnectError")
    section.Flush()
end function

function HasLoadedContentCache() as boolean
    section = CreateObject("roRegistrySection", "pxt_player_state")
    return section.Read("hasLoadedContent") = "1"
end function

function ClearAccountErrors() as void
    section = CreateObject("roRegistrySection", "pxt_player_state")
    section.Delete("accountError")
    section.Delete("reconnectError")
    section.Flush()
end function

function SaveReconnectError(message as string) as void
    if HasLoadedContentCache() then return
    section = CreateObject("roRegistrySection", "pxt_player_state")
    section.Write("reconnectError", message)
    section.Flush()
end function
