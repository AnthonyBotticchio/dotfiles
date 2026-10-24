#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
minimal=false
link_args=()
for arg in "$@"; do
    case "$arg" in
        --minimal) minimal=true ;;
        --backup) link_args=(--backup) ;;
        --help)
            echo "Usage: ./bootstrap.sh [--minimal] [--backup]"
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

export PATH="$HOME/.local/bin:$PATH"
system=$(uname -s)
packages=(vim nvim tmux zsh git htop)
case "$system" in
    Darwin)
        command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }
        command -v git >/dev/null || brew install git
        brew install stow vim neovim tmux zsh htop curl unzip ripgrep fd cmake node python
        if ! $minimal; then
            brew install --cask kitty font-fira-code-nerd-font
            packages+=(kitty)
            mkdir -p "$HOME/git"
        fi
        ;;
    Linux)
        source /etc/os-release
        sudo_cmd=()
        if [[ $EUID -ne 0 ]]; then
            command -v sudo >/dev/null || { echo "sudo is required to install system packages." >&2; exit 1; }
            sudo_cmd=(sudo)
        fi
        common=(stow vim neovim tmux zsh htop curl unzip ripgrep fd-find cmake nodejs npm python3-pip)
        command -v git >/dev/null || common+=(git)
        if [[ "$ID" == ubuntu || " ${ID_LIKE:-} " == *" ubuntu "* ]]; then
            ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt update
            ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt install -y "${common[@]}" build-essential clangd clang-format python3-venv
        else
            command -v dnf >/dev/null || { echo "This distribution needs dnf; automatic setup supports Ubuntu and dnf-based systems." >&2; exit 1; }
            ${sudo_cmd[@]+"${sudo_cmd[@]}"} dnf install -y "${common[@]}" gcc gcc-c++ make clang-tools-extra python3
        fi
        ;;
    *) echo "Unsupported system: $system" >&2; exit 1 ;;
esac

recent_nvim() {
    nvim --headless -u NONE -i NONE '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)' >/dev/null 2>&1
}

if ! recent_nvim; then
    [[ "$system" == Linux ]] || { echo "Neovim 0.12+ is required; upgrade your Homebrew Neovim." >&2; exit 1; }
    case "$(uname -m)" in
        x86_64) arch=x86_64 ;;
        aarch64|arm64) arch=arm64 ;;
        *) echo "No automatic Neovim download for this architecture." >&2; exit 1 ;;
    esac
    if [[ -e "$HOME/.local/bin/nvim" && ! -L "$HOME/.local/bin/nvim" ]]; then
        echo "Move the existing ~/.local/bin/nvim before installing a newer version." >&2
        exit 1
    fi
    temp=$(mktemp -d)
    trap 'rm -rf "$temp"' EXIT
    archive="nvim-linux-$arch"
    curl -fL --retry 3 "https://github.com/neovim/neovim/releases/latest/download/$archive.tar.gz" -o "$temp/nvim.tar.gz"
    tar -xzf "$temp/nvim.tar.gz" -C "$temp"
    "$temp/$archive/bin/nvim" --headless -u NONE -i NONE '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)'
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    destination=$(mktemp -d "$HOME/.local/opt/nvim.XXXXXX")
    mv "$temp/$archive" "$destination/"
    ln -sfn "$destination/$archive/bin/nvim" "$HOME/.local/bin/nvim"
    hash -r
fi
recent_nvim || { echo "Neovim 0.12+ is not available on PATH." >&2; exit 1; }

if ! command -v tree-sitter >/dev/null; then
    if [[ "$system" == Darwin ]]; then
        brew install tree-sitter-cli
    else
        npm install --global --prefix "$HOME/.local" tree-sitter-cli
    fi
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
theme="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$theme" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme"
fi
[[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" && -f "$theme/powerlevel10k.zsh-theme" ]] || {
    echo "The existing Oh My Zsh or Powerlevel10k installation is incomplete." >&2
    exit 1
}

"$repo/install.sh" ${link_args[@]+"${link_args[@]}"} "${packages[@]}"
echo 'Setup complete. Run zsh, then open nvim to install its plugins.'
