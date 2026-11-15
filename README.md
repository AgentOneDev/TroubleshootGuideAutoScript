# Cloud Backend Troubleshooting Guide
Troubleshooting guide for cloud Linux servers: SSH, networking, DNS, TLS, server health, scripting and deployments. Opens in your browser.

# Install
```bash
git clone https://github.com/<your-username>/backend-cloud-troubleshoot-guide.git
cd backend-cloud-troubleshoot-guide
chmod +x install.sh backend-cloud-troubleshoot-guide.sh
./install.sh
```
Copies the script to `~/.local/bin/guide`. No sudo, no downloads, no shell config edits.

If `~/.local/bin` isn't on your PATH, add this to `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

Re-run `./install.sh` after updating the repo.

# Use
```bash
guide
```

| Option | Action |
|---|---|
| `-n`, `--no-open` | Save the page without opening it |
| `-o`, `--out FILE` | Save to `FILE` |
| `-f`, `--force` | Overwrite `FILE` |
| `-v`, `--version` | Show version |
| `-h`, `--help` | Show help |

Without installing: `./backend-cloud-troubleshoot-guide.sh`

# Installer options
| Option | Action |
|---|---|
| `-d`, `--dir DIR` | Install to `DIR/guide` |
| `-f`, `--force` | Replace an existing `guide` that isn't this one |
| `-u`, `--uninstall` | Remove `guide` |

# Uninstall — deletes a file
```bash
./install.sh --uninstall
```
Permanently deletes `~/.local/bin/guide`. Only deletes it if it's this guide.

# Requirements
- Bash: Linux, macOS, WSL or Git Bash (not PowerShell or Command Prompt)
- A web browser
