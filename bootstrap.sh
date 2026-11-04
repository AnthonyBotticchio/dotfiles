#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
minimal=false
cluster=false
link_args=()
for arg in "$@"; do
    case "$arg" in
        --minimal) minimal=true ;;
        --cluster) cluster=true ;;
        --backup) link_args=(--backup) ;;
        --help)
            echo "Usage: ./bootstrap.sh [--minimal] [--cluster] [--backup]"
            echo "  --cluster  Use Linux cluster tools on PATH; install missing Stow/Neovim/Tree-sitter/Zsh under ~/.local."
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

export PATH="$HOME/.local/bin:$PATH"
system=$(uname -s)
if $cluster && [[ "$system" != Linux ]]; then
    echo "--cluster requires Linux." >&2
    exit 1
fi
packages=(vim nvim tmux git)
case "$system" in
    Darwin)
        command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }
        command -v git >/dev/null || brew install git
        brew install stow vim neovim tmux curl unzip ripgrep fd cmake node python
        if ! $minimal; then
            brew install --cask kitty font-fira-code-nerd-font
            packages+=(kitty)
            mkdir -p "$HOME/git"
        fi
        ;;
    Linux)
        if $cluster; then
            missing=()
            for tool in git vim tmux curl tar gzip unzip make perl rg python3; do
                command -v "$tool" >/dev/null || missing+=("$tool")
            done
            if ! command -v cc >/dev/null && ! command -v gcc >/dev/null && ! command -v clang >/dev/null; then
                missing+=("C compiler")
            fi
            if [[ ${#missing[@]} -gt 0 ]]; then
                printf 'Missing cluster tools: %s\n' "${missing[*]}" >&2
                echo 'Load the site modules or install these in your user account, then retry. See docs/cluster.md.' >&2
                exit 1
            fi
        else
            source /etc/os-release
            sudo_cmd=()
            if [[ $EUID -ne 0 ]]; then
                command -v sudo >/dev/null || { echo "sudo is required to install system packages." >&2; exit 1; }
                sudo_cmd=(sudo)
            fi
            common=(stow vim neovim tmux curl unzip ripgrep fd-find cmake nodejs npm python3-pip)
            command -v git >/dev/null || common+=(git)
            if [[ "$ID" == ubuntu || " ${ID_LIKE:-} " == *" ubuntu "* ]]; then
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt update
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt install -y "${common[@]}" build-essential clangd clang-format python3-venv
            else
                command -v dnf >/dev/null || { echo "This distribution needs dnf; automatic setup supports Ubuntu and dnf-based systems." >&2; exit 1; }
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} dnf install -y "${common[@]}" gcc gcc-c++ make clang-tools-extra python3
            fi
        fi
        ;;
    *) echo "Unsupported system: $system" >&2; exit 1 ;;
esac

temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT

if $cluster && ! command -v stow >/dev/null; then
    curl -fL --retry 3 https://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz -o "$temp/stow.tar.gz"
    tar -xzf "$temp/stow.tar.gz" -C "$temp"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    destination=$(mktemp -d "$HOME/.local/opt/stow.XXXXXX")
    (
        cd "$temp/stow-2.4.1"
        ./configure --prefix="$destination"
        make -j1
        make -j1 install
    )
    ln -s "$destination/bin/stow" "$HOME/.local/bin/stow"
fi

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

recent_tree_sitter() {
    local version major minor patch
    version=$("${1:-tree-sitter}" --version 2>/dev/null) || return 1
    [[ "$version" =~ ^tree-sitter\ ([0-9]+)\.([0-9]+)\.([0-9]+) ]] || return 1
    major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[3]}
    (( major > 0 || minor > 26 || (minor == 26 && patch >= 1) ))
}

if ! recent_tree_sitter; then
    if [[ "$system" == Darwin ]]; then
        brew install tree-sitter-cli
    else
        case "$(uname -m)" in
            x86_64) arch=x64 ;;
            aarch64|arm64) arch=arm64 ;;
            *) echo "Install Tree-sitter CLI 0.26.1+ for this architecture, then retry." >&2; exit 1 ;;
        esac
        if [[ -e "$HOME/.local/bin/tree-sitter" && ! -L "$HOME/.local/bin/tree-sitter" ]]; then
            echo "Move the existing ~/.local/bin/tree-sitter before installing a newer version." >&2
            exit 1
        fi
        curl -fL --retry 3 "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-$arch.gz" -o "$temp/tree-sitter.gz"
        gzip -dc "$temp/tree-sitter.gz" > "$temp/tree-sitter"
        chmod +x "$temp/tree-sitter"
        recent_tree_sitter "$temp/tree-sitter" || { echo "Downloaded Tree-sitter CLI is incompatible with this host." >&2; exit 1; }
        mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
        destination=$(mktemp -d "$HOME/.local/opt/tree-sitter.XXXXXX")
        mv "$temp/tree-sitter" "$destination/"
        ln -sfn "$destination/tree-sitter" "$HOME/.local/bin/tree-sitter"
        hash -r
    fi
fi
recent_tree_sitter || { echo "Tree-sitter CLI 0.26.1+ is not available on PATH." >&2; exit 1; }

"$repo/install.sh" ${link_args[@]+"${link_args[@]}"} "${packages[@]}"
if $cluster; then
    "$repo/install-zsh.sh" --cluster
    echo 'Cluster setup complete. Run zsh to start your shell, then open nvim in a compute allocation to install plugins.'
else
    echo 'Setup complete. Open nvim to install its plugins.'
fi
