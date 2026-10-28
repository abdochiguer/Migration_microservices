param(
    [string]$BaseUrl = "http://localhost:8080",
    [int]$DelayMs = 250,
    [switch]$Canary
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Simulateur de Trafic Local (Zero-Downtime Verification)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Cible       : $BaseUrl" -ForegroundColor Yellow
Write-Host "Cadence     : $(1000 / $DelayMs) req/sec" -ForegroundColor Yellow
Write-Host "Mode Canary : $(if ($Canary) { 'ACTIVÉ (X-Canary: true)' } else { 'DÉSACTIVÉ (Trafic normal)' })" -ForegroundColor Yellow
Write-Host "Appuyez sur Ctrl+C pour arrêter le test à tout moment.`n" -ForegroundColor Gray

$headers = @{
    "Accept" = "application/json"
}
if ($Canary) {
    $headers["X-Canary"] = "true"
}

$totalRequests = 0
$success200 = 0
$errors = 0
$latencies = [System.Collections.Generic.List[double]]::new()

$stopwatch = [System.Diagnostics.Stopwatch]::new()

while ($true) {
    $totalRequests++
    $stopwatch.Restart()
    $statusCode = 0
    $isSuccess = $false

    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/vets" -Headers $headers -TimeoutSec 5 -UseBasicParsing
        $statusCode = $response.StatusCode
        if ($statusCode -eq 200) {
            $success200++
            $isSuccess = $true
        } else {
            $errors++
        }
    } catch [System.Net.WebException] {
        $errors++
        if ($_.Response) {
            $statusCode = [int]$_.Response.StatusCode
        } else {
            $statusCode = 0 # Timeout ou connexion refusée
        }
    } catch {
        $errors++
        $statusCode = 500
    }
    $stopwatch.Stop()
    $latencyMs = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
    $latencies.Add($latencyMs)
    if ($latencies.Count -gt 50) { $latencies.RemoveAt(0) }

    $avgLatency = [math]::Round(($latencies | Measure-Object -Average).Average, 1)

    $statusColor = if ($isSuccess) { "Green" } else { "Red" }
    $errorRate = [math]::Round(($errors / $totalRequests) * 100, 2)

    Write-Host -NoNewline "`r[Req #$totalRequests] Status: " 
    Write-Host -NoNewline "$statusCode" -ForegroundColor $statusColor
    Write-Host -NoNewline " | Latence: "
    Write-Host -NoNewline "$($latencyMs)ms" -ForegroundColor White
    Write-Host -NoNewline " (Moy: $($avgLatency)ms) | 200 OK: "
    Write-Host -NoNewline "$success200" -ForegroundColor Green
    Write-Host -NoNewline " | Erreurs: "
    Write-Host -NoNewline "$errors ($errorRate%)" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Gray" })

    Start-Sleep -Milliseconds $DelayMs
}
