# Probe api.xiaomimimo.com and mimo.mi.com for TTS/ASR endpoints. Key never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
Write-Output ("key loaded, len=" + $key.Length)

$body = '{"model":"mimo-v2.5-tts","input":"hello tts test","voice":"alloy","response_format":"mp3"}'
[System.IO.File]::WriteAllText("$PSScriptRoot\tts_req.json", $body, (New-Object System.Text.UTF8Encoding($false)))

$hosts = @("https://api.xiaomimimo.com", "https://mimo.mi.com")
$paths = @("/v1/audio/speech", "/v1/audio/transcriptions", "/v1/tts", "/v1/asr", "/audio/speech", "/api/v1/audio/speech")

foreach ($h in $hosts) {
    foreach ($p in $paths) {
        Write-Output "=== POST $h$p ==="
        & curl.exe -s -m 20 -o "$PSScriptRoot\tts_out.bin" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" `
            -X POST "$h$p" `
            -H "Authorization: Bearer $key" `
            -H "Content-Type: application/json" `
            --data-binary "@$PSScriptRoot\tts_req.json"
        Write-Output ""
        $head = [System.IO.File]::ReadAllBytes("$PSScriptRoot\tts_out.bin")
        if ($head.Length -gt 0 -and $head.Length -lt 1024) {
            Write-Output ([System.Text.Encoding]::UTF8.GetString($head))
        } elseif ($head.Length -ge 4) {
            $first4 = ($head[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '
            Write-Output ("binary len=" + $head.Length + " first4=" + $first4)
        }
    }
    Write-Output "=== GET $h/v1/models ==="
    & curl.exe -s -m 20 "$h/v1/models" -H "Authorization: Bearer $key"
    Write-Output ""
}
