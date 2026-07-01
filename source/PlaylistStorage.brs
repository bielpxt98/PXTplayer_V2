' TEMPORÁRIO PARA TESTE: remova este bloco antes de publicar o app.
' Credenciais usadas somente para facilitar testes no Roku/simulador sem digitação repetida.
function GetTemporaryTestXtreamCredentials() as object
    return {
        TEST_DNS: "http://ttvp2.live"
        TEST_USERNAME: "20082016"
        TEST_PASSWORD: "10012024"
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
    if saved.dns <> invalid and saved.dns <> "" and saved.username <> invalid and saved.username <> "" and saved.password <> invalid and saved.password <> ""
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
