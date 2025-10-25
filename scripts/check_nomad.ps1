# PowerShell smoke-test for the Nomad job
# - builds local image
# - purges previous job
# - submits nomad/hello_fixed.nomad
# - waits for an allocation to be running
# - curls the dynamic http address

Param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir\..\

Write-Host "[check_nomad.ps1] Building image devops-intern-final:latest..."
docker build -t devops-intern-final:latest .

Write-Host "[check_nomad.ps1] Stopping existing job (if any)..."
try { docker exec -i nomad nomad job stop -purge hello } catch { }

Write-Host "[check_nomad.ps1] Submitting job..."
docker exec -i nomad nomad job run - < nomad/hello_fixed.nomad

Write-Host "[check_nomad.ps1] Waiting for allocation to become running (timeout 60s)..."
$alloc = $null
for ($i=0; $i -lt 30; $i++) {
    $statusOutput = docker exec -i nomad nomad job status hello 2>$null
    $allocLine = $statusOutput -split "`n" | Where-Object { $_ -match '^[0-9a-f]{6,}' } | Select-Object -First 1
    if ($allocLine) { $alloc = ($allocLine -split '\s+')[0] }
    if ($alloc) {
        $allocStatus = docker exec -i nomad nomad alloc status -verbose $alloc 2>$null
        if ($allocStatus -match 'Client Status\s*=\s*running') { Write-Host "[check_nomad.ps1] Allocation $alloc is running"; break }
    }
    Write-Host "[check_nomad.ps1] waiting... $i"
    Start-Sleep -Seconds 2
}

if (-not $alloc) { Write-Error "No allocation found after timeout"; docker exec -i nomad nomad job status hello; exit 2 }

$allocStatus = docker exec -i nomad nomad alloc status -verbose $alloc
$httpLine = ($allocStatus -split "`n") | Where-Object { $_ -match '\*http' }
if ($httpLine -match '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:\d+)') { $addr = $matches[1] } else { Write-Error "Could not find http address in alloc status"; docker exec -i nomad nomad alloc status -verbose $alloc; exit 3 }

Write-Host "[check_nomad.ps1] Curling http://$addr/"
try {
    $r = curl.exe "http://$addr/" -UseBasicParsing -ErrorAction Stop
    Write-Host "[check_nomad.ps1] OK"
    exit 0
} catch {
    Write-Error "Request failed"
    exit 4
}
