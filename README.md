![Bash](https://img.shields.io/badge/Bash-script-4EAA25?logo=gnubash&logoColor=white)

# Cloud Backend Troubleshooting Guide
An automated Bash (Shell Script) troubleshooting guide for working on cloud linux servers, with a focus on networking: SSH sessions that won't connect, pings that fail, traceroutes that stop halfway, tunnels, firewalls and DNS, plus the server, scripting and deployment problems that come with them.

# Run it
git clone https://github.com/<your-username>/cloud-backend-troubleshooting.git

cd cloud-backend-troubleshooting

chmod +x backend-cloud-troubleshoot-guide.sh

./backend-cloud-troubleshoot-guide.sh

# What the script does
Writes the embedded HTML guide to a new temporary folder
Opens it with your system's browser opener: `xdg-open` (Linux), `open` (macOS), `wslview`/`explorer.exe` (WSL) or `start` (Git Bash).

It makes no network requests, installs nothing, doesn't need `sudo`, and won't overwrite an existing file unless you pass `--force`. The temp file stays in `$TMPDIR` (usually `/tmp`), which your OS clears on its own schedule.

# Topics
SSH & Remote Access: connecting, keys & authentication, sessions, tunnels & bastions, file transfer
Network Diagnostics: ping, traceroute & mtr, interfaces & routing, ports, firewalls & security groups, packet capture, throughput & MTU
Name Resolution & Web: DNS, TLS & certificates, HTTP & APIs, load balancers & proxies
Server Health: disk, CPU & memory, processes, services & logs, time
Files & Access: permissions, files & search, configuration & environment
Scripting & Automation: Bash, scheduled jobs, JSON & text processing
Application Ops: databases & caches, deployments & releases

# Requirements
Bash installed (the macOS default works) & a desktop browser(working). 
