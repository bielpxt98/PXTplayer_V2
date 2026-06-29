function PxtTrim(value as dynamic) as string
    if value = invalid then return ""
    return value.ToStr().Trim()
end function

function NormalizeDns(rawDns as dynamic) as string
    dns = PxtTrim(rawDns)
    if dns = "" then return ""

    lowerDns = LCase(dns)
    if Left(lowerDns, 7) <> "http://" and Left(lowerDns, 8) <> "https://"
        dns = "http://" + dns
    end if

    while Len(dns) > 0 and Right(dns, 1) = "/"
        dns = Left(dns, Len(dns) - 1)
    end while

    return dns
end function

function UrlEncodeParam(value as dynamic) as string
    transfer = CreateObject("roUrlTransfer")
    return transfer.Escape(PxtTrim(value))
end function

function MaskText(value as dynamic) as string
    text = PxtTrim(value)
    masked = ""
    for i = 1 to Len(text)
        masked = masked + Chr(8226)
    end for
    return masked
end function
