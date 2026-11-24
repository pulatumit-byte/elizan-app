# Elizan — GitHub Desktop oturumunu kullanarak repo olustur, push et, derle, APK indir
$ErrorActionPreference = "Continue"

# ---------- 1) Token oku ----------
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ElizanCredX {
    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);
    [DllImport("advapi32.dll")] public static extern void CredFree(IntPtr cred);
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CREDENTIAL { public int Flags; public int Type; public string TargetName; public string Comment; public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten; public int CredentialBlobSize; public IntPtr CredentialBlob; public int Persist; public int AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName; }
}
"@

function Get-ElizanToken {
    $ptr = [IntPtr]::Zero
    if (-not [ElizanCredX]::CredRead("GitHub - https://api.github.com/pulatumit-byte", 1, 0, [ref]$ptr)) { return $null }
    $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][ElizanCredX+CREDENTIAL])
    $n = [int]$c.CredentialBlobSize
    $b = New-Object byte[] $n
    [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $b, 0, $n)
    [ElizanCredX]::CredFree($ptr)
    $raw = [System.Text.Encoding]::UTF8.GetString($b)
    $json = $raw.Substring("github-desktop-oauth:".Length)
    return ($json | ConvertFrom-Json).credential.accessToken
}

$token = Get-ElizanToken
if (-not $token) { Write-Host "HATA: token okunamadi" -ForegroundColor Red; exit 1 }
$env:GH_TOKEN = $token
$env:GITHUB_TOKEN = $token

$git     = "$env:LOCALAPPDATA\GitHubDesktop\app-3.7.0\resources\app\git\cmd\git.exe"
$gh      = "C:\Program Files\GitHub CLI\gh.exe"
$dir     = "C:\Users\PC\Desktop\Ai\elizan-android"
$owner   = "pulatumit-byte"
$repoName= "elizan-app"
$api     = "https://api.github.com"
$headers = @{ Authorization = "token $token"; "User-Agent" = "elizan"; Accept = "application/vnd.github+json" }

Write-Host "`n[1/6] Token alindi (hesap: $owner)" -ForegroundColor Green

# ---------- 2) Repo olustur ----------
Write-Host "`n[2/6] Repo: $owner/$repoName" -ForegroundColor Cyan
$exists = $true
try { Invoke-RestMethod -Uri "$api/repos/$owner/$repoName" -Headers $headers -ErrorAction Stop | Out-Null }
catch { $exists = $false }

if ($exists) {
    Write-Host "      Repo zaten var, kullanilacak" -ForegroundColor Yellow
} else {
    $body = @{ name = $repoName; description = "Elizan - Temizlik ve Apartman Yonetimi (Android/APK)"; private = $false; auto_init = $false } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$api/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Host "      Repo olusturuldu" -ForegroundColor Green
    } catch {
        Write-Host ("      HATA: repo olusturulamadi -> " + $_.Exception.Message) -ForegroundColor Red
        exit 1
    }
}

# ---------- 3) Push ----------
Write-Host "`n[3/6] Dosyalar push ediliyor..." -ForegroundColor Cyan
Set-Location $dir
& $git remote remove origin 2>$null | Out-Null
& $git remote add origin "https://github.com/$owner/$repoName.git"
& $git branch -M main 2>$null | Out-Null
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("x-access-token:$token"))
$pushOut = & $git -c "http.extraheader=AUTHORIZATION: basic $b64" push -u origin main --force 2>&1 | Out-String
$pushOk = ($LASTEXITCODE -eq 0)
Write-Host ($pushOut.Trim() -replace [regex]::Escape($token), "***") -ForegroundColor Gray

if (-not $pushOk) {
    Write-Host "      HATA: push basarisiz" -ForegroundColor Red
    exit 1
}
$sha = (& $git rev-parse HEAD).Trim()
Write-Host "      Push tamam. Commit: $($sha.Substring(0,7))" -ForegroundColor Green

# ---------- 4) Derlemeyi bul ----------
Write-Host "`n[4/6] Actions derlemesi bekleniyor..." -ForegroundColor Cyan
$run = $null
for ($i = 1; $i -le 25; $i++) {
    Start-Sleep -Seconds 6
    try {
        $runs = Invoke-RestMethod -Uri "$api/repos/$owner/$repoName/actions/runs?per_page=10" -Headers $headers -ErrorAction Stop
        $run = $runs.workflow_runs | Where-Object { $_.head_sha -eq $sha } | Select-Object -First 1
    } catch {
        Write-Host ("      (" + $_.Exception.Message + ")") -ForegroundColor DarkGray
    }
    if ($run) { break }
    Write-Host "      ... aranıyor ($i)" -ForegroundColor DarkGray
}

