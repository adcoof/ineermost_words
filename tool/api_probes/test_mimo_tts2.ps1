# Probe MiMo API for TTS endpoints. Key stays in a variable, never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"

$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
if (-not $key) { Write-Output "FAIL: no api key"; exit 1 }
Write-Output ("key loaded, len=" + $key.Length)

# 1) models list
Write-Output "=== GET /models ==="
& curl.exe -s -m 30 "$base/models" -H "Authorization: Bearer $key"
Write-Output ""

# 2) try common TTS paths with POST
$paths = @("/audio/speech", "/audio/tts", "/tts", "/audio/synthesize", "/text-to-speech", "/audio/generations")
$body = '{"model":"mimo-v2.5-tts","input":"test","voice":"alloy","response_format":"mp3"}'
[System.IO.File]::WriteAllText("$PSScriptRoot\tts_req.json", $body, (New-Object System.Text.UTF8Encoding($false)))

foreach ($p in $paths) {
    Write-Output "=== POST $p ==="
    & curl.exe -s -m 30 -o "$PSScriptRoot\tts_out.bin" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" `
        -X POST "$base$p" `
        -H "Authorization: Bearer $key" `
        -H "Content-Type: application/json" `
        --data-binary "@$PSScriptRoot\tts_req.json"
    Write-Output ""
    $head = [System.IO.File]::ReadAllBytes("$PSScriptRoot\tts_out.bin")
    if ($head.Length -gt 0 -and $head.Length -lt 2048) {
        Write-Output ([System.Text.Encoding]::UTF8.GetString($head))
    } elseif ($head.Length -ge 4) {
        $first4 = ($head[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '
        Write-Output ("binary len=" + $head.Length + " first4=" + $first4)
    }
    Write-Output ""
}
