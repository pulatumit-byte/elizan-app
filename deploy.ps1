# Elizan — GitHub'a yukle, derlemeyi calistir, APK'yi indir
# Kullanim: powershell -NoProfile -ExecutionPolicy Bypass -File deploy.ps1
$ErrorActionPreference = "Continue"

$gh   = "C:\Program Files\GitHub CLI\gh.exe"
$git  = "$env:LOCALAPPDATA\GitHubDesktop\app-3.7.0\resources\app\git\cmd\git.exe"
$dir  = "C:\Users\PC\Desktop\Ai\elizan-android"
$repo = "elizan-app"

Set-Location $dir

Write-Host "`n[1/5] GitHub girisi kontrol ediliyor..." -ForegroundColor Cyan
& $gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: GitHub girisi yok. Once su komutu calistirin: gh auth login --web" -ForegroundColor Red
    exit 1
}

$user = (& $gh api user --jq .login).Trim()
Write-Host "      Giris yapildi: $user" -ForegroundColor Green

Write-Host "`n[2/5] Repo kontrol ediliyor: $user/$repo" -ForegroundColor Cyan
& $gh repo view "$user/$repo" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      Repo mevcut, push edilecek" -ForegroundColor Yellow
    $hasOrigin = (& $git remote) -match "origin"
    if (-not $hasOrigin) { & $git remote add origin "https://github.com/$user/$repo.git" }
    & $git push -u origin main
} else {
    Write-Host "      Repo olusturuluyor ve push ediliyor..." -ForegroundColor Yellow
    & $gh repo create $repo --public --source . --remote origin --push
}

if ($LASTEXITCODE -ne 0) { Write-Host "HATA: push basarisiz" -ForegroundColor Red; exit 1 }

Write-Host "`n[3/5] Actions derlemesi bekleniyor..." -ForegroundColor Cyan
$commit = (& $git rev-parse HEAD).Trim()
$runId = $null
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 6
    $runs = & $gh run list --commit $commit --limit 1 --json databaseId,status,conclusion,url 2>$null
    if ($runs) {
        $obj = $runs | ConvertFrom-Json
        if ($obj.Count -gt 0) { $runId = $obj[0].databaseId; break }
    }
}

if (-not $runId) {
    Write-Host "UYARI: Derleme kaydi bulunamadi. Actions sekmesini kontrol edin." -ForegroundColor Yellow
    exit 1
}
Write-Host "      Run ID: $runId" -ForegroundColor Green
& $gh run watch $runId --interval 15
if ($LASTEXITCODE -ne 0) {
    Write-Host "HATA: Derleme basarisiz. Loglar: gh run view $runId --log-failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/5] APK indiriliyor..." -ForegroundColor Cyan
$out = Join-Path $dir "apk-out"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
& $gh run download $runId -D $out

Write-Host "`n[5/5] APK masaustune kopyalaniyor..." -ForegroundColor Cyan
$apk = Get-ChildItem $out -Recurse -Filter "app-debug.apk" | Select-Object -First 1
if ($apk) {
    $dest = "C:\Users\PC\Desktop\Elizan.apk"
    Copy-Item $apk.FullName $dest -Force
    $mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "`nBASARILI! APK: $dest ($mb MB)" -ForegroundColor Green
} else {
    Write-Host "HATA: APK artifact icinde bulunamadi" -ForegroundColor Red
    exit 1
}
