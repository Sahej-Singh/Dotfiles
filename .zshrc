# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# .zshrc
# Basic zsh config.

umask 077
ZDOTDIR=${ZDOTDIR:-${HOME}}
ZSHDDIR="${HOME}/.config/zsh.d"
HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE='10000'
SAVEHIST="${HISTSIZE}"
ZSH='/usr/share/oh-my-zsh'
ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_AUTO_UPDATE="true"
plugins=(git
	themes
	virtualenv
	sudo 
	emoji
	fancy-ctrl-z)

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi


export EDITOR="/usr/bin/nvim"
export TMP="/tmp"
export TEMP="$TMP"
export TMPDIR="$TMP"
export TMPPREFIX="${TMPDIR}/zsh"
export BROWSER="/usr/bin/firefox"
export COLORTERM="truecolor"
# Copied from arch wiki - color output in console
export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

if [ ! -d "${TMP}" ]; then mkdir "${TMP}"; fi

# Use hostname in TMUX_TMPDIR as $HOME may be on nfs.
export TMUX_TMPDIR="${TMPDIR}/tmux-${HOST}-${UID}"
if [ ! -d "${TMUX_TMPDIR}" ]; then mkdir -p "${TMUX_TMPDIR}"; fi

if ! [[ "${PATH}" =~ "^${HOME}/bin" ]]; then
    export PATH="${HOME}/bin:${PATH}"
fi

# Colors.
red='\e[0;31m'
RED='\e[1;31m'
green='\e[0;32m'
GREEN='\e[1;32m'
yellow='\e[0;33m'
YELLOW='\e[1;33m'
blue='\e[0;34m'
BLUE='\e[1;34m'
purple='\e[0;35m'
PURPLE='\e[1;35m'
cyan='\e[0;36m'
CYAN='\e[1;36m'
NC='\e[0m'

# Functions

# Fancy cd that can cd into parent directory, if trying to cd into file.
# useful with ^F fuzzy searcher.
cd() {
    if (( $+2 )); then
        builtin cd "$@"
        return 0
    fi

    if [ -f "$1" ]; then
        echo "${yellow}cd ${1:h}${NC}" >&2
        builtin cd "${1:h}"
    else
        builtin cd "${@}"
    fi
}

run_under_tmux() {
    # Run $1 under session or attach if such session already exist.
    # $2 is optional path, if no specified, will use $1 from $PATH.
    # If you need to pass extra variables, use $2 for it as in example below..
    # Example usage:
    #   torrent() { run_under_tmux 'rtorrent' '/usr/local/rtorrent-git/bin/rtorrent'; }
    #   mutt() { run_under_tmux 'mutt'; }
    #   irc() { run_under_tmux 'irssi' "TERM='screen' command irssi"; }


    # There is a bug in linux's libevent...
    # export EVENT_NOEPOLL=1

    command -v tmux >/dev/null 2>&1 || return 1

    if [ -z "$1" ]; then return 1; fi
        local name="$1"
    if [ -n "$2" ]; then
        local execute="$2"
    else
        local execute="command ${name}"
    fi

    if tmux has-session -t "${name}" 2>/dev/null; then
        tmux attach -d -t "${name}"
    else
        tmux new-session -s "${name}" "${execute}" \; set-option status \; set set-titles-string "${name} (tmux@${HOST})"
    fi
}

t() { run_under_tmux rtorrent 'nice -n 19 ionice -c 3 rtorrent'; }
irc() { run_under_tmux irssi "TERM='screen' command irssi"; }

over_ssh() {
    if [ -n "${SSH_CLIENT}" ]; then
        return 0
    else
        return 1
    fi
}

reload () {
    exec "${SHELL}" "$@"
}

escape() {
    # Uber useful when you need to translate weird as fuck path into single-argument string.
    local escape_string_input
    echo -n "String to escape: "
    read escape_string_input
    printf '%q\n' "$escape_string_input"
}

confirm() {
    local answer
    echo -ne "zsh: sure you want to run '${YELLOW}$*${NC}' [yN]? "
    read -q answer
        echo
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        command "${@}"
    else
        return 1
    fi
}

confirm_wrapper() {
    if [ "$1" = '--root' ]; then
        local as_root='true'
        shift
    fi

    local prefix=''

    if [ "${as_root}" = 'true' ] && [ "${USER}" != 'root' ]; then
        prefix="sudo"
    fi
    confirm ${prefix} "$@"
}

