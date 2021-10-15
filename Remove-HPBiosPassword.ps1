Param (
	[Parameter(Mandatory = $True)]
	[string]$BIOSPassword
)




Function ConvertTo-KBDString {
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [Alias("UniStr")]
        [AllowEmptyString()]
        [String]
        $UnicodeString
    )

    $kbdHexVals = New-Object System.Collections.Hashtable
    $kbdHexVals."a" = "1E"
    $kbdHexVals."b" = "30"
    $kbdHexVals."c" = "2E"
    $kbdHexVals."d" = "20"
    $kbdHexVals."e" = "12"
    $kbdHexVals."f" = "21"
    $kbdHexVals."g" = "22"
    $kbdHexVals."h" = "23"
    $kbdHexVals."i" = "17"
    $kbdHexVals."j" = "24"
    $kbdHexVals."k" = "25"
    $kbdHexVals."l" = "26"
    $kbdHexVals."m" = "32"
    $kbdHexVals."n" = "31"
    $kbdHexVals."o" = "18"
    $kbdHexVals."p" = "19"
    $kbdHexVals."q" = "10"
    $kbdHexVals."r" = "13"
    $kbdHexVals."s" = "1F"
    $kbdHexVals."t" = "14"
    $kbdHexVals."u" = "16"
    $kbdHexVals."v" = "2F"
    $kbdHexVals."w" = "11"
    $kbdHexVals."x" = "2D"
    $kbdHexVals."y" = "15"
    $kbdHexVals."z" = "2C"
    $kbdHexVals."A" = "9E"
    $kbdHexVals."B" = "B0"
    $kbdHexVals."C" = "AE"
    $kbdHexVals."D" = "A0"
    $kbdHexVals."E" = "92"
    $kbdHexVals."F" = "A1"
    $kbdHexVals."G" = "A2"
    $kbdHexVals."H" = "A3"
    $kbdHexVals."I" = "97"
    $kbdHexVals."J" = "A4"
    $kbdHexVals."K" = "A5"
    $kbdHexVals."L" = "A6"
    $kbdHexVals."M" = "B2"
    $kbdHexVals."N" = "B1"
    $kbdHexVals."O" = "98"
    $kbdHexVals."P" = "99"
    $kbdHexVals."Q" = "90"
    $kbdHexVals."R" = "93"
    $kbdHexVals."S" = "9F"
    $kbdHexVals."T" = "94"
    $kbdHexVals."U" = "96"
    $kbdHexVals."V" = "AF"
    $kbdHexVals."W" = "91"
    $kbdHexVals."X" = "AD"
    $kbdHexVals."Y" = "95"
    $kbdHexVals."Z" = "AC"
    $kbdHexVals."1" = "02"
    $kbdHexVals."2" = "03"
    $kbdHexVals."3" = "04"
    $kbdHexVals."4" = "05"
    $kbdHexVals."5" = "06"
    $kbdHexVals."6" = "07"
    $kbdHexVals."7" = "08"
    $kbdHexVals."8" = "09"
    $kbdHexVals."9" = "0A"
    $kbdHexVals."0" = "0B"
    $kbdHexVals."!" = "82"
    $kbdHexVals."@" = "83"
    $kbdHexVals."#" = "84"
    $kbdHexVals."$" = "85"
    $kbdHexVals."%" = "86"
    $kbdHexVals."^" = "87"
    $kbdHexVals."&" = "88"
    $kbdHexVals."*" = "89"
    $kbdHexVals."(" = "8A"
    $kbdHexVals.")" = "8B"
    $kbdHexVals."-" = "0C"
    $kbdHexVals."_" = "8C"
    $kbdHexVals."=" = "0D"
    $kbdHexVals."+" = "8D"
    $kbdHexVals."[" = "1A"
    $kbdHexVals."{" = "9A"
    $kbdHexVals."]" = "1B"
    $kbdHexVals."}" = "9B"
    $kbdHexVals.";" = "27"
    $kbdHexVals.":" = "A7"
    $kbdHexVals."'" = "28"
    $kbdHexVals."`"" = "A8"
    $kbdHexVals."``" = "29"
    $kbdHexVals."~" = "A9"
    $kbdHexVals."\" = "2B"
    $kbdHexVals."|" = "AB"
    $kbdHexVals."," = "33"
    $kbdHexVals."<" = "B3"
    $kbdHexVals."." = "34"
    $kbdHexVals.">" = "B4"
    $kbdHexVals."/" = "35"
    $kbdHexVals."?" = "B5"

    foreach ($char in $UnicodeString.ToCharArray()) {
        $kbdEncodedString += $kbdHexVals.Get_Item($char.ToString())
    }

    return $kbdEncodedString
}



$PasswordEncoding = (Get-WmiObject -Namespace root/hp/InstrumentedBIOS -Class HP_BIOSSetting | Where-Object Name -EQ "Setup Password").SupportedEncoding

switch ($PasswordEncoding) {
    "kbd" { 
        $HPBIOSPassword = "<kbd/>" + (ConvertTo-KBDString -UnicodeString $BiosPassword)
    }
    "utf-16" { 
        $HPBIOSPassword = "<utf-16/>" + $BiosPassword
    }
    defualt {
        throw "Current setup password encoding unknown, exiting." 
    }
}

# $HPBIOSPassword = "<utf-16/>" + "$BiosPassword"
$GetHPBIOSObject = Get-WmiObject -Class HP_BiosSettingInterface -Namespace "root\hp\instrumentedbios"
$ClearHPBiosPassword = ($GetHPBIOSObject.SetBIOSSetting('Setup Password', "<$PasswordEncoding/>", $HPBIOSPassword)).Return

Write-Host $ClearHPBiosPassword
