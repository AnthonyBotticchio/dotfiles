#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Backup,
    [ValidateSet('git', 'vim', 'nvim')]
    [string[]]$Packages = @('git', 'vim', 'nvim')
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use install.sh on macOS/Linux or WSL.' }

$homePath = [Environment]::GetFolderPath('UserProfile')
$configRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
$appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
$links = @{
    git = @('git/.gitconfig', (Join-Path $homePath '.gitconfig'))
    vim = @('vim/.vimrc', (Join-Path $homePath '_vimrc'))
    nvim = @('nvim/.config/nvim', (Join-Path $configRoot $appName))
}
$pending = @()
foreach ($package in ($Packages | Select-Object -Unique)) {
    $source = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot $links[$package][0])).Path
    $destination = $links[$package][1]
    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $source) {
        Write-Host "Already linked: $destination"
        continue
    }
    if ($existing -and !$Backup) { throw "Already exists: $destination. Use -Backup to move existing configs aside." }
    $pending += [pscustomobject]@{ Source = $source; Destination = $destination; Existing = $existing }
}

# Check link permissions before moving any existing config. -WhatIf performs no writes.
if ($pending.Count -gt 0 -and !$WhatIfPreference) {
    $probe = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-link-' + [guid]::NewGuid())
    try { New-Item -ItemType SymbolicLink -Path $probe -Target $PSScriptRoot | Out-Null }
    catch { throw 'Symbolic links require Windows Developer Mode or an elevated PowerShell. No configs were moved.' }
    finally { if (Test-Path -LiteralPath $probe) { Remove-Item -LiteralPath $probe -Force } }
}
$backupRoot = Join-Path $homePath ('.dotfiles-backup.' + [guid]::NewGuid())
foreach ($link in $pending) {
    if ($PSCmdlet.ShouldProcess($link.Destination, "Link to $($link.Source) (backup existing: $Backup)")) {
        $saved = $null
        if ($link.Existing) {
            New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
            $saved = Join-Path $backupRoot ([IO.Path]::GetFileName($link.Destination))
            Move-Item -LiteralPath $link.Destination -Destination $saved
            Write-Host "Backup: $saved"
        }
        try {
            New-Item -ItemType Directory -Path (Split-Path $link.Destination -Parent) -Force | Out-Null
            New-Item -ItemType SymbolicLink -Path $link.Destination -Target $link.Source | Out-Null
        }
        catch {
            if ($saved) { Move-Item -LiteralPath $saved -Destination $link.Destination }
            throw
        }
    }
}
