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
    $statusLabel.Text = $msg
    $progressBar.Value = $val
    [System.Windows.Forms.Application]::DoEvents()
}

$button.Add_Click({
    $button.Enabled = $false
    $closeButton.Enabled = $false
    $progressBar.Style = "Marquee"
    
    try {
        # 1. Check Node.js
        Update-Status "Checking for Node.js..." 10
        $nodeExists = Get-Command "node" -ErrorAction SilentlyContinue
        
        if (-not $nodeExists) {
            Update-Status "Downloading Node.js (this may take a minute)..." 20
            $msiPath = "$env:TEMP\node-v20.12.2-x64.msi"
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v20.12.2/node-v20.12.2-x64.msi" -OutFile $msiPath
            
            Update-Status "Installing Node.js..." 30
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msiPath`" /quiet /norestart"
            
            # Refresh path
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
        
        # 2. Install NPM packages
        Update-Status "Installing NPM dependencies (npm install)..." 50
        Set-Location $global:projectPath
        
        $process = Start-Process cmd.exe -ArgumentList "/c npm install" -WindowStyle Hidden -PassThru
        while (-not $process.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        
        # 3. Setup Prisma DB
        Update-Status "Initializing Database (Prisma)..." 70
        $process2 = Start-Process cmd.exe -ArgumentList "/c npx prisma db push" -WindowStyle Hidden -PassThru
        while (-not $process2.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
        
        # 4. Start Server
        Update-Status "Starting Synapse Grid Server..." 85
        Start-Process cmd.exe -ArgumentList "/c npm run dev" -WindowStyle Hidden
        
        # 5. Wait for localhost:3000
        Update-Status "Waiting for server to spin up..." 90
        $serverUp = $false
        $attempts = 0
        while (-not $serverUp -and $attempts -lt 30) {
            Start-Sleep -Seconds 1
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -ErrorAction Stop
                if ($response.StatusCode -eq 200) { $serverUp = $true }
            } catch {
                # Ignore
            }
            $attempts++
            [System.Windows.Forms.Application]::DoEvents()
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
