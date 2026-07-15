# =============================================================================
# .zshrc — zero external deps, works on any system with zsh 4.3.11+
# =============================================================================

# ---------------------------------------------------------------------------
# Local pre-load (PATH etc. — loaded again at the end for overrides)
# ---------------------------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------
autoload -Uz compinit && compinit -u
zmodload -i zsh/complist

zstyle ':completion:*' completer _expand _complete _match _approximate
zstyle ':completion:*' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{green}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ---------------------------------------------------------------------------
# Prompt (pure zsh — git branch + dirty indicator)
# ---------------------------------------------------------------------------
autoload -Uz colors && colors

_git_prompt_info() {
  local branch=""
  # try git symbolic-ref first (fast)
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return

  local dirty=""
  if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
    dirty="%F{red}*%f"
  fi
  echo " %F{cyan}(%F{green}${branch}${dirty}%F{cyan})%f"
}

setopt prompt_subst

# 2-line prompt: [HH:MM:SS] user@host:path (git) \n ❯
PROMPT='%F{248}[%D{%H:%M:%S}]%f %F{blue}%n%f@%F{magenta}%m%f:%F{yellow}%~%f$(_git_prompt_info)
%(?:%F{green}:%F{red})❯%f '

# ---------------------------------------------------------------------------
# Keybindings (emacs mode)
# ---------------------------------------------------------------------------
bindkey -e
bindkey "^U" backward-kill-line
bindkey "^[[A" up-line-or-search      # Up: history prefix search
bindkey "^[[B" down-line-or-search    # Down: history prefix search
bindkey "^[[1;5C" forward-word        # Ctrl+Right
bindkey "^[[1;5D" backward-word       # Ctrl+Left
bindkey "^[[H" beginning-of-line      # Home
bindkey "^[[F" end-of-line            # End
bindkey "^[[3~" delete-char           # Delete

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------
HISTFILE=${HOME}/.zhistory
HISTSIZE=50000
SAVEHIST=50000

setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history
setopt extended_history
setopt inc_append_history

# ---------------------------------------------------------------------------
# History search (Ctrl+R) — pure zsh, no fzf needed
# ---------------------------------------------------------------------------
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# Incremental search (built-in)
bindkey "^R" history-incremental-pattern-search-backward
bindkey "^S" history-incremental-pattern-search-forward

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
setopt no_beep
setopt correct
setopt print_eight_bit
setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt magic_equal_subst
setopt complete_in_word
setopt globdots
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt interactive_comments
setopt IGNORE_EOF

# Treat '/' as a word separator
typeset -g WORDCHARS=${WORDCHARS:s@/@@}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias la='ls -a --color=auto'
alias ll='ls -l --color=auto'
alias lla='ls -la --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# ---------------------------------------------------------------------------
# Colors (dircolors for ls)
# ---------------------------------------------------------------------------
if [[ -x /usr/bin/dircolors ]]; then
  if [[ -f ~/.dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi
fi

# ---------------------------------------------------------------------------
# Terminal title (xterm/screen/tmux)
# ---------------------------------------------------------------------------
case "$TERM" in
  xterm*|rxvt*|screen*|tmux*)
    precmd() {
      print -Pn "\e]0;%n@%m:%~\a"
    }
    preexec() {
      print -Pn "\e]0;$1\a"
    }
    ;;
esac

# ---------------------------------------------------------------------------
# Syntax highlighting (lightweight, pure zsh — bracket matching only)
# ---------------------------------------------------------------------------
# zsh 4.3.11+ has bracket highlighting built-in
if [[ ${ZSH_VERSION//./} -ge 4311 ]]; then
  zle_highlight=(region:standout special:standout suffix:bold isearch:underline)
fi

# ---------------------------------------------------------------------------
# Extract helper
# ---------------------------------------------------------------------------
extract() {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2) tar xjf $1    ;;
      *.tar.gz)  tar xzf $1    ;;
      *.tar.xz)  tar xJf $1    ;;
      *.bz2)     bunzip2 $1    ;;
      *.gz)      gunzip $1     ;;
      *.tar)     tar xf $1     ;;
      *.tbz2)    tar xjf $1    ;;
      *.tgz)     tar xzf $1    ;;
      *.zip)     unzip $1      ;;
      *.Z)       uncompress $1 ;;
      *.7z)      7z x $1       ;;
      *.xz)      xz -d $1     ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ---------------------------------------------------------------------------
# Optional: if fzf is available, use it (graceful degradation)
# ---------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
  _fzf_history() {
    BUFFER=$(fc -rl 1 | fzf --no-sort +m --tac | sed 's/^ *[0-9]* *//')
    CURSOR=${#BUFFER}
    zle clear-screen
  }
  zle -N _fzf_history
  bindkey "^R" _fzf_history
fi

# ---------------------------------------------------------------------------
# Local overrides (machine-specific, not tracked in dotfiles)
# ---------------------------------------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# ^ Also loaded at the top so PATH is available early;
#   loaded again here so alias/bindkey overrides take effect last
