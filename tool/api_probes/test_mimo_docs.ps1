# Fetch MiMo platform docs pages and extract API paths / js bundles.
$out = "$PSScriptRoot\mimo_docs"
New-Item -ItemType Directory -Force $out | Out-Null

& curl.exe -s -m 30 -L "https://platform.xiaomimimo.com/docs" -o "$out\docs.html"
& curl.exe -s -m 30 -L "https://platform.xiaomimimo.com/" -o "$out\home.html"

Write-Output "--- docs.html links/scripts ---"
Select-String -Path "$out\docs.html" -Pattern '(src|href)="[^"]+"' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Select-Object -Unique

Write-Output "--- search for api-ish strings in docs.html ---"
Select-String -Path "$out\docs.html" -Pattern 'audio|speech|tts|asr|api|v1|endpoint' -AllMatches |
    ForEach-Object { $_.Line.Trim() } | Select-Object -First 40
