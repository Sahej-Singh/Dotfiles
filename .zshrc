# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -v
# End of lines configured by zsh-newuser-install
#alias sudo='sudo	'
alias ls='ls --color=auto'
alias fuck='sudo !!'
alias Westworld='echo "Have you ever questioned the nature of your reality?"'
alias yank='yank -- xsel -b'

export PS1="\e[0;36m[\u@\h \W]\$ \e[m"

ccd()
{
	mkdir -p "$1"
	cd "$1"
}
## The following lines were added by compinstall
zstyle :compinstall filename '/home/sahej/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
