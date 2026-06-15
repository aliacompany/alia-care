param (
    [int]$IntervalSeconds = 5
)

Write-Host "Starting Auto-Sync script. Checking for changes every $IntervalSeconds seconds..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray

while ($true) {
    # Add all changes
    git add .

    # Check if there are any staged changes
    $status = git status --porcelain
    if (![string]::IsNullOrWhiteSpace($status)) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "Changes detected, committing at $timestamp..." -ForegroundColor Yellow
        git commit -m "Auto-sync $timestamp" | Out-Null
        
        Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
        git push
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Warning: Push failed. Attempting to pull and rebase..." -ForegroundColor Red
        }
    }

    # Always attempt to pull to receive updates from other machines
    $pullOutput = git pull --rebase 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($pullOutput -match "(?i)fatal: unable to access|Connection was reset|Could not resolve host|Failed to connect|Connection timed out") {
            Write-Host "Network error during pull. Will retry next cycle..." -ForegroundColor Yellow
        } else {
            Write-Host "ERROR: Merge conflict or pull failed!" -ForegroundColor Red
            Write-Host $pullOutput
            Write-Host "Please resolve the conflict manually, commit, and then restart this script." -ForegroundColor Red
            break
        }
    } elseif ($pullOutput -match "Fast-forward|Updating") {
        Write-Host "Successfully pulled new changes from GitHub." -ForegroundColor Green
    }

    Start-Sleep -Seconds $IntervalSeconds
}
