# build-desktop.ps1
# This script compiles the Next.js app in standalone mode and packages it with Node.js.

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

Set-Location $projectRoot

# 1. Clean previous build folders
Write-Host "Cleaning old build folders..."
$distDir = Join-Path $projectRoot "dist"
if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
New-Item -ItemType Directory -Path $distDir | Out-Null

# 2. Build the application
Write-Host "Building Next.js application..."
cmd /c "npm run build"

# 3. Setup SQLite Database for the production package
Write-Host "Preparing production SQLite database..."
cmd /c "npx prisma db push --accept-data-loss"

# 4. Copy Next.js Standalone build artifacts
Write-Host "Packaging standalone server..."
$standaloneDir = Join-Path $projectRoot ".next\standalone"

if (-not (Test-Path $standaloneDir)) {
    Write-Error "Standalone build output not found! Ensure 'output: 'standalone'' is set in next.config.ts."
}

# Copy standalone folder contents to dist/
Copy-Item -Path "$standaloneDir\*" -Destination $distDir -Recurse -Force

# Copy static assets (standalone Next.js doesn't copy public/ and static/ folders automatically)
Write-Host "Copying static assets..."
if (Test-Path "public") {
    Copy-Item -Path "public" -Destination (Join-Path $distDir "public") -Recurse -Force
}
if (Test-Path ".next\static") {
    Copy-Item -Path ".next\static" -Destination (Join-Path $distDir ".next\static") -Recurse -Force
}

# Copy prisma schema and dev.db to dist/
Write-Host "Copying database files..."
New-Item -ItemType Directory -Path (Join-Path $distDir "prisma") | Out-Null
if (Test-Path "prisma\schema.prisma") {
    Copy-Item -Path "prisma\schema.prisma" -Destination (Join-Path $distDir "prisma\schema.prisma") -Force
}
if (Test-Path "prisma\dev.db") {
    Copy-Item -Path "prisma\dev.db" -Destination (Join-Path $distDir "prisma\dev.db") -Force
}

# Create production .env file in dist/
Write-Host "Creating production environment configurations..."
$envContent = @"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="synapse-grid-default-desktop-secret-key-12345"
"@
Set-Content -Path (Join-Path $distDir ".env") -Value $envContent

# 5. Bundle Node.js Portable Binary
Write-Host "Bundling Node.js executable..."
$nodePath = Get-Command "node" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $nodePath) {
    Write-Error "Node.exe was not found on your system path. Please install Node.js to package the app."
}
Copy-Item -Path $nodePath -Destination (Join-Path $distDir "node.exe") -Force

# 6. Create Launch BAT File
Write-Host "Creating Launch script..."
$batContent = @"
@echo off
title Synapse Grid
echo Starting Synapse Grid server...
start /b "" "%~dp0node.exe" "%~dp0server.js"
timeout /t 3 > nul
echo Opening browser...
start "" "http://localhost:3000"
"@
$batPath = Join-Path $distDir "Launch_Synapse_Grid.bat"
Set-Content -Path $batPath -Value $batContent

Write-Host "`nSuccessfully packaged self-contained app into the 'dist/' folder!" -ForegroundColor Green
Write-Host "You can now zip the 'dist' folder and distribute it to any Windows user."
Write-Host "Users can run the application by double-clicking 'Launch_Synapse_Grid.bat' directly."
