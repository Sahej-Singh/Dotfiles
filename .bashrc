#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#alias sudo='sudo	'
alias ls='ls --color=auto'
alias fuck='sudo !!'
alias Westworld='echo "Have you ever questioned the nature of your reality?"'
alias yank='yank -- xsel -b'
alias tuir='tuir --enable-media'
alias wind.ser='sudo systemctl start windscribe.service'
alias spt.ser='systemctl --user restart spotifyd.service'
export PS1="\e[0;36m[\u@\h \W]\$ \e[m"

ccd()
{
	mkdir -p "$1"
	cd "$1"
}
#PS1='[\u@\h \W]\$ '
#export XDG_CURRENT_DESKTOP=KDE