poweroff() { confirm_wrapper --root $0 "$@"; }
# reboot() { confirm_wrapper --root $0 "$@"; }
# hibernate() { confirm_wrapper --root $0 "$@"; }

startx() {
    exec =startx
}

has() {
    local string="${1}"
    shift
    local element=''
    for element in "$@"; do
        if [ "${string}" = "${element}" ]; then
            return 0
        fi
    done
    return 1
}

begin_with() {
    local string="${1}"
    shift
    local element=''
    for element in "$@"; do
        if [[ "${string}" =~ "^${element}" ]]; then
            return 0
        fi
    done
    return 1

}

termtitle() {
    case "$TERM" in
        rxvt*|xterm*|nxterm|gnome|screen|screen-*)
            local prompt_host="${(%):-%m}"
            local prompt_user="${(%):-%n}"
            local prompt_char="${(%):-%~}"
            case "$1" in
                precmd)
                    printf '\e]0;%s@%s: %s\a' "${prompt_user}" "${prompt_host}" "${prompt_char}"
                ;;
                preexec)
                    printf '\e]0;%s [%s@%s: %s]\a' "$2" "${prompt_user}" "${prompt_host}" "${prompt_char}"
                ;;
            esac
        ;;
    esac
}

setup_git_prompt() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        unset git_prompt
        return 0
    fi

    local git_status_dirty git_branch

    if [ "$(git --no-optional-locks status --untracked-files='no' --porcelain)" ]; then
        git_status_dirty='%F{green}*'
    else
        unset git_status_dirty
    fi

    git_branch="$(git symbolic-ref HEAD 2>/dev/null)"
    git_branch="${git_branch#refs/heads/}"

    if [ "${#git_branch}" -ge 24 ]; then
        git_branch="${git_branch:0:21}..."
    fi

    git_branch="${git_branch:-no branch}"

    git_prompt=" %F{blue}[%F{253}${git_branch}${git_status_dirty}%F{blue}]"

}

precmd() {
    # Set terminal title.
    termtitle precmd

    # Set optional git part of prompt.
    setup_git_prompt

# Maybe to be used someday, too annoying with vim and other interactive apps.
#   # $REPORTTIME is about cpu time, not real time.
#   if [ "${executed_on}" ]; then
#       local current_timestamp=${(%):-'%D{%s}'}
#       local last_cmd_took=$(( current_timestamp - executed_on ))
#       if [ "${last_cmd_took}" -gt 60 ]; then
#           printf "\n>>> [INFO] Execution took %ss\n\n" "$last_cmd_took"
#       fi
#       unset executed_on
#   fi
}

preexec() {
    # Set terminal title along with current executed command pass as second argument
    termtitle preexec "${(V)1}"

#   # Save timestamp when we executed this command
#   executed_on=${(%):-'%D{%s}'}
}

man() {
    if command -v vimmanpager >/dev/null 2>&1; then
        PAGER="vimmanpager" command man "$@"
    else
        command man "$@"
    fi
}


dot_progress() {
    # Fancy progress function from Landley's Aboriginal Linux.
    # Useful for long rm, tar and such.
    # Usage: 
    #     rm -rfv /foo | dot_progress
    local i='0'
    local line=''

    while read line; do
        i="$((i+1))"
        if [ "${i}" = '25' ]; then
            printf '.'
            i='0'
        fi
    done
    printf '\n'
}


# Le features!
# extended globbing, awesome!
setopt extendedGlob

# zmv -  a command for renaming files by means of shell patterns.
autoload -U zmv

# zargs, as an alternative to find -exec and xargs.
autoload -U zargs

# Turn on command substitution in the prompt (and parameter expansion and arithmetic expansion).
setopt promptsubst


# (switch to vim mode)

# Control-x-e to open current line in $EDITOR, awesome when writting functions or editing multiline commands.
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# Include user-specified configs.
if [ ! -d "${ZSHDDIR}" ]; then
    mkdir -p "${ZSHDDIR}" && echo "# Put your user-specified config here." > "${ZSHDDIR}/example.zsh"
fi

for zshd in $(ls -A ${HOME}/.config/zsh.d/^*.(z)sh$); do
    . "${zshd}"
done

# Completion.
autoload -Uz compinit
compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' menu select=2
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*:descriptions' format '%U%F{cyan}%d%f%u'

# If running as root and nice >0, renice to 0.
if [ "$USER" = 'root' ] && [ "$(cut -d ' ' -f 19 /proc/$$/stat)" -gt 0 ]; then
    renice -n 0 -p "$$" && echo "# Adjusted nice level for current shell to 0."
