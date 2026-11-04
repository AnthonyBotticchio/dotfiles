# Install

Requires Git and Homebrew (macOS), apt (Ubuntu), or dnf (other supported Linux distributions).

```sh
git clone https://github.com/AnthonyBotticchio/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh --backup
```

Installs dependencies and links configs, backing up existing files. On macOS, add `--minimal` to skip Kitty and its font.

## Zsh

```sh
./install-zsh.sh
zsh
```

Installs missing Zsh/Git, Oh My Zsh, and Powerlevel10k, then backs up and links `.zshrc` and `.p10k.zsh`. Reuses existing installations, including Zsh on CAC. Requires administrator access only when Zsh or Git must be installed. Keep machine-specific settings in `~/.zshrc.local`.

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

Kitty is macOS-only.

## Git identity

Git aliases such as `git gone` are shared. Set your identity in the included local file on each machine (these commands also work in PowerShell):

```sh
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.com"
```

The linked `~/.gitconfig` belongs to this repo, so `git config --global` would write machine-specific settings into the shared file. Keep signing and credential-helper settings in `~/.gitconfig.local` too.

## What stays local

Keep `~/.gitconfig.local` and `~/.zshrc.local` outside the repo. SSH keys, credentials, shell history, caches, downloaded plugins/language servers, and backups should stay on each machine; `.gitignore` excludes common local files if they appear here.

Keep `lazy-lock.json` and `.p10k.zsh`: they pin plugins and configure the prompt.
