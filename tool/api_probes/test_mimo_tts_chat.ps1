# Test MiMo TTS via chat.completions + audio param (official shape).
# API key stays in a variable, never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
if (-not $key) { Write-Output "FAIL: no api key"; exit 1 }
Write-Output ("key loaded, len=" + $key.Length)

# Official request shape: user = style, assistant = text to speak, audio = {format, voice}
$body = @'
{
  "model": "mimo-v2.5-tts",
  "messages": [
    {"role": "user", "content": "Natural, friendly, clear tone."},
    {"role": "assistant", "content": "Hello, this is a TTS test from the chat app."}
  ],
  "audio": {"format": "wav", "voice": "Chloe"}
}
'@
[System.IO.File]::WriteAllText("$PSScriptRoot\tts_chat_req.json", $body, (New-Object System.Text.UTF8Encoding($false)))

foreach ($h in @("https://api.xiaomimimo.com", "https://token-plan-cn.xiaomimimo.com")) {
    Write-Output "=== POST $h/v1/chat/completions (mimo-v2.5-tts) ==="
    & curl.exe -s -m 90 -o "$PSScriptRoot\tts_chat_resp.json" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" `
        -X POST "$h/v1/chat/completions" `
        -H "Authorization: Bearer $key" `
        -H "Content-Type: application/json" `
        --data-binary "@$PSScriptRoot\tts_chat_req.json"
    Write-Output ""
    $raw = [System.IO.File]::ReadAllText("$PSScriptRoot\tts_chat_resp.json")
    if ($raw.Length -lt 2000) {
        Write-Output $raw
    } else {
        Write-Output ("resp len=" + $raw.Length)
    }
    # Try to extract message.audio.data and decode
    try {
        $j = $raw | ConvertFrom-Json
        $audioB64 = $j.choices[0].message.audio.data
        if ($audioB64) {
            $bytes = [System.Convert]::FromBase64String($audioB64)
            [System.IO.File]::WriteAllBytes("$PSScriptRoot\tts_out.wav", $bytes)
            $first4 = ($bytes[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '
            Write-Output ("AUDIO OK bytes=" + $bytes.Length + " first4=" + $first4)
        } else {
            Write-Output "no message.audio.data in response"
        }
    } catch {
        Write-Output ("parse: " + $_.Exception.Message)
    }
    Write-Output ""
}
