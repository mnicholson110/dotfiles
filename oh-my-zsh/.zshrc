export PATH="$HOME/.dotfiles/scripts/:$PATH"

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="mnich"
plugins=(git exercism)
alias scala="scala3"
alias scalac="scalac3"
source $ZSH/oh-my-zsh.sh
alias sortty='python3 /usr/local/bin/sortty-bin/sortty.py'
