@echo off
title Synapse Grid Installer
echo Starting Synapse Grid Installer...
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0installer\setup_gui.ps1"
