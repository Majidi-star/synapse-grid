Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# Capture script path outside of event handlers
$global:projectPath = Split-Path -Parent $PSScriptRoot

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Synapse Grid Installer"
$form.Size = New-Object System.Drawing.Size(500, 350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#18181b") # zinc-900

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Install & Launch Synapse Grid"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($titleLabel)

# Description
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "This setup will automatically configure Node.js, install dependencies, prepare the database, and launch the application."
$descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$descLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a1a1aa") # zinc-400
$descLabel.Size = New-Object System.Drawing.Size(440, 50)
$descLabel.Location = New-Object System.Drawing.Point(20, 60)
$form.Controls.Add($descLabel)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to install."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$statusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d4d4d8") # zinc-300
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(20, 160)
$form.Controls.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(440, 20)
$progressBar.Location = New-Object System.Drawing.Point(20, 185)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Install Button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Start Setup"
$button.Size = New-Object System.Drawing.Size(120, 40)
$button.Location = New-Object System.Drawing.Point(340, 240)
$button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2563eb") # blue-600
$button.ForeColor = [System.Drawing.Color]::White
$button.FlatStyle = "Flat"
$button.FlatAppearance.BorderSize = 0
$button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($button)

# Close Button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Cancel"
$closeButton.Size = New-Object System.Drawing.Size(100, 40)
$closeButton.Location = New-Object System.Drawing.Point(230, 240)
$closeButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3f3f46") # zinc-700
$closeButton.ForeColor = [System.Drawing.Color]::White
$closeButton.FlatStyle = "Flat"
$closeButton.FlatAppearance.BorderSize = 0
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

function Update-Status($msg, $val) {
    if ($val -gt 0 -and $val -lt 100) {
        $statusLabel.Text = "[$val%] $msg"
    } else {
        $statusLabel.Text = $msg
    }
    $progressBar.Value = $val
    [System.Windows.Forms.Application]::DoEvents()
}

