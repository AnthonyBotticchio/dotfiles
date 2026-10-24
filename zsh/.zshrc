if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -U path
path=("$HOME/.local/bin" $path)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

[[ ! -d "$HOME/.docker/completions" ]] || fpath=("$HOME/.docker/completions" $fpath)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit
    compinit
fi

alias sros="source install/setup.sh"
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

[[ ! -r ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -r ~/git/qhpc/.qhpc-rm-guard.zsh ]] || source ~/git/qhpc/.qhpc-rm-guard.zsh
[[ ! -r ~/.zshrc.local ]] || source ~/.zshrc.local
