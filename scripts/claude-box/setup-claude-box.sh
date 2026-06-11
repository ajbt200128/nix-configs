#!/usr/bin/env bash
# Provision a fresh Ubuntu box into a "claude-box": Claude Code + tmux auto-attach
# + latest Nix (flakes). Idempotent. Run as the login user (e.g. ubuntu) on the box:
#
#   ssh -i ~/.ssh/aws_sandbox_ec2 ubuntu@<box> 'bash -s' < setup-claude-box.sh
#
# Then drop your key into ~/.config/claude-box/env and `start-claude`.
# Canonical copies of the three installed files live alongside this script
# (claude-tmux, start-claude, claude-box.bashrc) — keep them in sync if edited.
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.config/claude-box"

echo "### [1/5] apt deps ###"
sudo NEEDRESTART_MODE=a DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo NEEDRESTART_MODE=a DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  xz-utils curl ca-certificates git tmux rsync >/dev/null && echo "apt ok"

# First-party installers are fetched to a file (not piped straight into a shell)
# so they can be inspected before running.
run_installer() {  # url, then args passed to the downloaded script
  local url="$1"; shift
  local f; f="$(mktemp)"
  curl -fsSL "$url" -o "$f"
  sh "$f" "$@"
  rm -f "$f"
}

echo "### [2/5] Claude Code (native installer -> ~/.local/bin/claude) ###"
command -v claude >/dev/null || run_installer https://claude.ai/install.sh
command -v claude && claude --version 2>/dev/null || echo "(claude version check deferred to fresh shell)"

echo "### [3/5] claude-box scripts ###"
cat > "$HOME/.local/bin/claude-tmux" <<'CT'
#!/usr/bin/env bash
set -uo pipefail
export PATH="$HOME/.local/bin:$PATH"
if ! tmux has-session -t claude 2>/dev/null; then
  source "$HOME/.config/claude-box/env" 2>/dev/null || true
  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    tmux new-session -d -s claude "start-claude; echo '[claude exited — press enter for a shell]'; exec bash"
  else
    tmux new-session -d -s claude
    tmux send-keys -t claude 'echo ">> No API key yet. Put it in ~/.config/claude-box/env then run: start-claude"' C-m
  fi
fi
exec tmux attach -t claude
CT
chmod +x "$HOME/.local/bin/claude-tmux"

cat > "$HOME/.local/bin/start-claude" <<'SC'
#!/usr/bin/env bash
set -uo pipefail
[ -f "$HOME/.config/claude-box/env" ] && source "$HOME/.config/claude-box/env"
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "!! ANTHROPIC_API_KEY not set — edit ~/.config/claude-box/env, then re-run start-claude." >&2
  exec bash
fi
cd "$HOME/semgrep-proprietary"
exec claude --dangerously-skip-permissions "$@"
SC
chmod +x "$HOME/.local/bin/start-claude"

# Key is intentionally NOT baked in — left blank for the operator to fill.
if [ ! -f "$HOME/.config/claude-box/env" ]; then
  cat > "$HOME/.config/claude-box/env" <<'ENVF'
# claude-box environment — sourced by start-claude / claude-tmux
# Add your key below (no quotes needed), then run: start-claude
# export ANTHROPIC_API_KEY=sk-ant-...
ENVF
  chmod 600 "$HOME/.config/claude-box/env"
fi
echo "scripts installed"

echo "### [4/5] .bashrc auto-attach block ###"
if ! grep -q 'claude-box-bashrc' "$HOME/.bashrc" 2>/dev/null; then
cat >> "$HOME/.bashrc" <<'BRC'

# --- claude-box-bashrc ---
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.config/claude-box/env" ] && source "$HOME/.config/claude-box/env"
if [[ $- == *i* ]] && [[ -z "${TMUX:-}" ]] && [[ -n "${SSH_CONNECTION:-}" ]]; then
  claude-tmux
fi
# --- end claude-box-bashrc ---
BRC
  echo "bashrc block added"
else
  echo "bashrc block already present"
fi

echo "### [5/5] Nix (Determinate installer, latest, flakes on) ###"
if ! command -v nix >/dev/null && [ ! -e /nix/var/nix ]; then
  run_installer https://install.determinate.systems/nix install --no-confirm
fi
( . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null; nix --version 2>/dev/null ) \
  || echo "(nix available in a fresh shell)"

echo "### DONE ###"
