# Install

Requires Git and Homebrew on macOS, apt on Ubuntu, or dnf on other Linux distributions.

```sh
git clone https://github.com/AnthonyBotticchio/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles
./bootstrap.sh --backup
zsh
```

Installs dependencies and links configs, backing up existing files first.
Add `--minimal` to skip Kitty and its font on macOS.
