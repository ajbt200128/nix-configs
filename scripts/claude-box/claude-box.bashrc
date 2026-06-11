# --- claude-box-bashrc ---
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.config/claude-box/env" ] && source "$HOME/.config/claude-box/env"
if [[ $- == *i* ]] && [[ -z "${TMUX:-}" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
  claude-tmux
fi
# --- end claude-box-bashrc ---
