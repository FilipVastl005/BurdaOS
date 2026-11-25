# ==============================================================================
# BurdaOS — ~/.bashrc (/etc/skel/.bashrc)
# ==============================================================================

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Load system-wide bash completion if present
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# Clean terminal prompt
PS1='\[\033[1;34m\][BurdaOS]\[\033[0m\] \[\033[0;36m\]\u@\h\[\033[0m\]:\[\033[1;37m\]\w\[\033[0m\]\$ '

# Useful teaching aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias hwinfo-brief='inxi -Fazy'

# Display custom system telemetry once per interactive terminal open
if [[ -z "${BURDAOS_FETCH_SHOWN:-}" ]]; then
    if command -v fastfetch >/dev/null 2>&1; then
        export BURDAOS_FETCH_SHOWN=1
        fastfetch
    elif command -v neofetch >/dev/null 2>&1; then
        export BURDAOS_FETCH_SHOWN=1
        neofetch
    fi
fi

# Source Passive-Aggressive Shell Engine (strictly stderr, safe stdout)
if [[ -r "${HOME}/.config/burdaos/roasts.sh" ]]; then
    source "${HOME}/.config/burdaos/roasts.sh"
fi
