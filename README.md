# Install

Requires Git and Homebrew (macOS), apt (Ubuntu), or dnf (other supported Linux distributions). For a cluster without administrator access, use `--cluster` below.

```sh
git clone https://github.com/AnthonyBotticchio/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh --backup
```

Installs dependencies and links Vim, Neovim, tmux, and Git configs. On macOS, it also installs Kitty and its font; `--minimal` skips them. Neovim requires 0.12+. Open `nvim` after setup to install plugins.

## Clusters

For general cluster computing on Linux. Load the site's development modules, then run in an interactive compute allocation:

```sh
./bootstrap.sh --cluster --backup
export PATH="$HOME/.local/bin:$PATH"
zsh
```

Uses existing cluster tools and installs missing Stow, Neovim, ripgrep, Tree-sitter, and Zsh under `~/.local`, without `sudo`. Includes your Zsh config, Oh My Zsh, and Powerlevel10k. Stops before linking configs if Tree-sitter cannot run. Building Zsh requires a C compiler, `xz`, and ncurses development files. Install Neovim plugins in the allocation too. See the [cluster guide](docs/cluster.md) for prerequisites and workflow details.

## Commands

| Command | What it does |
| --- | --- |
| `./bootstrap.sh --backup` | Install dependencies and link configs, backing up existing files. |
| `./bootstrap.sh --minimal --backup` | Same setup, without Kitty or its font on macOS. |
| `./bootstrap.sh --cluster --backup` | Set up editors, tmux, Git, and Zsh without administrator access on a Linux cluster. |
| `./install.sh --dry-run` | Preview config links without changing files. |
| `./install.sh --backup` | Link configs without installing software; back up existing files. |
| `./install.sh --backup nvim tmux` | Link only the named packages. |
| `./install.sh --delete` | Remove the links managed by Stow. |
| `./install-zsh.sh` | Install Zsh, Oh My Zsh, and Powerlevel10k; back up and link shell configs. |
| `./install-zsh.sh --cluster` | Same Zsh setup, building a local copy if needed, without `sudo`. |
| `zsh` | Start the configured shell. |
| `./bootstrap.sh --help`, `./install.sh --help`, `./install-zsh.sh --help` | Show script options. |
| `.\bootstrap.ps1 -WhatIf` | Preview Windows dependency installation and config links. |
| `.\bootstrap.ps1 -Backup` | Install Windows dependencies and link configs, backing up existing files. |
| `.\install.ps1 -WhatIf` | Preview Windows config links. |
| `.\install.ps1 -Backup` | Link Windows configs without installing software. |
| `.\install.ps1 -Packages git,vim -Backup` | Link only the named Windows packages. |

Shell setup leaves your login shell unchanged. Run `zsh` to use it. Keep machine-specific shell settings in `~/.zshrc.local`.

## Windows

**WSL:** use the Linux commands above inside your Linux home.

**Native Windows:** requires Git, PowerShell 5.1+, and WinGet. Enable Developer Mode for symlinks with PowerShell 7; PowerShell 5.1 may need an elevated session.

```powershell
git clone https://github.com/AnthonyBotticchio/dotfiles.git "$HOME/git/dotfiles"
cd "$HOME/git/dotfiles"
.\bootstrap.ps1 -Backup
```

Restart the terminal after installation, then open `nvim` and run `:checkhealth`. Native Windows links Git, Vim, and Neovim. Kitty is macOS-only.

## Git identity

Set your identity in the local file on each machine:

```sh
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.com"
```

Use that file for signing and credential settings too. `git config --global` would edit the shared config in this repo.

Keep local settings, credentials, caches, and backups outside the repo. `lazy-lock.json` and `.p10k.zsh` belong here.
