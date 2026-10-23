# MiMo TTS endpoint probe. API key stays in a variable, never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"

$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
if (-not $key) { Write-Output "FAIL: no api key in db"; exit 1 }
Write-Output ("key loaded, len=" + $key.Length)

$body = '{"model":"mimo-v2.5-tts","input":"Hello, this is a TTS test.","voice":"alloy","response_format":"mp3"}'
[System.IO.File]::WriteAllText("$PSScriptRoot\tts_req.json", $body, (New-Object System.Text.UTF8Encoding($false)))

& curl.exe -s -o "$PSScriptRoot\tts_out.bin" -D "$PSScriptRoot\tts_hdr.txt" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" `
    -X POST "$base/audio/speech" `
    -H "Authorization: Bearer $key" `
    -H "Content-Type: application/json" `
    --data-binary "@$PSScriptRoot\tts_req.json"
Write-Output ""
Write-Output "--- headers ---"
Get-Content "$PSScriptRoot\tts_hdr.txt"
Write-Output "--- body head ---"
$head = [System.IO.File]::ReadAllBytes("$PSScriptRoot\tts_out.bin")
if ($head.Length -gt 0 -and $head.Length -lt 4096) {
    Write-Output ([System.Text.Encoding]::UTF8.GetString($head))
} elseif ($head.Length -ge 4) {
    $first4 = ($head[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '
    Write-Output ("binary len=" + $head.Length + " first4=" + $first4)
} else {
    Write-Output "empty body"
}
