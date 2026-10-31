param(
    [int]$Port = 8080
)

$rootDir = $PSScriptRoot
if (-not $rootDir) {
    $rootDir = Get-Location
}

$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host "=========================================================="
    Write-Host " Water Usage & Bill Calculator Local Server"
    Write-Host " Running at: $prefix"
    Write-Host " Press Ctrl+C in this terminal to stop the server."
    Write-Host "=========================================================="
} catch {
    Write-Error "Could not start server on $prefix. Error: $_"
    exit 1
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".txt"  = "text/plain; charset=utf-8"
    ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
    } catch {
        break
    }

    $request = $context.Request
    $response = $context.Response

    $rawPath = $request.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($rawPath)) {
        $rawPath = "index.html"
    }

    # Handle CGI endpoint
    if ($rawPath -match "calculate\.(cgi|exe)$") {
        $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
        $body = $reader.ReadToEnd()
        $reader.Close()

        $cgiExe = Join-Path $rootDir "cgi-bin\calculate.exe"
        if (-not (Test-Path $cgiExe)) {
            $cgiExe = Join-Path $rootDir "cgi-bin\calculate.cgi"
        }

        if (Test-Path $cgiExe) {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $cgiExe
            $psi.UseShellExecute = $false
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.CreateNoWindow = $true

            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $psi.EnvironmentVariables["CONTENT_LENGTH"] = "$($bodyBytes.Length)"
            $psi.EnvironmentVariables["REQUEST_METHOD"] = "POST"
            $psi.EnvironmentVariables["CONTENT_TYPE"] = "application/x-www-form-urlencoded"

            $proc = [System.Diagnostics.Process]::Start($psi)
            $proc.StandardInput.BaseStream.Write($bodyBytes, 0, $bodyBytes.Length)
            $proc.StandardInput.Close()

            $output = $proc.StandardOutput.ReadToEnd()
            $proc.WaitForExit()

            # Separate headers and body - extract JSON payload cleanly
            $cgiBody = $output.Trim()
            if ($output -match '(?s)\{.*\}') {
                $cgiBody = $matches[0]
            } elseif ($output.IndexOf("`r`n`r`n") -ge 0) {
                $cgiBody = $output.Substring($output.IndexOf("`r`n`r`n") + 4).Trim()
            } elseif ($output.IndexOf("`n`n") -ge 0) {
                $cgiBody = $output.Substring($output.IndexOf("`n`n") + 2).Trim()
            }

            $respBytes = [System.Text.Encoding]::UTF8.GetBytes($cgiBody)
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $respBytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($respBytes, 0, $respBytes.Length)
            $response.Close()
            continue
        } else {
            $response.StatusCode = 500
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"CGI executable not found in cgi-bin."}')
            $response.ContentType = "application/json; charset=utf-8"
            $response.ContentLength64 = $errBytes.Length
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            $response.Close()
            continue
        }
    }

    # Static file handling
    $filePath = Join-Path $rootDir $rawPath
    if (Test-Path $filePath -PathType Leaf) {
        $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
        if ($mimeTypes.ContainsKey($ext)) {
            $response.ContentType = $mimeTypes[$ext]
        } else {
            $response.ContentType = "application/octet-stream"
        }

        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
        $response.ContentLength64 = $fileBytes.Length
        $response.StatusCode = 200
        $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
        $response.Close()
    } else {
        $response.StatusCode = 404
        $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
        $response.OutputStream.Write($msg, 0, $msg.Length)
        $response.Close()
    }
}

