# ==============================================================================
# BurdaOS — Passive-Aggressive Shell Engine
# Path: /etc/skel/.config/burdaos/roasts.sh
#
# CRITICAL USABILITY GUARANTEE:
#   1. ALL passive-aggressive messages are strictly written to stderr (>&2).
#   2. Standard output (stdout) and piping are NEVER polluted.
#   3. Every wrapped command runs the real binary (`command <cmd> "$@"`) and
#      preserves its exact original exit code.
#
# Modes:
#   BURDAOS_ESCALATION_MODE="random"  (default) - picks a random tier per trigger
#   BURDAOS_ESCALATION_MODE="tiered"            - escalates Tier 1 -> Tier 5
# ==============================================================================

# Prevent double-sourcing in the same shell unless explicitly forced
if [[ -n "${_BURDAOS_ROASTS_LOADED:-}" && -z "${BURDAOS_FORCE_RELOAD:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_BURDAOS_ROASTS_LOADED=1

: "${BURDAOS_ESCALATION_MODE:=random}"
: "${BURDAOS_ROASTS_ENABLED:=1}"

FAIL_COUNT=0
_BURDAOS_HANDLED=0
declare -gA _BURDAOS_TIER_IDX=()

# ------------------------------------------------------------------------------
# All 14 Categories x 5 Tiers — Pure Passive-Aggressive Sarcasm
# ------------------------------------------------------------------------------

# 1. Execution & Syntax — Exit Code 1 (General Error / Uncaught Failure)
ROAST_EXIT_1=(
    "That didn't work. No, it's fine, we can just pretend you meant to do that."
    "Exit code 1. Honestly, at this point it would be weirder if it actually succeeded."
    "Another failed command. Reading the --help flag was always optional, I suppose."
    "Impressive consistency. Wrong again, yet you keep pressing Enter with such confidence."
    "You know, most people eventually stop guessing and check what went wrong. Not you, clearly."
)

# 2. Execution & Syntax — Exit Code 2 (Misuse of Built-in / Syntax Error)
ROAST_EXIT_2=(
    "Invalid syntax. The flags aren't decorative suggestions."
    "Oh, inventing your own bash syntax now? Very brave. Still completely wrong, though."
    "It's okay, brackets and quotes are notoriously tricky when you just eyeball them."
    "Exit code 2. You literally just had to type valid arguments, and yet here we are."
    "At this rate, maybe stick to clicking icons. The shell is clearly hurting your feelings."
)

# 3. Execution & Permissions — Exit Code 126 (Command Cannot Execute / Permission Denied)
ROAST_EXIT_126=(
    "Permission denied. Almost like chmod exists for a reason."
    "You can't just run random files without execute bits, no matter how nicely you ask."
    "Still not executable. Try wishing harder, or maybe just check ls -l."
    "It's adorable that you expected the kernel to just wave you through without permissions."
    "Basic Unix permissions are undefeated today. Zero for one."
)

# 4. Execution & Syntax — Exit Code 127 (Command Not Found)
ROAST_EXIT_127=(
    "Command not found. Take your time—the keyboard isn't going anywhere."
    "Making up commands doesn't actually create the binaries. Worth a shot, I guess."
    "Sure, let's just mash keys and hope the PATH figures out what you meant."
    "Tab-completion is literally free and built right in, just so you know."
    "Another nonexistent command. Have you considered looking at the screen while typing?"
)

# 5. Process & Signals — Exit Code 130 / SIGINT (Ctrl+C / Interrupted)
ROAST_SIGINT=(
    "Quitting halfway through? Yeah, finishing things is overrated anyway."
    "Ctrl+C already? It barely even started, but sure, give up."
    "Nothing says 'I definitely knew what that command would do' like panicking with Ctrl+C."
    "Oh, suddenly in a rush? Funny how you only hurry after realizing you messed up."
    "Interrupted again. Attention span looking roughly as short as your patience."
)

# 6. Memory & Hardware — Exit Code 137 / SIGKILL (OOM Killer / Killed)
ROAST_EXIT_137=(
    "Killed by the kernel. You had 8GB of RAM and somehow still got greedy."
    "SIGKILL. Even the OS got tired of watching whatever your script was doing."
    "Out of memory. Truly inspiring how fast you turned 8 gigabytes into nothing."
    "The OOM killer had to step in because clearly nobody else was supervising that process."
    "Force-killed. Next time try not to treat RAM like an all-you-can-eat buffet."
)

# 7. Memory & Hardware — Exit Code 139 / SIGSEGV (Segmentation Fault)
ROAST_EXIT_139=(
    "Segmentation fault. Pointer arithmetic really isn't for everyone."
    "You dereferenced something that doesn't exist. Honestly, relatable."
    "SIGSEGV. Touching memory you don't own—classic."
    "Memory went out of bounds and crashed. Look on the bright side: at least it was fast."
    "Core dumped. Even C gave up trying to make sense of what you wrote."
)

# 8. Process & Signals — Exit Code 143 / SIGTERM (Terminated by Supervisor)
ROAST_SIGTERM=(
    "Terminated. At least something around here knows when to stop."
    "SIGTERM received. Honestly, it was putting everyone else to sleep anyway."
    "Shutting that process down cleanly—which is more grace than your commands usually get."
    "Stopped before it could embarrass itself any further."
    "Killed politely. You're welcome."
)

# 9. Session & Flow Control — Consecutive Failures (Fail Streak >= 3)
ROAST_STREAK=(
    "Three errors in a row. Deep breath. Maybe look at the error output this time?"
    "A hat-trick of failures. Truly a masterclass in stubbornness."
    "Still failing. Doing the exact same thing faster won't make it work, by the way."
    "At this point I'm not even mad, just genuinely curious how long you can keep this streak alive."
    "Multiple consecutive failures. Have you considered turning yourself off and back on again?"
)

# 10. Scripting & Traps — Pipeline Error (set -e / pipefail)
ROAST_PIPELINE=(
    "Your pipe broke halfway through. Garbage in, nothing out."
    "Piping broken output into another command won't magically fix the first one."
    "Upstream failed and took the whole pipeline down with it. Surprise."
    "Chaining commands together only works when at least one of them actually works."
    "Nice pipeline. Too bad the very first part fell apart immediately."
)

# 11. Session & Power — Sudo / Privileged Failure (Exit != 0 on Sudo)
ROAST_SUDO=(
    "Failed with sudo. Honestly, it's probably safer for everyone that you don't get root."
    "Even with root privileges you managed to break it. That takes real talent."
    "Sudo rejected you. Maybe the system has better survival instincts than we thought."
    "Asking for admin rights and immediately faceplanting. Love the energy."
    "No root for you. Try proving you can handle regular user commands first."
)

# 12. Session & Exit — Premature / Dirty Shell Exit (trap EXIT)
ROAST_DIRTY_EXIT=(
    "Leaving on a non-zero exit? Sure, just walk away and pretend it never happened."
    "Closing the terminal won't undo the broken command you just ran, just FYI."
    "Running away in an error state. Very graceful."
    "Dirty exit. Leaving a mess behind like usual—have a great day anyway."
    "Oh, rage-quitting the shell now? Take care."
)

# 13. Environment & Variables — Unbound Variable (set -u / nounset)
ROAST_NOUNSET=(
    "Unbound variable. Checking if something actually exists before using it is overrated, right?"
    "That variable is completely empty, much like the thought behind referencing it."
    "set -u caught you guessing variable names again. Unfortunate."
    "Referencing variables you never defined. Bold strategy. Didn't pay off."
    "Null, undefined, and still somehow my problem. Great job."
)

# 14. Process & Resource — Fork Bomb / PID Exhaustion (Resource Limit)
ROAST_ULIMIT=(
    "Easy on the forks there, champ. No need to suffocate your own VM."
    "Spawning hundreds of useless processes won't make the computer think faster."
    "PID limit reached. Congratulations, you managed to annoy even the process table."
    "Forking out of control. Did you forget a wait condition or just want to watch it burn?"
    "Process spawning throttled. Calm down before you crash your own desktop."
)

# ------------------------------------------------------------------------------
# Core Roast Emitter (Strictly stderr, Preserves Exit Status)
# ------------------------------------------------------------------------------
_burdaos_roast() {
    [[ "${BURDAOS_ROASTS_ENABLED:-1}" == "1" ]] || return 0
    local array_name="$1"
    local -n arr_ref="$array_name"
    local count="${#arr_ref[@]}"
    (( count > 0 )) || return 0

    local idx=0
    if [[ "${BURDAOS_ESCALATION_MODE}" == "tiered" ]]; then
        idx="${_BURDAOS_TIER_IDX[$array_name]:-0}"
        if (( idx >= count )); then
            idx=$(( count - 1 ))
        fi
        _BURDAOS_TIER_IDX[$array_name]=$(( idx + 1 ))
    else
        idx=$(( RANDOM % count ))
    fi

    local BURDA_MSG="${arr_ref[$idx]}"
    if [[ -t 2 ]]; then
        printf '\033[1;38;5;203m[BurdaOS]\033[0m \033[38;5;250m%s\033[0m\n' "$BURDA_MSG" >&2
    else
        printf '[BurdaOS] %s\n' "$BURDA_MSG" >&2
    fi
}

# ------------------------------------------------------------------------------
# Hook 1: Command Not Found (Exit Code 127)
# ------------------------------------------------------------------------------
command_not_found_handle() {
    local cmd="${1:-}"
    printf 'bash: %s: command not found\n' "$cmd" >&2
    _burdaos_roast ROAST_EXIT_127
    _BURDAOS_HANDLED=1
    return 127
}

# ------------------------------------------------------------------------------
# Hook 2: Sudo Wrapper (Preserves arguments, stdout, and exact exit code)
# ------------------------------------------------------------------------------
sudo() {
    command sudo "$@"
    local rc=$?
    if (( rc != 0 )); then
        _burdaos_roast ROAST_SUDO
        _BURDAOS_HANDLED=1
    fi
    return "$rc"
}

# ------------------------------------------------------------------------------
# Hook 3: Signal & Exit Traps (SIGINT, SIGTERM, EXIT, ERR)
# ------------------------------------------------------------------------------
_burdaos_on_sigint() {
    _burdaos_roast ROAST_SIGINT
    _BURDAOS_HANDLED=1
    return 130
}

_burdaos_on_sigterm() {
    _burdaos_roast ROAST_SIGTERM
    _BURDAOS_HANDLED=1
    return 143
}

_burdaos_on_exit() {
    local rc=$?
    if (( rc != 0 )); then
        if [[ $- == *u* && ( $rc -eq 1 || $rc -eq 127 ) ]]; then
            _burdaos_roast ROAST_NOUNSET
        fi
        _burdaos_roast ROAST_DIRTY_EXIT
    fi
    return "$rc"
}

# ------------------------------------------------------------------------------
# Hook 4: Pipeline, Exit Code, Resource Limit & Streak Evaluator
# ------------------------------------------------------------------------------
_burdaos_evaluate_status() {
    local rc="${1:-$?}"
    local -a pipe_rc=()
    if (( ${#_BURDAOS_LAST_PIPESTATUS[@]} > 0 )); then
        pipe_rc=("${_BURDAOS_LAST_PIPESTATUS[@]}")
        _BURDAOS_LAST_PIPESTATUS=()
    fi

    # Track consecutive failure streak
    if (( rc == 0 )); then
        FAIL_COUNT=0
        _BURDAOS_HANDLED=0
        return 0
    fi

    (( FAIL_COUNT++ ))

    # If a dedicated hook (command_not_found_handle, sudo, SIGINT, SIGTERM)
    # already emitted the primary roast for this command, only check streak.
    if (( _BURDAOS_HANDLED == 1 )); then
        _BURDAOS_HANDLED=0
        if (( FAIL_COUNT >= 3 )); then
            _burdaos_roast ROAST_STREAK
        fi
        return "$rc"
    fi

    # Detect multi-stage pipeline failure (pipefail)
    local is_pipe_fail=0
    if (( ${#pipe_rc[@]} > 1 )); then
        local stage_rc
        for stage_rc in "${pipe_rc[@]}"; do
            if (( stage_rc != 0 )); then
                is_pipe_fail=1
                break
            fi
        done
    fi

    # Detect active nounset violation (when set -u is enabled)
    if [[ $- == *u* && ( $rc -eq 1 || $rc -eq 127 ) ]]; then
        _burdaos_roast ROAST_NOUNSET
    elif (( is_pipe_fail == 1 )); then
        _burdaos_roast ROAST_PIPELINE
    else
        case "$rc" in
            1)   _burdaos_roast ROAST_EXIT_1 ;;
            2)   _burdaos_roast ROAST_EXIT_2 ;;
            126) _burdaos_roast ROAST_EXIT_126 ;;
            127)
                # In interactive mode, command_not_found_handle (subshell) already
                # roasted 127; only roast here in non-interactive shells.
                [[ $- != *i* ]] && _burdaos_roast ROAST_EXIT_127
                ;;
            128) _burdaos_roast ROAST_ULIMIT ;;
            130) _burdaos_roast ROAST_SIGINT ;;
            137) _burdaos_roast ROAST_EXIT_137 ;;
            139) _burdaos_roast ROAST_EXIT_139 ;;
            143) _burdaos_roast ROAST_SIGTERM ;;
            254) _burdaos_roast ROAST_ULIMIT ;;
            *)   _burdaos_roast ROAST_EXIT_1 ;;
        esac
    fi

    # Check consecutive failure streak >= 3
    if (( FAIL_COUNT >= 3 )); then
        _burdaos_roast ROAST_STREAK
    fi

    return "$rc"
}

