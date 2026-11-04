#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
target=${DOTFILES_TARGET:-$HOME}
if [[ $# -gt 0 ]]; then
    if [[ $# -eq 1 && $1 == --help ]]; then
        echo "Usage: ./install-zsh.sh"
        echo "Install Zsh, Oh My Zsh, and Powerlevel10k; back up and link shell configs."
        exit 0
    fi
    echo "Unknown option: $1" >&2
    exit 1
fi
[[ -d "$target" ]] || { echo "Target directory does not exist: $target" >&2; exit 1; }
target=$(cd "$target" && pwd)

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
