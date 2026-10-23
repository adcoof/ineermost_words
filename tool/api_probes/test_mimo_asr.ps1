# Probe mimo-v2.5-asr request shape using the WAV we just synthesized.
# Also discover which TTS voices are accepted. Key never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"
$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
Write-Output ("key loaded, len=" + $key.Length)

# ---- ASR: chat.completions with input_audio (OpenAI multimodal style) ----
$wavB64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$PSScriptRoot\tts_out.wav"))
$body = @"
{
  "model": "mimo-v2.5-asr",
  "messages": [
    {"role": "user", "content": [
      {"type": "input_audio", "input_audio": {"data": "$wavB64", "format": "wav"}},
      {"type": "text", "text": "Transcribe the audio."}
    ]}
  ]
}
"@
[System.IO.File]::WriteAllText("$PSScriptRoot\asr_req.json", $body, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "=== POST /chat/completions (mimo-v2.5-asr, input_audio in content) ==="
& curl.exe -s -m 90 -o "$PSScriptRoot\asr_resp.json" -w "HTTP=%{http_code} SIZE=%{size_download}" `
    -X POST "$base/chat/completions" `
    -H "Authorization: Bearer $key" `
    -H "Content-Type: application/json" `
    --data-binary "@$PSScriptRoot\asr_req.json"
Write-Output ""
$raw = [System.IO.File]::ReadAllText("$PSScriptRoot\asr_resp.json")
if ($raw.Length -lt 3000) { Write-Output $raw } else { Write-Output ("resp len=" + $raw.Length); try { $j = $raw | ConvertFrom-Json; Write-Output ("content=" + $j.choices[0].message.content) } catch {} }

# ---- ASR fallback shape: audio as top-level data_url ----
$body2 = @"
{
  "model": "mimo-v2.5-asr",
  "messages": [
    {"role": "user", "content": [
      {"type": "input_audio", "input_audio": {"data": "data:audio/wav;base64,$wavB64", "format": "wav"}}
    ]}
  ]
}
"@
[System.IO.File]::WriteAllText("$PSScriptRoot\asr_req2.json", $body2, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "=== POST /chat/completions (asr, data-url form) ==="
& curl.exe -s -m 90 -o "$PSScriptRoot\asr_resp2.json" -w "HTTP=%{http_code} SIZE=%{size_download}" `
    -X POST "$base/chat/completions" `
    -H "Authorization: Bearer $key" `
    -H "Content-Type: application/json" `
    --data-binary "@$PSScriptRoot\asr_req2.json"
Write-Output ""
$raw2 = [System.IO.File]::ReadAllText("$PSScriptRoot\asr_resp2.json")
if ($raw2.Length -lt 3000) { Write-Output $raw2 } else { Write-Output ("resp len=" + $raw2.Length); try { $j = $raw2 | ConvertFrom-Json; Write-Output ("content=" + $j.choices[0].message.content) } catch {} }

# ---- TTS voice probing ----
foreach ($voice in @("Chloe", "alloy", "xiaoyi", "Aria")) {
    $b = "{`"model`":`"mimo-v2.5-tts`",`"messages`":[{`"role`":`"user`",`"content`":`"Neutral.`"},{`"role`":`"assistant`",`"content`":`"hi`"}],`"audio`":{`"format`":`"wav`",`"voice`":`"$voice`"}}"
    [System.IO.File]::WriteAllText("$PSScriptRoot\voice_req.json", $b, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output "=== TTS voice=$voice ==="
    & curl.exe -s -m 60 -o "$PSScriptRoot\voice_resp.json" -w "HTTP=%{http_code} SIZE=%{size_download}" `
        -X POST "$base/chat/completions" `
        -H "Authorization: Bearer $key" `
        -H "Content-Type: application/json" `
        --data-binary "@$PSScriptRoot\voice_req.json"
    Write-Output ""
    try {
        $j = [System.IO.File]::ReadAllText("$PSScriptRoot\voice_resp.json") | ConvertFrom-Json
        if ($j.choices[0].message.audio.data) { Write-Output "voice OK" } elseif ($j.error) { Write-Output ("err=" + $j.error.message) } else { Write-Output "no audio field" }
    } catch { Write-Output "unparseable" }
}
