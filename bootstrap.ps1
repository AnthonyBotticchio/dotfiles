#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Backup)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use bootstrap.sh on macOS/Linux or WSL.' }
if (!(Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install App Installer (WinGet) first.' }

$packages = @('vim.vim', 'Neovim.Neovim', 'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd', 'Kitware.CMake', 'OpenJS.NodeJS.LTS', 'Python.Python.3.13', 'LLVM.LLVM')
foreach ($package in $packages) {
    if ($PSCmdlet.ShouldProcess($package, 'Install with WinGet')) {
        & winget list --id $package --exact --source winget --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) { continue }
        & winget install --id $package --exact --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw "WinGet failed for $package (exit $LASTEXITCODE)." }
    }
}
if (!$WhatIfPreference) {
    # Include executable paths added by the installers in this process.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    if (!(Get-Command nvim -ErrorAction SilentlyContinue)) { throw 'Open a new PowerShell and rerun; Neovim is not yet on PATH.' }
    & nvim --headless -u NONE -i NONE '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)'
    if ($LASTEXITCODE -ne 0) { throw 'Neovim 0.12+ is required. Upgrade Neovim, then run install.ps1 -Backup.' }
    if (!(Get-Command tree-sitter -ErrorAction SilentlyContinue)) {
        & npm.cmd install --global tree-sitter-cli
        if ($LASTEXITCODE -ne 0) { throw 'tree-sitter-cli installation failed.' }
    }
}
& "$PSScriptRoot/install.ps1" -Backup:$Backup -WhatIf:$WhatIfPreference