if (-not $run) {
    Write-Host "      UYARI: Derleme kaydi bulunamadi. https://github.com/$owner/$repoName/actions adresini kontrol edin." -ForegroundColor Yellow
    Write-Host "      (Workflow dosyasi .github/workflows/android.yml dogru yolda mi?)" -ForegroundColor Yellow
    exit 2
}

Write-Host "      Derleme bulundu: #$($run.run_number)  [durum: $($run.status)]" -ForegroundColor Green
Write-Host "      $($run.html_url)" -ForegroundColor Gray

# ---------- 5) Bitis bekle ----------
$lastStatus = ""
for ($i = 1; $i -le 120; $i++) {
    try {
        $cur = Invoke-RestMethod -Uri "$api/repos/$owner/$repoName/actions/runs/$($run.id)" -Headers $headers -ErrorAction Stop
    } catch { Start-Sleep -Seconds 10; continue }

    $st = "$($cur.status)/$($cur.conclusion)"
    if ($st -ne $lastStatus) {
        Write-Host ("      [{0}] durum: {1} {2}" -f (Get-Date -Format "HH:mm:ss"), $cur.status, $cur.conclusion) -ForegroundColor DarkCyan
        $lastStatus = $st
    }
    if ($cur.status -eq "completed") { break }
    Start-Sleep -Seconds 10
}

if ($cur.conclusion -ne "success") {
    Write-Host "`n      HATA: Derleme basarisiz (sonuc: $($cur.conclusion))" -ForegroundColor Red
    Write-Host "      Log: https://github.com/$owner/$repoName/actions/runs/$($run.id)" -ForegroundColor Yellow
    exit 3
}

Write-Host "`n      Derleme BASARILI" -ForegroundColor Green

# ---------- 6) APK indir ----------
Write-Host "`n[5/6] APK indiriliyor..." -ForegroundColor Cyan
$arts = Invoke-RestMethod -Uri "$api/repos/$owner/$repoName/actions/runs/$($run.id)/artifacts" -Headers $headers
if ($arts.total_count -lt 1) { Write-Host "      HATA: artifact yok" -ForegroundColor Red; exit 4 }
$art = $arts.artifacts[0]
Write-Host ("      Artifact: {0} ({1:N0} KB)" -f $art.name, ($art.size_in_bytes / 1KB)) -ForegroundColor Green

$tmpZip = "C:\Users\PC\AppData\Local\Temp\opencode\elizan-artifact.zip"
if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }
$outDir = "C:\Users\PC\AppData\Local\Temp\opencode\elizan-apk-out"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# gh CLI ile indir (redirect/yetki sorunlarini kendisi cozer)
& $gh run download $run.id --repo "$owner/$repoName" --dir $outDir 2>&1 | Out-String | Write-Host -ForegroundColor Gray
$apk = Get-ChildItem $outDir -Recurse -Filter "*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $apk) {
    Write-Host "      gh ile indirilemedi, API deneniyor..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "$api/repos/$owner/$repoName/actions/artifacts/$($art.id)/zip" -Headers $headers -OutFile $tmpZip -MaximumRedirection 5 -ErrorAction Stop
        Expand-Archive -Path $tmpZip -DestinationPath $outDir -Force
        $apk = Get-ChildItem $outDir -Recurse -Filter "*.apk" | Select-Object -First 1
    } catch {
        Write-Host ("      HATA: indirilemedi -> " + $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host "`n[6/6] APK masaustune kopyalaniyor..." -ForegroundColor Cyan
if ($apk) {
    $dest = "C:\Users\PC\Desktop\Elizan.apk"
    Copy-Item $apk.FullName $dest -Force
    $mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "`n===== BASARILI =====" -ForegroundColor Green
    Write-Host "APK: $dest  ($mb MB)" -ForegroundColor Green
    Write-Host "Repo: https://github.com/$owner/$repoName" -ForegroundColor Green
} else {
    Write-Host "      HATA: APK bulunamadi. Artifact'i elle indirin: $($run.html_url)" -ForegroundColor Red
    exit 5
}
