#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Backup)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Use bootstrap.sh on macOS/Linux or WSL.' }
if (!(Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install App Installer (WinGet) first.' }

# DEVCOM.LuaJIT bundles LuaJIT + LuaRocks (Neovim's Lua is LuaJIT / Lua 5.1 compatible).
$packages = @('vim.vim', 'Neovim.Neovim', 'BurntSushi.ripgrep.MSVC',
    'sharkdp.fd', 'Kitware.CMake', 'OpenJS.NodeJS.LTS', 'Python.Python.3.13', 'LLVM.LLVM',
    'tree-sitter.tree-sitter-cli', 'DEVCOM.LuaJIT')
foreach ($package in $packages) {
    if ($PSCmdlet.ShouldProcess($package, 'Install with WinGet')) {
        & winget list --id $package --exact --source winget --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) { continue }
        & winget install --id $package --exact --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw "WinGet failed for $package (exit $LASTEXITCODE)." }
    }
}

# Get-Command also finds broken shims, so actually run the tool to prove it works.
function Test-Tool([string]$Name) {
    try { & $Name --version *> $null; return ($LASTEXITCODE -eq 0) }
    catch { return $false }
}

if (!$WhatIfPreference) {
    # Include executable paths added by the installers in this process.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    if (!(Get-Command nvim -ErrorAction SilentlyContinue)) { throw 'Open a new PowerShell and rerun; Neovim is not yet on PATH.' }
    & nvim --headless -u NONE -i NONE '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)'
    if ($LASTEXITCODE -ne 0) { throw 'Neovim 0.12+ is required. Upgrade Neovim, then run install.ps1 -Backup.' }

    if (!(Test-Tool 'tree-sitter')) {
        # A leftover npm tree-sitter-cli (its binary download is blocked by default) can
        # shadow the winget one on PATH. Remove it and test again.
        if (Get-Command npm.cmd -ErrorAction SilentlyContinue) {
            & npm.cmd uninstall --global tree-sitter-cli *> $null
        }
        if (!(Test-Tool 'tree-sitter')) {
            throw 'tree-sitter does not run. Open a new PowerShell and rerun; check "Get-Command tree-sitter -All".'
        }
    }
    # LuaRocks is optional (no plugin requires it yet), so warn instead of aborting.
    if (!(Test-Tool 'luarocks')) {
        Write-Warning 'luarocks is not on PATH yet. Open a new PowerShell; if it still fails, lazy.nvim can fall back to hererocks.'
    }
}
& "$PSScriptRoot/install.ps1" -Backup:$Backup -WhatIf:$WhatIfPreference