# ------------------------------------------------------------------------------
# Optional Strict Mode Helpers (for testing set -u / set -e without breaking
# interactive bash-completion by default)
# ------------------------------------------------------------------------------
burdaos-strict-on() {
    set -e -u -o pipefail
    trap '_burdaos_prompt_entry' ERR
    printf '[BurdaOS] Strict mode enabled (set -euo pipefail). Good luck.\n' >&2
}

burdaos-strict-off() {
    set +e +u
    set -o pipefail
    trap - ERR
    printf '[BurdaOS] Strict mode disabled. Back to safety wheels.\n' >&2
}

# ------------------------------------------------------------------------------
# Initialize Shell Safeguards, Traps & Resource Limits
# ------------------------------------------------------------------------------
set -o pipefail
# Apply fork-bomb guardrail (ulimit -u 1000) only when current thread count is
# safely below the cap so sourcing in a busy multi-session host never starves.
_burdaos_cur_tasks=$(ps -eL -u "${USER:-$(id -un)}" --no-headers 2>/dev/null | wc -l || echo 0)
if [[ "$_burdaos_cur_tasks" =~ ^[0-9]+$ ]] && (( _burdaos_cur_tasks < 850 )); then
    ulimit -u 1000 2>/dev/null || true
fi
unset _burdaos_cur_tasks

trap '_burdaos_on_sigint' SIGINT
trap '_burdaos_on_sigterm' SIGTERM
trap '_burdaos_on_exit' EXIT

_burdaos_prompt_entry() {
    _BURDAOS_LAST_PIPESTATUS=("${PIPESTATUS[@]}")
    local rc=0 s
    for s in "${_BURDAOS_LAST_PIPESTATUS[@]}"; do
        (( s != 0 )) && rc="$s"
    done
    _burdaos_evaluate_status "$rc"
}

if [[ $- == *i* ]]; then
    # Prepend _burdaos_prompt_entry so it always captures the user's true PIPESTATUS
    # and $? before any other PROMPT_COMMAND hooks mutate them.
    if [[ -z "${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="_burdaos_prompt_entry"
    elif [[ "$PROMPT_COMMAND" != *"_burdaos_prompt_entry"* ]]; then
        PROMPT_COMMAND="_burdaos_prompt_entry; ${PROMPT_COMMAND}"
    fi
else
    # Non-interactive script / strict trap support
    trap '_burdaos_prompt_entry' ERR
fi
