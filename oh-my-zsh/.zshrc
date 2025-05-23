export PATH="$HOME/.dotfiles/scripts/:$HOME/.local/bin/:/usr/lib/jvm/java-22-openjdk/bin/:$PATH"

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="mnich"
plugins=(git)
alias tt="tt -showwpm"
source $ZSH/oh-my-zsh.sh
source $HOME/.cargo/env
alias ls="ls --color=tty"
alias compose="docker-compose"
alias lsg="ls | grep"
export GOPATH="$HOME/.go"
