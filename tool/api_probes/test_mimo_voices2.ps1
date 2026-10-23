# Verify all 9 voices with Chinese text via JSON \u escapes. Pure ASCII source.
# JSON parsers decode \uXXXX natively, so the API receives real Chinese.
# Key never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"
$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()

# style: natural friendly conversational tone
$styleEscaped = "自然、友好的对话语气。"
# text: hello there, what shall we chat about today?
$textEscaped = "你好呀，今天想聊点什么？"

$pairs = @(
    @("mimo_default", "mimo_default"),
    @("mo_li", "茉莉"),
    @("bing_tang", "冰糖"),
    @("su_da", "苏打"),
    @("bai_hua", "白桦"),
    @("Mia", "Mia"),
    @("Chloe", "Chloe"),
    @("Milo", "Milo"),
    @("Dean", "Dean")
)

foreach ($p in $pairs) {
    $label = $p[0]
    $voiceEscaped = $p[1]
    $b = "{`"model`":`"mimo-v2.5-tts`",`"messages`":[{`"role`":`"user`",`"content`":`"$styleEscaped`"},{`"role`":`"assistant`",`"content`":`"$textEscaped`"}],`"audio`":{`"format`":`"mp3`",`"voice`":`"$voiceEscaped`"}}"
    [System.IO.File]::WriteAllText("$PSScriptRoot\voice_req.json", $b, (New-Object System.Text.UTF8Encoding($false)))
    $code = & curl.exe -s -m 90 -o "$PSScriptRoot\voice_resp.json" -w "%{http_code}" -X POST "$base/chat/completions" -H "Authorization: Bearer $key" -H "Content-Type: application/json" --data-binary "@$PSScriptRoot\voice_req.json"
    Write-Output ("voice=$label HTTP=" + $code)
    if ($code -eq "200") {
        try {
            $j = [System.IO.File]::ReadAllText("$PSScriptRoot\voice_resp.json") | ConvertFrom-Json
            $bytes = [System.Convert]::FromBase64String($j.choices[0].message.audio.data)
            $first2 = ($bytes[0..1] | ForEach-Object { $_.ToString('X2') }) -join ' '
            Write-Output ("  AUDIO OK bytes=" + $bytes.Length + " first2=" + $first2)
        } catch { Write-Output "  parse fail" }
    } else {
        try { $j = [System.IO.File]::ReadAllText("$PSScriptRoot\voice_resp.json") | ConvertFrom-Json; Write-Output ("  err=" + $j.error.message) } catch { Write-Output "  (no json)" }
    }
}