$button.Add_Click({
    $button.Enabled = $false
    $closeButton.Enabled = $false
    $progressBar.Style = "Marquee"
    
    try {
        # 0. Check Internet Connectivity (Try Microsoft and Cloudflare as backups)
        Update-Status "Checking internet connection..." 5
        $hasInternet = $false
        foreach ($url in @("http://www.microsoft.com", "http://www.cloudflare.com")) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    $hasInternet = $true
                    break
                }
            } catch {}
        }

        # 1. Check Node.js
        Update-Status "Checking for Node.js..." 10
        $nodeExists = Get-Command "node" -ErrorAction SilentlyContinue
        
        if (-not $nodeExists) {
            if (-not $hasInternet) {
                Update-Status "Error: No internet connection! Please connect to download Node.js (~30 MB)." 0
                $progressBar.Style = "Continuous"
                $button.Enabled = $true
                $closeButton.Enabled = $true
                return
            }

            $progressBar.Style = "Continuous"
            $msiPath = "$env:TEMP\node-v20.12.2-x64.msi"
            
            # Robust, synchronous single-threaded stream downloader with real-time UI updates
            $request = [System.Net.HttpWebRequest]::Create("https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi")
            $request.Timeout = 15000
            $response = $request.GetResponse()
            $totalLength = $response.ContentLength
            $responseStream = $response.GetResponseStream()
            $targetStream = [System.IO.File]::Create($msiPath)
            
            $buffer = New-Object byte[] 65536 # 64KB chunk
            $downloaded = 0
            $count = $responseStream.Read($buffer, 0, $buffer.Length)
            
            while ($count -gt 0) {
                $targetStream.Write($buffer, 0, $count)
                $downloaded += $count
                
                $percent = [math]::Round(($downloaded / $totalLength) * 100)
                $scaledProgress = 10 + [math]::Round($percent * 0.3)
                Update-Status "Downloading Node.js..." $scaledProgress
                
                [System.Windows.Forms.Application]::DoEvents()
                $count = $responseStream.Read($buffer, 0, $buffer.Length)
            }
            
            $targetStream.Close()
            $responseStream.Close()
            $response.Close()
            
            Update-Status "Installing Node.js (Please wait)..." 40
            $progressBar.Style = "Marquee"
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msiPath`" /quiet /norestart"
            
            # Refresh path environment variables, expanding system directories correctly
            $rawPath = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $env:Path = [System.Environment]::ExpandEnvironmentVariables($rawPath)
        }
        
        # 2. Install NPM packages
        Set-Location $global:projectPath
        # Check if node_modules exists AND contains the 'next' core dependency
        if (-not (Test-Path "node_modules") -or -not (Test-Path "node_modules\next")) {
            if (-not $hasInternet) {
                Update-Status "Error: No internet! Connect to download dependencies (~100 MB)." 0
                $progressBar.Style = "Continuous"
                $button.Enabled = $true
                $closeButton.Enabled = $true
                return
            }

            Update-Status "Downloading app dependencies (~100 MB)... this may take a few minutes." 50
            $process = Start-Process cmd.exe -ArgumentList "/c npm install" -WorkingDirectory $global:projectPath -WindowStyle Hidden -PassThru
            while (-not $process.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
            
            if ($process.ExitCode -ne 0) {
                Update-Status "Error: npm install failed with exit code $($process.ExitCode). Please check your internet/VPN." 0
                $progressBar.Style = "Continuous"
                $button.Enabled = $true
                $closeButton.Enabled = $true
                return
            }
        } else {
            Update-Status "Dependencies found. Skipping install..." 50
            Start-Sleep -Seconds 1
        }
        
        # 3. Setup SQLite Database
        if (-not (Test-Path "prisma\dev.db")) {
            Update-Status "Initializing local SQLite database... (This can take a minute)" 70
            
            # Pre-create the SQLite file to bypass the "Do you want to continue? [y/N]" prompt
            if (-not (Test-Path "prisma")) { New-Item -Path "prisma" -ItemType Directory -Force | Out-Null }
            New-Item -Path "prisma\dev.db" -ItemType File -Force | Out-Null

            $process2 = Start-Process cmd.exe -ArgumentList "/c echo y | npx --yes prisma db push --accept-data-loss" -WorkingDirectory $global:projectPath -WindowStyle Hidden -PassThru
            while (-not $process2.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
            
            if ($process2.ExitCode -ne 0) {
                Update-Status "Error: SQLite Database initialization failed (exit code $($process2.ExitCode))." 0
                $progressBar.Style = "Continuous"
                $button.Enabled = $true
                $closeButton.Enabled = $true
                return
            }
        } else {
            Update-Status "Local database found. Skipping initialization..." 70
            Start-Sleep -Seconds 1
        }

        # Check if local Database Client is generated (must be compiled for the target OS)
        if (-not (Test-Path "node_modules\.prisma\client")) {
            Update-Status "Configuring local database client..." 80
            $process3 = Start-Process cmd.exe -ArgumentList "/c npx --yes prisma generate" -WorkingDirectory $global:projectPath -WindowStyle Hidden -PassThru
            while (-not $process3.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
        }
        
        # 4. Start Server
        # Check if port 3000 is already active (means app is running)
        $alreadyRunning = $false
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($response.StatusCode -eq 200) { $alreadyRunning = $true }
        } catch {}

        if ($alreadyRunning) {
            Update-Status "Synapse Grid is already running! Opening browser..." 100
            Start-Process "http://localhost:3000"
            Start-Sleep -Seconds 2
            $form.Close()
            return
        }

        Update-Status "Starting Synapse Grid Server..." 85
        $logPath = Join-Path $global:projectPath "server_error.log"
        if (Test-Path $logPath) { Remove-Item $logPath -Force -ErrorAction SilentlyContinue }
        
        $serverProc = Start-Process cmd.exe -ArgumentList "/c npm run dev > `"$logPath`" 2>&1" -WorkingDirectory $global:projectPath -WindowStyle Hidden -PassThru
        
        # 5. Wait for localhost:3000
        Update-Status "Waiting for server to spin up..." 90
        $serverUp = $false
        $attempts = 0
        while (-not $serverUp -and $attempts -lt 30 -and (-not $serverProc.HasExited)) {
            Start-Sleep -Seconds 1
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
                if ($response.StatusCode -eq 200) { $serverUp = $true }
            } catch {
                # Ignore
            }
            $attempts++
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        if (-not $serverUp) {
            $errorMsg = "Server failed to start."
            if (Test-Path $logPath) {
                $logContent = Get-Content $logPath -Raw
                if (-not [string]::IsNullOrWhiteSpace($logContent)) {
                    # Take the first 150 chars of error log to display on the installer label
                    $cleanErr = $logContent -replace '\r?\n', ' '
                    if ($cleanErr.Length -gt 150) { $cleanErr = $cleanErr.Substring(0, 150) + "..." }
                    $errorMsg = "Error: $cleanErr"
                }
            }
            Update-Status $errorMsg 0
            $progressBar.Style = "Continuous"
            $button.Enabled = $true
            $closeButton.Enabled = $true
            return
        }
        
        Update-Status "Setup Complete! Opening browser..." 100
        $progressBar.Style = "Continuous"
        Start-Process "http://localhost:3000"
        
        Start-Sleep -Seconds 2
        $form.Close()
        
    } catch {
        Update-Status "Error: $_" 0
        $progressBar.Style = "Continuous"
        $button.Enabled = $true
        $closeButton.Enabled = $true
    }
})

$form.ShowDialog() | Out-Null
