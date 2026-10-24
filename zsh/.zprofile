for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_path" ]]; then
        eval "$("$brew_path" shellenv)"
        break
    fi
done
unset brew_path

if [[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi
[[ ! -r ~/.orbstack/shell/init.zsh ]] || source ~/.orbstack/shell/init.zsh
