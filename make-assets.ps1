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

function Draw-ElizanMark([System.Drawing.Graphics]$g, [float]$ox, [float]$oy, [float]$sz) {
    $s = $sz / 120.0

    # Turkuaz yuvarlak kare
    $bg = New-RoundedPath $ox $oy $sz $sz (30 * $s)
    $rect = New-Object System.Drawing.RectangleF($ox, $oy, $sz, $sz)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.ColorTranslator]::FromHtml('#2dd4bf'),
        [System.Drawing.ColorTranslator]::FromHtml('#0f766e'),
        55.0)
    $g.FillPath($brush, $bg)
    $brush.Dispose()
    $bg.Dispose()

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

    $bars = @(@(28, 58, 17, 38), @(51, 42, 17, 54), @(74, 50, 17, 46))
    foreach ($b in $bars) {
        $bp = New-RoundedPath ($ox + $b[0] * $s) ($oy + $b[1] * $s) ($b[2] * $s) ($b[3] * $s) (4 * $s)
        $g.FillPath($white, $bp)
        $bp.Dispose()
    }

    $winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#159f95'))
    $windows = @(
        @(32, 63), @(32, 73), @(32, 83),
        @(55, 47), @(55, 57), @(55, 67), @(55, 77), @(55, 87),
        @(78, 55), @(78, 65), @(78, 75), @(78, 85)
    )
    foreach ($w in $windows) {
        $wp = New-RoundedPath ($ox + $w[0] * $s) ($oy + $w[1] * $s) (9 * $s) (6 * $s) (1.5 * $s)
        $g.FillPath($winBrush, $wp)
        $wp.Dispose()
    }

    $sp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $sp.AddBezier($ox + 93 * $s, $oy + 20 * $s, $ox + 94.6 * $s, $oy + 27.4 * $s, $ox + 96.6 * $s, $oy + 29.4 * $s, $ox + 104 * $s, $oy + 31 * $s)
    $sp.AddBezier($ox + 104 * $s, $oy + 31 * $s, $ox + 96.6 * $s, $oy + 32.6 * $s, $ox + 94.6 * $s, $oy + 34.6 * $s, $ox + 93 * $s, $oy + 42 * $s)
    $sp.AddBezier($ox + 93 * $s, $oy + 42 * $s, $ox + 91.4 * $s, $oy + 34.6 * $s, $ox + 89.4 * $s, $oy + 32.6 * $s, $ox + 82 * $s, $oy + 31 * $s)
    $sp.AddBezier($ox + 82 * $s, $oy + 31 * $s, $ox + 89.4 * $s, $oy + 29.4 * $s, $ox + 91.4 * $s, $oy + 27.4 * $s, $ox + 93 * $s, $oy + 20 * $s)
    $sp.CloseFigure()
    $g.FillPath($white, $sp)
    $sp.Dispose()

    $white.Dispose()
    $winBrush.Dispose()
}

function New-Graphics([System.Drawing.Bitmap]$bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return $g
}

$root = "C:\Users\PC\Desktop\Ai\elizan-android\assets"
if (-not (Test-Path $root)) { New-Item -ItemType Directory -Force -Path $root | Out-Null }

# 1) Uygulama ikonu — 1024x1024
$icon = New-Object System.Drawing.Bitmap(1024, 1024)
$g = New-Graphics $icon
$g.Clear([System.Drawing.Color]::Transparent)
Draw-ElizanMark $g 0 0 1024
$icon.Save((Join-Path $root "icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $icon.Dispose()
Write-Output "OK assets\icon.png (1024x1024)"

# 2) Splash — 2732x2732, turkuaz gradyan zemin + ortada marka
$splash = New-Object System.Drawing.Bitmap(2732, 2732)
$g = New-Graphics $splash
$full = New-Object System.Drawing.RectangleF(0, 0, 2732, 2732)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $full,
    [System.Drawing.ColorTranslator]::FromHtml('#2dd4bf'),
    [System.Drawing.ColorTranslator]::FromHtml('#0f766e'),
    60.0)
$g.FillRectangle($bgBrush, $full)
$bgBrush.Dispose()

$markSize = 720
$off = (2732 - $markSize) / 2
Draw-ElizanMark $g $off $off $markSize

$splash.Save((Join-Path $root "splash.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $splash.Dispose()
Write-Output "OK assets\splash.png (2732x2732)"
