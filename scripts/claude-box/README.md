# claude-box scripts

The setup that auto-starts Claude Code inside a persistent `tmux` session when you
SSH into a dev box. Used by **claude-box** (`172.16.1.23`) and **claude-box-mini**
(`172.16.1.24`) — both Ubuntu, both reached over tailscale (`172.16.0.0/23`), same
key (`~/.ssh/aws_sandbox_ec2`).

## Files

| File | Installed to | Purpose |
|------|--------------|---------|
| `claude-box.bashrc` | appended to `~/.bashrc` | On an interactive SSH login (not already in tmux), runs `claude-tmux`. |
| `claude-tmux` | `~/.local/bin/claude-tmux` | Creates/attaches the `claude` tmux session; runs `start-claude` if a key is set, else prints a hint. |
| `start-claude` | `~/.local/bin/start-claude` | Sources the env, `cd`s to the repo, `exec claude --dangerously-skip-permissions`. |
| `setup-claude-box.sh` | — (run once on the box) | Installs Claude Code + tmux + the three files above + latest Nix (flakes). Idempotent. |

The API key is **not** stored here. It lives only in `~/.config/claude-box/env` on the
box (`export ANTHROPIC_API_KEY=...`, mode 600); until you set it, `claude-tmux`/`start-claude`
print a hint instead of failing.

## Provision a new box

```bash
ssh -i ~/.ssh/aws_sandbox_ec2 ubuntu@<box-ip> 'bash -s' < setup-claude-box.sh
```

## Connect / start / stop / sync

From the nix-darwin shell (see `home.nix`):

- `claudebox` / `claudeboxmini` — SSH in (auto-attaches the `claude` tmux session)
- `startclaudebox` / `startclaudeboxmini` — start the instance and wait for sshd
- `stopclaudebox` / `stopclaudeboxmini` — stop the instance
- `pushrepo <claudebox|mini>` — rsync the current repo up to `<host>:~/<dirname>`
- `pullrepo <claudebox|mini>` — rsync it back down