fi

# Fancy prompt.
if over_ssh && [ -z "${TMUX}" ]; then
    prompt_is_ssh='%F{blue}[%F{red}SSH%F{blue}] '
elif over_ssh; then
    prompt_is_ssh='%F{blue}[%F{253}SSH%F{blue}] '
else
    unset prompt_is_ssh
fi

case $USER in
    root)
        PROMPT='%B%F{cyan}%m%k %(?..%F{blue}[%F{253}%?%F{blue}] )${prompt_is_ssh}%B%F{blue}%1~${git_prompt}%F{blue} %# %b%f%k'
    ;;

    *)  
        PROMPT='%B%F{blue}%n@%m%k %(?..%F{blue}[%F{253}%?%F{blue}] )${prompt_is_ssh}%B%F{cyan}%1~${git_prompt}%F{cyan} %# %b%f%k'

    ;;
esac

# Keep history of `cd` as in with `pushd` and make `cd -<TAB>` work.
DIRSTACKSIZE=16
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_minus

# Ignore lines prefixed with '#'.
setopt interactivecomments

# Ignore duplicate in history.
setopt hist_ignore_dups

# Prevent record in history entry if preceding them with at least one space
setopt hist_ignore_space

# Nobody need flow control anymore. Troublesome feature.
#stty -ixon
setopt noflowcontrol

# Ensure that / is added after tab complation to directories.
# without disabling it, $LBUFFER does not have the slash at the end
# and it's required for _append_path_to_buffer thing..
#setopt AUTO_PARAM_SLASH
#unsetopt AUTO_REMOVE_SLASH

_select_path_with_fzy() {
    (
        if [ "$1" != '.' ]; then
            if ! [ -d $~1 ]; then
                echo -e "${yellow}The $1 is not a directory.${NC}"  >&2
                return
            fi
            cd $~1
        fi

        find -L . \( -type d -printf "%p/\n" , -type f -print \) 2>/dev/null | cut -c 3- | sort | fzy
    )
}

_append_path_to_buffer() {
    local selected_path

    if ! command -v fzy >/dev/null 2>&1; then
        echo 'No fzy binary found in $PATH.'
        return 1
    fi
    echo
    print -nr "${zle_bracketed_paste[2]}" >/dev/tty
    {
        if [ "${LBUFFER[-1]}" = '/' ]; then
            search_in="${LBUFFER##*[$'\t' ]}"
        else
            search_in='.'
        fi

        selected_path="$(_select_path_with_fzy "${search_in}")"
    } always {
        print -nr "${zle_bracketed_paste[1]}" >/dev/tty
    }
    if [ "${selected_path}" ]; then
        if [[ "${LBUFFER[-1]}" =~ [[:alnum:]] ]]; then
            # if last character is a word character, insert space.
            # before inserting selected path. Useful when one's lazy 
            # and use 'vim^F', yet works okay with 'cmd foo=^F'.
            LBUFFER+=" "
        fi
        LBUFFER+="${(q)selected_path}"
    fi
    zle reset-prompt
}
zle -N _append_path_to_buffer
bindkey "^F" _append_path_to_buffer

_history_search_with_fzy() {
    local selected_history_entry

    if ! command -v fzy >/dev/null 2>&1; then
        echo 'No fzy binary found in $PATH.'
        return 1
    fi

    if ! command -v awk >/dev/null 2>&1; then
        echo 'No awk binary found in $PATH.'
        return 1
    fi
    echo

    print -nr "${zle_bracketed_paste[2]}" >/dev/tty
    {
        # The awk is used to filter out duplicates, keeping the most 
        # recent entries, while not re-ordering the history list.
        selected_history_entry="$(fc -nrl 1 | awk '!v[$0]++' | fzy)"
    } always {
        print -nr "${zle_bracketed_paste[1]}" >/dev/tty
    }
    if [ "${selected_history_entry}" ]; then
        BUFFER="${selected_history_entry}"
        CURSOR="${#BUFFER}"
    fi
    zle reset-prompt
}
zle -N _history_search_with_fzy
bindkey "^T" _history_search_with_fzy

