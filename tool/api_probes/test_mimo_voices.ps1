# Probe invalid-voice error body + mp3 format support. Key never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"
$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()

# invalid voice -> error body
$b = '{"model":"mimo-v2.5-tts","messages":[{"role":"user","content":"Neutral."},{"role":"assistant","content":"hi"}],"audio":{"format":"wav","voice":"NoSuchVoice"}}'
[System.IO.File]::WriteAllText("$PSScriptRoot\voice_req.json", $b, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "=== invalid voice error body ==="
& curl.exe -s -m 60 -X POST "$base/chat/completions" -H "Authorization: Bearer $key" -H "Content-Type: application/json" --data-binary "@$PSScriptRoot\voice_req.json"
Write-Output ""

# mp3 format
$b2 = '{"model":"mimo-v2.5-tts","messages":[{"role":"user","content":"Neutral."},{"role":"assistant","content":"hi"}],"audio":{"format":"mp3","voice":"Chloe"}}'
[System.IO.File]::WriteAllText("$PSScriptRoot\voice_req.json", $b2, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "=== format=mp3 ==="
& curl.exe -s -m 60 -o "$PSScriptRoot\mp3_resp.json" -w "HTTP=%{http_code} SIZE=%{size_download}" -X POST "$base/chat/completions" -H "Authorization: Bearer $key" -H "Content-Type: application/json" --data-binary "@$PSScriptRoot\voice_req.json"
Write-Output ""
try {
    $j = [System.IO.File]::ReadAllText("$PSScriptRoot\mp3_resp.json") | ConvertFrom-Json
    if ($j.choices[0].message.audio.data) {
        $bytes = [System.Convert]::FromBase64String($j.choices[0].message.audio.data)
        $first4 = ($bytes[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '
        Write-Output ("mp3 OK bytes=" + $bytes.Length + " first4=" + $first4)
    } elseif ($j.error) { Write-Output ("err=" + $j.error.message) }
} catch { Write-Output "unparseable" }

# try a couple more plausible voices
foreach ($voice in @("Benjamin", "Ben", "Benjamin2", "Benjamin_multilingual", "Chloe2", "default", "male", "female", "zh-CN", "mimo")) {
    $b3 = "{`"model`":`"mimo-v2.5-tts`",`"messages`":[{`"role`":`"user`",`"content`":`"Neutral.`"},{`"role`":`"assistant`",`"content`":`"hi`"}],`"audio`":{`"format`":`"wav`",`"voice`":`"$voice`"}}"
    [System.IO.File]::WriteAllText("$PSScriptRoot\voice_req.json", $b3, (New-Object System.Text.UTF8Encoding($false)))
    $code = & curl.exe -s -m 60 -o "$PSScriptRoot\voice_resp.json" -w "%{http_code}" -X POST "$base/chat/completions" -H "Authorization: Bearer $key" -H "Content-Type: application/json" --data-binary "@$PSScriptRoot\voice_req.json"
    Write-Output ("voice=$voice HTTP=" + $code)
    if ($code -ne "200") {
        try { $j = [System.IO.File]::ReadAllText("$PSScriptRoot\voice_resp.json") | ConvertFrom-Json; Write-Output ("  err=" + $j.error.message) } catch { Write-Output "  (no json)" }
    }
}
