set -o vi
alias gac='git add . && git commit'
alias v='nvim'
alias s='ls'
alias c='clear'
alias e='exit'
alias o='xdg-open'
alias cp='cp -r'
alias vc='nvim ~/.config/nvim'
alias sy='systemctl'

export VISUAL=nvim
export EDITOR=nvim

export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH=/nvim/build/bin:$PATH