# ^A to open new terminal in current working directory
# Check `logname` so we won't create new terminal as user after `su`.
_open_new_terminal_here(){
    if \
        [ "${XAUTHORITY}" ] && \
        [ "${DISPLAY}" ] && \
        [ "${LOGNAME}" = "$(logname)" ] && \
        command -v urxvt >/dev/null 2>&1
    then
        # Spawn terminal with clean login shell.
        env -i \
            XAUTHORITY="${XAUTHORITY}" \
            PATH="${PATH}" \
            HOME="${HOME}" \
            DISPLAY="${DISPLAY}" \
            LOGNAME="${LOGNAME}" \
            SHELL="${SHELL}" \
            LANG="${LANG}" \
            urxvt -e "${SHELL}" --login >/dev/null 2>&1 &!
    fi
}
zle -N _open_new_terminal_here
bindkey "^A" _open_new_terminal_here

# Fix for tmux on linux.
case "$(uname -o)" in
    'GNU/Linux')
        export EVENT_NOEPOLL=1
    ;;
esac

# Aliases
alias cp='cp -iv'
alias rcp='rsync -v --progress'
alias rmv='rsync -v --progress --remove-source-files'
alias mv='mv -iv'
alias rm='rm -iv'
alias rmdir='rmdir -v'
alias ln='ln -v'
alias chmod="chmod -c"
alias chown="chown -c"
alias mkdir="mkdir -v"
alias tuir='tuir --enable-media'
alias sudo='sudo '
alias fuck='sudo !!'
alias westworld='echo "Have you ever questioned the nature of your reality?" && mpv /mnt/HDD/music/westworld'
alias yank='yank -- xsel -b'
alias tuir='tuir --enable-media'
alias wind.ser='sudo systemctl start windscribe.service'
alias wind.us='windscribe connect US'
alias spt.ser='systemctl --user restart spotifyd.service'
alias haha='feh -F --slideshow-delay 3.5 "/mnt/HDD/Tab_Backup/milo_haha" | mpv /mnt/HDD/music/haHAhaHAhaHAha.mp3'
alias tb='taskbook'
alias mus='cd /mnt/HDD/music && cmus '
alias dow='cd /mnt/HDD/Downloads'
alias x.s='xset dpms force standby'
alias sus='systemctl suspend'
alias shut='shutdown -h now'
if command -v colordiff > /dev/null 2>&1; then
    alias diff="colordiff -Nuar"
else
    alias diff="diff -Nuar"
fi

alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias ls='ls --color=auto --human-readable --group-directories-first --classify'
alias ll='ls --color=auto --human-readable --group-directories-first --classify -l'
alias lla='ls --color=auto --human-readable --group-directories-first --classify -la'
alias w.n='curl "https://wttr.in/noida"'


# Keys.
case $TERM in
    rxvt*|xterm*)
        bindkey "^[[7~" beginning-of-line #Home key
        bindkey "^[[8~" end-of-line #End key
        bindkey "^[[3~" delete-char #Del key
        bindkey "^[[A" history-beginning-search-backward #Up Arrow
        bindkey "^[[B" history-beginning-search-forward #Down Arrow
        bindkey "^[Oc" forward-word # control + right arrow
        bindkey "^[Od" backward-word # control + left arrow
        bindkey "^H" backward-kill-word # control + backspace
        bindkey "^[[3^" kill-word # control + delete
    ;;

    linux)
        bindkey "^[[1~" beginning-of-line #Home key
        bindkey "^[[4~" end-of-line #End key
        bindkey "^[[3~" delete-char #Del key
        bindkey "^[[A" history-beginning-search-backward
        bindkey "^[[B" history-beginning-search-forward
    ;;

    screen|screen-*)
        bindkey "^[[1~" beginning-of-line #Home key
        bindkey "^[[4~" end-of-line #End key
        bindkey "^[[3~" delete-char #Del key
        bindkey "^[[A" history-beginning-search-backward #Up Arrow
        bindkey "^[[B" history-beginning-search-forward #Down Arrow
        bindkey "^[Oc" forward-word # control + right arrow
        bindkey "^[OC" forward-word # control + right arrow
        bindkey "^[Od" backward-word # control + left arrow
        bindkey "^[OD" backward-word # control + left arrow
        bindkey "^H" backward-kill-word # control + backspace
        bindkey "^[[3^" kill-word # control + delete
    ;;
esac

# Replaced with _history_search_with_fzy
bindkey "^R" history-incremental-pattern-search-backward 
bindkey "^S" history-incremental-pattern-search-forward


if [ -f ~/.alert ]; then echo '>>> Check ~/.alert'; fi
	
bindkey -M viins '\e.' insert-last-word
source $ZSH/oh-my-zsh.sh
source $ZSH/custom/themes/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
bindkey -v 
