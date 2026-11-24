Add-Type -AssemblyName System.Drawing

function New-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc(($x + $w - $d), $y, $d, $d, 270, 90)
    $p.AddArc(($x + $w - $d), ($y + $h - $d), $d, $d, 0, 90)
    $p.AddArc($x, ($y + $h - $d), $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function New-ElizanIcon([int]$size, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $s = $size / 120.0
    $rect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)

    # Arka plan: turkuaz gradyan, yuvarlak köşeli
    $bg = New-RoundedPath 0 0 $size $size (30 * $s)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.ColorTranslator]::FromHtml('#2dd4bf'),
        [System.Drawing.ColorTranslator]::FromHtml('#0f766e'),
        55.0)
    $g.FillPath($brush, $bg)

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    # Bina kuleleri
    $bars = @(@(28, 58, 17, 38), @(51, 42, 17, 54), @(74, 50, 17, 46))
    foreach ($b in $bars) {
        $bp = New-RoundedPath ($b[0] * $s) ($b[1] * $s) ($b[2] * $s) ($b[3] * $s) (4 * $s)
        $g.FillPath($white, $bp)
    }

    # Pencereler
    $winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#159f95'))
    $windows = @(
        @(32, 63), @(32, 73), @(32, 83),
        @(55, 47), @(55, 57), @(55, 67), @(55, 77), @(55, 87),
        @(78, 55), @(78, 65), @(78, 75), @(78, 85)
    )
    foreach ($w in $windows) {
        $wp = New-RoundedPath ($w[0] * $s) ($w[1] * $s) (9 * $s) (6 * $s) (1.5 * $s)
        $g.FillPath($winBrush, $wp)
    }

    # Pırıltı yıldızı
    $sp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $sp.AddBezier(93 * $s, 20 * $s, 94.6 * $s, 27.4 * $s, 96.6 * $s, 29.4 * $s, 104 * $s, 31 * $s)
    $sp.AddBezier(104 * $s, 31 * $s, 96.6 * $s, 32.6 * $s, 94.6 * $s, 34.6 * $s, 93 * $s, 42 * $s)
    $sp.AddBezier(93 * $s, 42 * $s, 91.4 * $s, 34.6 * $s, 89.4 * $s, 32.6 * $s, 82 * $s, 31 * $s)
    $sp.AddBezier(82 * $s, 31 * $s, 89.4 * $s, 29.4 * $s, 91.4 * $s, 27.4 * $s, 93 * $s, 20 * $s)
    $sp.CloseFigure()
    $g.FillPath($white, $sp)

    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)

    $g.Dispose(); $bmp.Dispose(); $brush.Dispose(); $white.Dispose(); $winBrush.Dispose()
    Write-Output ("OK  {0}  ({1}x{1})" -f $path, $size)
}

$root = "C:\Users\PC\Desktop\Ai\elizan-pwa\icons"
New-ElizanIcon 512 (Join-Path $root "icon-512.png")
New-ElizanIcon 192 (Join-Path $root "icon-192.png")
New-ElizanIcon 180 (Join-Path $root "apple-touch-icon.png")
