$langtag = "en-GB"
$imt = "0809:00000809"

$with = Get-WinUserLanguageList
for ($i = 0; $i -lt $with.Count; $i++) {
    if (($with[$i].LanguageTag -eq $langtag) -and (-not ($with[$i].InputMethodTips -contains $imt))) {
        $with[$i].InputMethodTips.Add($imt)
    }
}

$without = Get-WinUserLanguageList
for ($i = 0; $i -lt $without.Count; $i++) {
    if (($without[$i].LanguageTag -eq $langtag) -and ($without[$i].InputMethodTips -contains $imt)) {
        $without[$i].InputMethodTips.Remove($imt)
    }
}

Set-WinUserLanguageList $with -Force

Start-Sleep -Milliseconds 250

Set-WinUserLanguageList $without -Force