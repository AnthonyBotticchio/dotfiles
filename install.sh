#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")" && pwd)
target=${DOTFILES_TARGET:-$HOME}
mode=install
case "${1:-}" in
    --backup|--dry-run|--delete) mode=${1#--}; shift ;;
    --help)
        echo "Usage: ./install.sh [--backup|--dry-run|--delete] [packages...]"
        exit 0 ;;
esac

command -v stow >/dev/null || { echo "Install GNU Stow first (brew install stow / sudo apt install stow)." >&2; exit 1; }
[[ -d "$target" ]] || { echo "Target directory does not exist: $target" >&2; exit 1; }
target=$(cd "$target" && pwd)
if [[ $# -eq 0 ]]; then
    set -- vim nvim tmux zsh git htop
    [[ $(uname -s) != Darwin ]] || set -- "$@" kitty
fi
for package in "$@"; do
    case "$package" in
        vim|nvim|tmux|zsh|git|kitty|htop) ;;
        *) echo "Unknown package: $package" >&2; exit 1 ;;
    esac
done

if [[ "$mode" == backup ]]; then
    backup=$(mktemp -d "$target/.dotfiles-backup.XXXXXX")
    echo "Backup: $backup"
    for package in "$@"; do
        sources=("$repo/$package"/.[!.]*)
        if [[ -d "$repo/$package/.config" ]]; then
            sources=("$repo/$package/.config"/*)
        fi
        for source in "${sources[@]}"; do
            relative=${source#"$repo/$package/"}
            destination="$target/$relative"
            if [[ ( -e "$destination" || -L "$destination" ) && ! "$destination" -ef "$source" ]]; then
                mkdir -p "$backup/$(dirname "$relative")"
                mv "$destination" "$backup/$relative"
            fi
        done
    done
fi

args=(--dir="$repo" --target="$target" --verbose)
case "$mode" in
    dry-run) exec stow "${args[@]}" --simulate "$@" ;;
    delete) exec stow "${args[@]}" --delete "$@" ;;
esac
stow "${args[@]}" --simulate "$@"
exec stow "${args[@]}" "$@"
