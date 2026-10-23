# Probe MiMo platform docs + more TTS/ASR endpoint shapes. Key never printed.
$adb = "D:\Software\Android\Sdk\platform-tools\adb.exe"
$base = "https://token-plan-cn.xiaomimimo.com/v1"

$key = (& $adb -s 127.0.0.1:16384 shell "run-as app.airoleplay.ai_roleplay_chat sqlite3 app_flutter/ai_roleplay_chat.sqlite 'SELECT api_key FROM api_profiles WHERE is_default=1;'").Trim()
Write-Output ("key loaded, len=" + $key.Length)

# docs / spec discovery on the same host (no auth needed usually)
foreach ($u in @(
    "https://platform.xiaomimimo.com/",
    "https://platform.xiaomimimo.com/docs",
    "https://token-plan-cn.xiaomimimo.com/openapi.json",
    "https://token-plan-cn.xiaomimimo.com/v1/openapi.json",
    "https://token-plan-cn.xiaomimimo.com/docs"
)) {
    Write-Output "=== GET $u ==="
    & curl.exe -s -m 20 -L -o "$PSScriptRoot\page.html" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" "$u"
    Write-Output ""
}

# more endpoint shapes
$paths = @(
    "/audio/speech",
    "/audio/transcriptions",
    "/audio/translations",
    "/audio/asr",
    "/asr",
    "/speech",
    "/speech/tts",
    "/speech/asr",
    "/tts/speech",
    "/mimo/tts",
    "/mimo/audio/speech"
)
foreach ($p in $paths) {
    Write-Output "=== POST $p (tts body) ==="
    & curl.exe -s -m 20 -o "$PSScriptRoot\tts_out.bin" -w "HTTP=%{http_code} TYPE=%{content_type} SIZE=%{size_download}" `
        -X POST "$base$p" `
        -H "Authorization: Bearer $key" `
        -H "Content-Type: application/json" `
        --data-binary "@$PSScriptRoot\tts_req.json"
    Write-Output ""
    $head = [System.IO.File]::ReadAllBytes("$PSScriptRoot\tts_out.bin")
    if ($head.Length -gt 0 -and $head.Length -lt 1024) {
        Write-Output ([System.Text.Encoding]::UTF8.GetString($head))
    }
}
