$root = "C:\Users\PC\Desktop\Ai\elizan-pwa"
$port = 8123
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Output "Serving $root on http://localhost:$port/"
while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.LocalPath
        if ($path -eq "/") { $path = "/index.html" }
        $rel = $path.TrimStart("/") -replace "/", "\"
        $file = Join-Path $root $rel
        if (-not (Test-Path $file -PathType Leaf)) {
            $ctx.Response.StatusCode = 404
            $ctx.Response.Close()
            continue
        }
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $mime = switch ($ext) {
            ".html" { "text/html; charset=utf-8" }
            ".js" { "text/javascript; charset=utf-8" }
            ".webmanifest" { "application/manifest+json; charset=utf-8" }
            ".json" { "application/json; charset=utf-8" }
            ".png" { "image/png" }
            ".svg" { "image/svg+xml" }
            ".css" { "text/css; charset=utf-8" }
            default { "application/octet-stream" }
        }
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $ctx.Response.ContentType = $mime
        $ctx.Response.Headers.Add("Cache-Control", "no-store")
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        $ctx.Response.Close()
    } catch { }
}
