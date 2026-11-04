#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
target=${DOTFILES_TARGET:-$HOME}
cluster=false
for arg in "$@"; do
    case "$arg" in
        --cluster) cluster=true ;;
        --help)
            echo "Usage: ./install-zsh.sh [--cluster]"
            echo "Install Zsh, Oh My Zsh, and Powerlevel10k; back up and link shell configs."
            echo "  --cluster  Build missing Zsh under ~/.local without sudo (Linux)."
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done
[[ -d "$target" ]] || { echo "Target directory does not exist: $target" >&2; exit 1; }
target=$(cd "$target" && pwd)
export PATH="$HOME/.local/bin:$PATH"

if $cluster; then
    [[ $(uname -s) == Linux ]] || { echo "--cluster requires Linux." >&2; exit 1; }
    command -v git >/dev/null || { echo "Load Git from the site modules before installing Zsh." >&2; exit 1; }
    if ! command -v zsh >/dev/null; then
        for tool in curl tar xz make; do
            command -v "$tool" >/dev/null || { echo "Load $tool before building Zsh." >&2; exit 1; }
        done
        if [[ -e "$HOME/.local/bin/zsh" || -L "$HOME/.local/bin/zsh" ]]; then
            echo "Move the existing ~/.local/bin/zsh before installing Zsh." >&2
            exit 1
        fi
        temp=$(mktemp -d)
        trap 'rm -rf "$temp"' EXIT
        curl -fL --retry 3 https://www.zsh.org/pub/zsh-5.9.2.tar.xz -o "$temp/zsh.tar.xz"
        tar -xJf "$temp/zsh.tar.xz" -C "$temp"
        mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
        destination=$(mktemp -d "$HOME/.local/opt/zsh.XXXXXX")
        if ! (
            cd "$temp/zsh-5.9.2" &&
            ./configure --prefix="$destination" --enable-multibyte &&
            make -j1 &&
            make -j1 install
        ); then
            echo "Zsh build failed. Check that a C compiler and ncurses development files are available." >&2
            exit 1
        fi
        "$destination/bin/zsh" --version
        ln -s "$destination/bin/zsh" "$HOME/.local/bin/zsh"
        hash -r
    fi
fi

missing=()
for tool in zsh git; do
    command -v "$tool" >/dev/null || missing+=("$tool")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    case "$(uname -s)" in
        Darwin)
            command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }
            brew install "${missing[@]}"
            ;;
        Linux)
            source /etc/os-release
            sudo_cmd=()
            if [[ $EUID -ne 0 ]]; then
                command -v sudo >/dev/null || { echo "Ask your administrator to install: ${missing[*]}" >&2; exit 1; }
                sudo_cmd=(sudo)
            fi
            if [[ "$ID" == ubuntu || " ${ID_LIKE:-} " == *" ubuntu "* ]]; then
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt update
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} apt install -y "${missing[@]}"
            else
                command -v dnf >/dev/null || { echo "Install ${missing[*]} first; automatic Linux installation supports Ubuntu and dnf-based systems." >&2; exit 1; }
                ${sudo_cmd[@]+"${sudo_cmd[@]}"} dnf install -y "${missing[@]}"
            fi
            ;;
        *) echo "Install ${missing[*]} first on this system." >&2; exit 1 ;;
    esac
fi
for tool in zsh git; do
    command -v "$tool" >/dev/null || { echo "$tool is not available on PATH." >&2; exit 1; }
done

omz="$target/.oh-my-zsh"
if [[ ! -r "$omz/oh-my-zsh.sh" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz"
fi
p10k_dir="$omz/custom/themes/powerlevel10k"
if [[ ! -r "$p10k_dir/powerlevel10k.zsh-theme" ]]; then
    mkdir -p "$omz/custom/themes"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
fi

backup=
for name in .zshrc .p10k.zsh; do
    source_file="$repo/zsh/$name"
    destination="$target/$name"
    [[ ! "$destination" -ef "$source_file" ]] || continue
    if [[ -e "$destination" || -L "$destination" ]]; then
        if [[ -z "$backup" ]]; then
            backup=$(mktemp -d "$target/.zsh-backup.XXXXXX")
            echo "Backup: $backup"
        fi
        mv "$destination" "$backup/$name"
    fi
    ln -s "$source_file" "$destination"
done

echo 'Zsh setup complete. Run zsh to start your configured shell.'
