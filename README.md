# Install

Requires Git and Homebrew (macOS), apt (Ubuntu), or dnf (other supported Linux distributions).

```sh
git clone https://github.com/AnthonyBotticchio/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh --backup
zsh
```

Installs dependencies and links configs, backing up existing files. On macOS, add `--minimal` to skip Kitty and its font.

## Windows

**WSL (Ubuntu):** run the commands above inside your Linux home.

**Native Windows:** requires Git, PowerShell 5.1+, and WinGet. Enable Developer Mode for symlinks with PowerShell 7; PowerShell 5.1 may require an elevated session.

```powershell
git clone https://github.com/AnthonyBotticchio/dotfiles.git "$HOME/git/dotfiles"
cd "$HOME/git/dotfiles"
.\bootstrap.ps1 -WhatIf
.\bootstrap.ps1 -Backup
```

Bootstrap installs Vim, Neovim, ripgrep, fd, CMake, Node.js, Python, LLVM, and tree-sitter CLI as needed. Neovim requires 0.12+; if WinGet installs an older version, upgrade it before running `.\install.ps1 -Backup`. Restart your terminal to refresh PATH, then open `nvim` to install plugins. Run `:checkhealth` to check dependencies and select a Nerd Font in your terminal for icons.

To link configs without installing software:

```powershell
.\install.ps1 -WhatIf
.\install.ps1 -Backup
# Optional subset:
.\install.ps1 -Packages git,vim -Backup
```

Note: zsh, htop, and Kitty configs are for macOS/Linux or WSL.
