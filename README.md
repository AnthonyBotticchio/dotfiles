# Dotfiles

Personal configs managed with GNU Stow. Each package mirrors paths under your
home directory: `nvim/.config/nvim` becomes `~/.config/nvim`. After installation,
editing either path edits the same files. Keep this checkout in place.

## Install

Clone this repository, enter it, and run as your normal user:

```sh
./bootstrap.sh --backup
```

This installs dependencies with **apt on Ubuntu** (including Ubuntu derivatives),
**dnf on other supported Linux distributions**, and **Homebrew on macOS**.
Homebrew must already be installed. Linux package installation uses sudo when
needed; user tools and shell dependencies stay in your home directory.
Distributions without apt on Ubuntu or dnf elsewhere are not automatically supported.

Kitty and FiraCode Nerd Font install only on macOS. Use `--minimal` to skip them:

```sh
./bootstrap.sh --minimal --backup
```

The bootstrap installs Oh My Zsh and Powerlevel10k without changing your login
shell. Run `zsh` afterward, or set it as your login shell yourself. Existing shell
dependency directories are reused. Package-manager errors stop setup.
Git is reused when available on PATH. Missing Tree-sitter CLI is installed with
Homebrew on macOS and npm on Linux.

If dependencies are already installed, use Stow alone:

```sh
./install.sh --dry-run
./install.sh --backup
```

The preview reports conflicts with existing configs. `--backup` moves those
configs into a unique `~/.dotfiles-backup.*` directory before linking. Plain
`./install.sh` refuses conflicts. Backups may contain entire app config folders;
keep them until you have checked your setup.

To install only certain packages (useful on remote machines):

```sh
./install.sh --backup vim nvim tmux zsh
```

Packages: `vim`, `nvim`, `tmux`, `zsh`, `git`, `htop`, plus `kitty` on macOS.
The Git package includes my name, email, and aliases; edit it before using
another identity. Credentials, histories, caches, and downloaded plugins are
excluded. iTerm2's local sockets and application-support symlink are excluded.

## Dependencies

- Neovim uses recent APIs including `autocomplete`; use Neovim 0.12 or newer.
  Bootstrap tries the system package first. On Linux, if it is too old, bootstrap
  downloads the [official stable x86_64/arm64 archive](https://neovim.io/doc/install/) into `~/.local/opt` and links
  `~/.local/bin/nvim`. An incompatible download stops setup before linking configs.
  Its existing configuration installs lazy.nvim and plugins on first launch.
  Run `:Lazy restore` to use the committed lockfile. Bootstrap includes `ripgrep`,
  Node/npm, Python, and the Tree-sitter CLI. On Linux it also installs compiler
  tools, `clangd`, and `clang-format`; on macOS those must already be available
  for the corresponding editor features. Mason installs configured language
  servers on first launch.
- Oh My Zsh lives at `~/.oh-my-zsh` and Powerlevel10k at
  `~/.oh-my-zsh/custom/themes/powerlevel10k`; neither is vendored.
- Kitty uses FiraCode Nerd Font Mono and starts in `~/git`, created by bootstrap.
  For remote machines, the font belongs on the machine running your terminal.
- Homebrew, Docker completions, OrbStack, and the QHPC shell guard load only
  when present. Put machine-specific shell settings in `~/.zshrc.local`.

## Everyday use

Edit configs here, then commit and push. On another machine, `git pull` updates
the linked files; reload the affected application. Run `./install.sh` again
after adding files if Stow linked individual files instead of a whole folder.

To unlink, run `./install.sh --delete` (or append package names). This preserves
the repository. Restore original configs from the backup directory if needed.

To add an application, create a package matching its home-relative paths and run
`stow --target="$HOME" package-name` from this directory. Add it to the installer
lists if it should be included there too.

For a disposable target: `DOTFILES_TARGET=/path/to/test-home ./install.sh`.
