# Generate Android launcher icons from tool/app_icon_source.png.
# Stepped downscale (2x stages) for quality, flattened onto near-black bg so
# launcher circle masks never show wallpaper through transparent corners.
# ASCII-only source (PS 5.1 safe).
Add-Type -AssemblyName System.Drawing

$src = "D:\AI_Chat_Project\tool\app_icon_source.png"
$res = "D:\AI_Chat_Project\android\app\src\main\res"
$bg = [System.Drawing.Color]::FromArgb(255, 16, 16, 16)

$sizes = @(
    @("mdpi", 48),
    @("hdpi", 72),
    @("xhdpi", 96),
    @("xxhdpi", 144),
    @("xxxhdpi", 192)
)

function Halve-Down([System.Drawing.Image]$img) {
    $nw = [int]($img.Width / 2)
    $nh = [int]($img.Height / 2)
    $next = New-Object System.Drawing.Bitmap($nw, $nh)
    $g = [System.Drawing.Graphics]::FromImage($next)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $nw, $nh)
    $g.Dispose()
    return $next
}

$img = [System.Drawing.Image]::FromFile($src)
Write-Output ("source: {0}x{1}" -f $img.Width, $img.Height)

foreach ($pair in $sizes) {
    $density = $pair[0]
    $target = [int]$pair[1]

    # stepped halving until within 2x of target
    $cur = $img
    $own = $false
    while ($cur.Width -gt ($target * 2)) {
        $next = Halve-Down $cur
        if ($own) { $cur.Dispose() }
        $cur = $next
        $own = $true
    }

    # flatten onto bg + final high-quality fit
    $bmp = New-Object System.Drawing.Bitmap($target, $target)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear($bg)
    $dest = New-Object System.Drawing.Rectangle(0, 0, $target, $target)
    $g.DrawImage($cur, $dest, 0, 0, $cur.Width, $cur.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    if ($own) { $cur.Dispose() }

    $out = Join-Path $res "mipmap-$density\ic_launcher.png"
    $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output ("wrote {0} ({1}x{1})" -f $out, $target)
}
$img.Dispose()
Write-Output "done"
