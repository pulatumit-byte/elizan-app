# Elizan Android paketi — yerel ön kontrol
# Kullanım: powershell -NoProfile -ExecutionPolicy Bypass -File dogrula.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$fail = 0

function Ok($m)   { Write-Host ("  [OK]   " + $m) -ForegroundColor Green }
function Warn($m) { Write-Host ("  [UYARI] " + $m) -ForegroundColor Yellow }
function Bad($m)  { Write-Host ("  [HATA] " + $m) -ForegroundColor Red; $script:fail++ }

Write-Host "`n=== Elizan Android on kontrol ===" -ForegroundColor Cyan

# 1) Zorunlu dosyalar
Write-Host "`n[1] Zorunlu dosyalar"
$need = @(
  ".github\workflows\android.yml",
  "package.json",
  "capacitor.config.json",
  "www\index.html",
  "www\prototype.html",
  "www\manifest.webmanifest",
  "www\icons\icon-192.png",
  "www\icons\icon-512.png",
  "assets\icon.png",
  "assets\splash.png"
)
foreach ($f in $need) {
  if (Test-Path (Join-Path $root $f)) { Ok $f } else { Bad "eksik: $f" }
}

# 2) JSON gecerliligi
Write-Host "`n[2] JSON dosyalari"
foreach ($j in @("package.json", "capacitor.config.json", "www\manifest.webmanifest")) {
  $p = Join-Path $root $j
  try { Get-Content $p -Raw | ConvertFrom-Json | Out-Null; Ok "$j gecerli" }
  catch { Bad "$j bozuk: $($_.Exception.Message)" }
}

# 3) Manifest alanlari
Write-Host "`n[3] Manifest alanlari"
$mf = Get-Content (Join-Path $root "www\manifest.webmanifest") -Raw | ConvertFrom-Json
if ($mf.name)          { Ok "name: $($mf.name)" } else { Bad "name yok" }
if ($mf.start_url)     { Ok "start_url: $($mf.start_url)" } else { Bad "start_url yok" }
if ($mf.display)       { Ok "display: $($mf.display)" } else { Bad "display yok" }
if ($mf.icons.Count -ge 2) { Ok "ikon sayisi: $($mf.icons.Count)" } else { Bad "ikon sayisi yetersiz" }
foreach ($ic in $mf.icons) {
  $ip = Join-Path $root ("www\" + ($ic.src -replace '/', '\'))
  if (Test-Path $ip) { Ok "ikon mevcut: $($ic.src)" } else { Bad "ikon eksik: $($ic.src)" }
}

# 4) Ikon boyutlari
Write-Host "`n[4] Gorsel boyutlari"
Add-Type -AssemblyName System.Drawing
foreach ($pair in @(@("assets\icon.png", 1024), @("www\icons\icon-192.png", 192), @("www\icons\icon-512.png", 512))) {
  $p = Join-Path $root $pair[0]
  if (Test-Path $p) {
    $img = [System.Drawing.Image]::FromFile($p)
    if ($img.Width -eq $pair[1]) { Ok "$($pair[0]) = $($img.Width)x$($img.Height)" }
    else { Warn "$($pair[0]) = $($img.Width)x$($img.Height), beklenen $($pair[1])" }
    $img.Dispose()
  } else { Bad "gorsel yok: $($pair[0])" }
}

# 5) Workflow icerigi
Write-Host "`n[5] Workflow kontrolu"
$wf = Get-Content (Join-Path $root ".github\workflows\android.yml") -Raw
$checks = @(
  @("actions/checkout@v4", "checkout adimi"),
  @("setup-java@v4", "Java kurulumu"),
  @("android-actions/setup-android@v3", "Android SDK"),
  @("cap add android", "Android platformu"),
  @("assembleDebug", "APK derleme"),
  @("upload-artifact@v4", "artifact yukleme")
)
foreach ($c in $checks) {
  if ($wf.Contains($c[0])) { Ok $c[1] } else { Bad "eksik: $($c[1])" }
}
if ($wf -match "(?m)^\s{2}build:") { Ok "workflow YAML girintisi temel kontrolu" } else { Warn "build job girintisi kontrol edilemedi" }

# 6) Mutlak yol / bozuk referans taramasi
Write-Host "`n[6] www icinde mutlak yol taramasi"
$badRefs = Select-String -Path (Join-Path $root "www\*.html") -Pattern 'src="C:|href="C:|file:///' -SimpleMatch:$false -ErrorAction SilentlyContinue
if ($badRefs) { $badRefs | ForEach-Object { Bad "mutlak yol: $($_.Filename):$($_.LineNumber)" } }
else { Ok "mutlak yol bulunamadi" }

# 7) Boyut ozeti
Write-Host "`n[7] Paket boyutu"
$size = (Get-ChildItem $root -Recurse -File | Measure-Object -Property Length -Sum).Sum
Ok ("toplam: {0:N0} KB" -f ($size / 1KB))

Write-Host "`n=== Sonuc ===" -ForegroundColor Cyan
if ($fail -eq 0) { Write-Host "Tum kontroller gecti. GitHub'a yuklemeye hazir." -ForegroundColor Green }
else { Write-Host "$fail sorun bulundu. Yukaridaki [HATA] satirlarina bakin." -ForegroundColor Red }
exit $fail
