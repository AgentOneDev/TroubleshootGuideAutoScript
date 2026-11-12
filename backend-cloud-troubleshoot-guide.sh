#!/usr/bin/env bash

#  This script saves my troubleshooting guide as an HTML file
#  and then opens it in your web browser.
#
#  How to run it:
#  Look at Readme.md for pointers on how to download and run this script.
#
#  The script does not download or install anything,
#  and it never needs sudo.

set -euo pipefail

VERSION="1.0.0"
OUTPUT_FILE=""        # empty means "make a temporary file for me"
OPEN_BROWSER="yes"    # "yes" or "no"
ALLOW_OVERWRITE="no"  # "yes" or "no"

# Function: show_help
# Prints the help message.
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Opens the Cloud Backend Troubleshooting guide in your default browser."
  echo ""
  echo "Options:"
  echo "  -o, --out FILE   Save the HTML page to FILE instead of a temporary file"
  echo "  -f, --force      Allow --out to replace a file that already exists"
  echo "  -n, --no-open    Save the page and print where it is, but don't open a browser"
  echo "  -v, --version    Show the version number"
  echo "  -h, --help       Show this help message"
}

# Function: open_in_browser
# Opens a file in the default browser.
# Each operating system uses a different command for this, so first I check which system we're on.
open_in_browser() {
  local file_to_open="$1"
  local system_name
  system_name="$(uname -s)"   # prints Linux, Darwin (macOS), MINGW64 (Git Bash) ...

  # WSL (Linux running inside Windows) says "Linux", so check for it first.
  # Its /proc/version file contains the word "microsoft".
  if grep -qi "microsoft" /proc/version 2>/dev/null; then
    if command -v wslview > /dev/null 2>&1; then
      wslview "$file_to_open"
    else
      # explorer.exe needs a Windows-style path, and wslpath converts it
      explorer.exe "$(wslpath -w "$file_to_open")" || true
    fi

  # macOS
  elif [[ "$system_name" == "Darwin" ]]; then
    open "$file_to_open"

  # Git Bash or Cygwin on Windows
  elif [[ "$system_name" == MINGW* || "$system_name" == MSYS* || "$system_name" == CYGWIN* ]]; then
    start "" "$file_to_open"

  # Normal Linux desktop
  elif command -v xdg-open > /dev/null 2>&1; then
    # The & runs it in the background so the terminal doesn't wait for the browser
    xdg-open "$file_to_open" > /dev/null 2>&1 &

  # Some systems set a BROWSER variable instead
  elif [[ -n "${BROWSER:-}" ]]; then
    "$BROWSER" "$file_to_open" > /dev/null 2>&1 &

  # Nothing worked
  else
    echo "Could not find a way to open your browser."
    echo "Open this file yourself: $file_to_open"
    return 1
  fi

  echo "Opening in your default browser..."
}

# Function: main
# The main steps of the script. It is called on the very last
# line of this file, after write_html (the HTML page) has been
# defined, so the long HTML doesn't get in the way of the code.
main() {

  # STEP 1: Read the options the user typed.
  # "$#" is how many arguments are left, and "$1" is the current one.
  # "shift" removes the current argument so the loop moves to the next one.
  while [[ $# -gt 0 ]]; do

    if [[ "$1" == "-o" || "$1" == "--out" ]]; then
      if [[ $# -lt 2 ]]; then
        echo "Error: --out needs a file name, for example: --out guide.html"
        exit 1
      fi
      OUTPUT_FILE="$2"
      shift 2   # remove both "--out" and the file name

    elif [[ "$1" == "-f" || "$1" == "--force" ]]; then
      ALLOW_OVERWRITE="yes"
      shift

    elif [[ "$1" == "-n" || "$1" == "--no-open" ]]; then
      OPEN_BROWSER="no"
      shift

    elif [[ "$1" == "-v" || "$1" == "--version" ]]; then
      echo "Cloud Backend Troubleshooting Guide, version $VERSION"
      exit 0

    elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
      show_help
      exit 0

    else
      echo "Error: unknown option: $1"
      echo ""
      show_help
      exit 1
    fi

  done


  # STEP 2: Decide where to save the page.
  if [[ -z "$OUTPUT_FILE" ]]; then
    # No --out given, so make a new, empty temporary folder
    # (mktemp -d picks a unique name) and save the page inside it.
    temp_folder="$(mktemp -d)"
    OUTPUT_FILE="$temp_folder/cloud-backend-troubleshooting.html"

  elif [[ -e "$OUTPUT_FILE" && "$ALLOW_OVERWRITE" == "no" ]]; then
    # Don't replace someone's file by accident.
    echo "Error: $OUTPUT_FILE already exists."
    echo "Use --force if you want to replace it."
    exit 1
  fi


  # STEP 3: Save the HTML page to the file.
  write_html > "$OUTPUT_FILE"


  # STEP 4: Turn the file name into a full path (starting with /),
  # because the browser needs the full path to find it.
  if [[ "$OUTPUT_FILE" != /* ]]; then
    OUTPUT_FILE="$(pwd)/$OUTPUT_FILE"
  fi

  echo "Guide saved to: $OUTPUT_FILE"


  # STEP 5: Open it in the browser, unless the user said --no-open.
  if [[ "$OPEN_BROWSER" == "yes" ]]; then
    open_in_browser "$OUTPUT_FILE"
  fi
}

#  Everything below is the HTML page itself.
#  The function write_html just prints it with "cat".
#  The quotes around 'HTML_EOF' tell bash to print the text
#  exactly as written, without changing any $ or ` in it.
write_html() {
cat <<'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cloud Backend Troubleshooting</title>
<style>
:root{
  --bg:#121417; --panel:#181b1f; --line:#262a30; --line2:#2f343b;
  --ink:#e4e6e9; --ink2:#aab1b9; --muted:#7c848d; --g:#3cc8b0; --gsoft:rgba(60,200,176,.08);
  --code:#d8dde2; --codebg:#0f1114;
  --mono:ui-monospace,SFMono-Regular,"JetBrains Mono",Menlo,Consolas,"Liberation Mono",monospace;
  --sans:Inter,system-ui,-apple-system,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
}
*{box-sizing:border-box}
html{scroll-behavior:smooth}
html,body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.65 var(--sans);-webkit-font-smoothing:antialiased}
a{color:var(--g)}
.hero{border-bottom:1px solid var(--line)}
.hero-in{max-width:1180px;margin:0 auto;padding:56px 28px 40px}
.eyebrow{font:600 12px/1 var(--sans);letter-spacing:.12em;text-transform:uppercase;color:var(--g);margin:0 0 14px}
h1{font:700 38px/1.15 var(--sans);letter-spacing:-.015em;margin:0 0 14px;color:var(--ink)}
.lede{font-size:16.5px;color:var(--ink2);max-width:760px;margin:0 0 28px}
.stats{display:flex;gap:40px;flex-wrap:wrap;margin:0}
.stat b{display:block;font:600 26px/1 var(--sans);color:var(--ink)}
.stat span{display:block;margin-top:6px;font-size:12px;color:var(--muted);letter-spacing:.04em}
.bar{position:sticky;top:0;z-index:20;background:var(--bg);border-bottom:1px solid var(--line)}
.bar-in{max-width:1180px;margin:0 auto;padding:12px 28px;display:flex;gap:14px;align-items:center}
#q{flex:1;border:1px solid var(--line2);border-radius:8px;padding:10px 14px;font:14.5px var(--sans);color:var(--ink);background:var(--panel)}
#q::placeholder{color:#666e77}
#q:focus{outline:none;border-color:var(--g)}
#count{font:12px var(--mono);color:var(--muted);white-space:nowrap}
kbd{font:11px var(--mono);border:1px solid var(--line2);border-radius:4px;padding:1px 6px;color:var(--muted)}
.wrap{max-width:1180px;margin:0 auto;display:grid;grid-template-columns:250px 1fr;gap:40px;padding:0 28px}
nav{position:sticky;top:66px;align-self:start;max-height:calc(100vh - 80px);overflow:auto;padding:24px 4px 40px 0;scrollbar-width:thin;scrollbar-color:var(--line2) transparent}
nav .tools{display:flex;gap:14px;margin:0 0 14px}
nav .tools button{background:none;border:none;padding:0;color:var(--muted);font:12.5px var(--sans);cursor:pointer}
nav .tools button:hover{color:var(--ink)}
nav details.grp{border-bottom:1px solid var(--line);padding:4px 0}
nav summary{list-style:none;cursor:pointer;display:flex;align-items:center;gap:8px;user-select:none}
nav summary::-webkit-details-marker{display:none}
nav summary::after{content:"";width:6px;height:6px;border-right:1.5px solid currentColor;border-bottom:1.5px solid currentColor;transform:rotate(-45deg);transition:transform .15s;flex:none;margin-right:4px;opacity:.6}
nav details[open]>summary::after{transform:rotate(45deg)}
nav details.grp>summary{font:600 12px var(--sans);letter-spacing:.08em;text-transform:uppercase;color:var(--ink2);padding:8px 0}
nav details.grp[open]>summary{color:var(--g)}
nav details.topic>summary{font-size:14px;color:var(--ink2);padding:4px 0 4px 4px}
nav details.topic>summary:hover,nav details.topic[open]>summary{color:var(--ink)}
nav summary .c{font:11px var(--mono);color:var(--muted);margin-left:auto}
nav ul{list-style:none;margin:2px 0 8px 6px;padding:0 0 0 10px;border-left:1px solid var(--line2)}
nav li a{display:block;text-decoration:none;color:var(--muted);font-size:13px;line-height:1.4;padding:3px 0 3px 6px}
nav li a:hover{color:var(--g)}
nav .hide{display:none}
main{padding:28px 0 100px;min-width:0}
.sec{margin:0 0 52px;scroll-margin-top:80px}
.sec.hide{display:none}
.sec-head{display:flex;align-items:baseline;gap:12px;margin:0 0 6px;padding:0 0 8px;border-bottom:1px solid var(--line)}
.sec h2{font:650 22px/1.25 var(--sans);margin:0;color:var(--g)}
.sec .tag{margin-left:auto;font-size:12px;color:var(--muted)}
.card{scroll-margin-top:80px;padding:20px 0 22px;border-bottom:1px solid var(--line)}
.card:last-child{border-bottom:none}
.card.hide{display:none}
.card h3{font:600 16.5px/1.4 var(--sans);margin:0 0 6px;color:var(--ink);display:flex;gap:12px;align-items:baseline}
.card h3 .n{font:12px var(--mono);color:var(--g);min-width:30px}
.why{margin:0 0 12px 42px;color:var(--ink2);font-size:14.5px}
.cmds{margin-left:42px;border:1px solid var(--line);border-radius:8px;overflow:hidden;background:var(--codebg)}
.row{display:grid;grid-template-columns:minmax(0,1.3fr) minmax(0,1fr);gap:18px;padding:8px 14px;border-top:1px solid var(--line);align-items:start}
.row:first-child{border-top:none}
.cmd{font:13px/1.6 var(--mono);color:var(--code);white-space:pre-wrap;word-break:break-word;cursor:pointer;position:relative}
.cmd:hover{color:var(--g)}
.cmd.copied::after{content:"copied";position:absolute;right:0;top:0;font:600 10px var(--sans);background:var(--g);color:#0f1114;padding:1px 6px;border-radius:4px}
.desc{font-size:13.5px;color:var(--ink2)}
pre.block{margin:0;padding:12px 14px;font:13px/1.6 var(--mono);color:var(--code);background:var(--codebg);overflow:auto;white-space:pre;border-top:1px solid var(--line);cursor:pointer}
.cmds pre.block:first-child{border-top:none}
.empty{display:none;color:var(--muted);padding:60px 0;text-align:center}
.unused,.unused2{display:none}
#top{position:fixed;right:22px;bottom:22px;width:38px;height:38px;border-radius:8px;border:1px solid var(--line2);background:var(--panel);color:var(--ink2);font:16px var(--sans);cursor:pointer;opacity:0;pointer-events:none;transition:opacity .2s}
#top.show{opacity:1;pointer-events:auto}
#navbtn{display:none;background:var(--panel);border:1px solid var(--line2);border-radius:8px;color:var(--ink);font:600 13px var(--sans);padding:9px 12px;cursor:pointer;white-space:nowrap}
#navbtn:hover{border-color:var(--g);color:var(--g)}
#scrim{display:none}
@media (max-width:1100px){.wrap{grid-template-columns:220px 1fr;gap:28px}.row{grid-template-columns:1fr;gap:2px}}
@media (max-width:820px){
  .wrap{grid-template-columns:1fr;gap:0}
  #navbtn{display:inline-block}
  nav{position:fixed;top:0;left:0;bottom:0;width:min(320px,86vw);max-height:none;height:100vh;z-index:40;background:var(--panel);border-right:1px solid var(--line2);padding:20px 16px 40px;transform:translateX(-105%);transition:transform .2s ease}
  body.nav-open nav{transform:none}
  body.nav-open #scrim{display:block;position:fixed;inset:0;z-index:30;background:rgba(0,0,0,.5)}
  h1{font-size:30px}.why,.cmds{margin-left:0}
  #count,kbd{display:none}
}
@media (prefers-reduced-motion:reduce){*{transition:none!important;scroll-behavior:auto!important}}
</style>
</head>
<body>
<section class="hero"><div class="hero-in">
  <h1>Cloud Backend Troubleshooting</h1>
  <p class="lede">I created this with a focus on networking: SSH sessions that won't connect, pings that fail, traceroutes that stop halfway, tunnels, firewalls and DNS, plus the server, scripting and deployment problems that come with them. Each entry attempts to explain the likely cause and lists the commands I could use to diagnose and fix it.</p>
  <div class="stats" id="stats"></div>
</div></section>
<div class="bar"><div class="bar-in">
  <button id="navbtn" type="button" aria-label="Open topics menu">☰ Topics</button>
  <input id="q" type="search" placeholder="Search a symptom, e.g. ssh timeout, no route to host, traceroute, MTU, disk full" autocomplete="off" spellcheck="false">
  <span id="count"></span> <kbd>/</kbd>
</div></div>
<div class="wrap">
  <nav id="nav"></nav>
  <main>
    <div id="grid"></div>
    <div class="empty" id="empty">Nothing matches that search. Try a shorter keyword like "dns", "port" or "memory".</div>
  </main>
</div>

<script type="text/plain" id="data">
@s sshconn | Connecting | SSH & Remote Access

@q SSH hangs, then "Connection timed out"
@w Packets to port 22 are being silently dropped: a cloud security group or network ACL, a host firewall, the wrong IP (private IP from outside the VPC), or the instance is down.
ssh -vvv -o ConnectTimeout=10 USER@HOST ::: Verbose output; a timeout before "Connection established" means a network problem, not an auth problem
nc -zv -w 5 HOST 22 ::: Raw TCP test of port 22 without SSH involved
getent hosts HOST ::: Are you connecting to the IP you think you are?
ip route get HOST_IP ::: Which interface and gateway your packets leave through
traceroute -T -p 22 HOST ::: TCP traceroute to port 22, showing where the path stops
curl -s https://ifconfig.me ::: Your public IP, to check against the security group's allowed source ranges

@q "Connection refused" on port 22
@w The host is reachable but nothing accepted the connection: sshd isn't running, it listens on a different port or address, or a firewall rule is actively rejecting you.
nc -zv HOST 22 ::: Confirms the refusal comes from port 22
systemctl status ssh   (RHEL: sshd) ::: On the server, via the cloud serial console: is sshd running?
sudo ss -tlnp | grep sshd ::: Which port and address sshd actually listens on
sudo sshd -T | grep -Ei '^(port|listenaddress)' ::: The effective sshd config after all includes
ssh -p 2222 USER@HOST ::: Connect if sshd was moved to a non-standard port

@q "No route to host"
@w Either there's no route to that network, or a firewall answered with ICMP host-unreachable (some REJECT rules do this). On the same subnet it can also mean ARP failed: the host is off or has a different IP.
ip route get HOST_IP ::: Is there a route, and via which gateway?
ip route | grep default ::: Is a default gateway configured at all?
ping -c 3 "$(ip route | awk '/default/ {print $3; exit}')" ::: Can you reach your own gateway?
ip neigh show HOST_IP ::: ARP entry for a host on the same subnet; FAILED or INCOMPLETE means it isn't answering

@q "Could not resolve hostname"
@w DNS lookup failed, or you used an alias that isn't defined in ~/.ssh/config.
getent hosts HOST ::: Does the name resolve on this machine?
ssh -G HOST | grep -E '^(hostname|user|port|identityfile|proxyjump) ' ::: The settings ssh will actually use for that name
grep -n -A5 -i '^Host .*HOST' ~/.ssh/config ::: Check for typos in your config alias
ssh USER@IP_ADDRESS ::: Bypass DNS to separate DNS problems from SSH problems

@q The login pauses for 10–30 seconds before the prompt
@w After authentication the server is waiting on something: a reverse DNS lookup of your IP (UseDNS), GSSAPI/Kerberos negotiation, or slow PAM or shell startup scripts.
ssh -vvv USER@HOST 2>&1 | ts '%.s' ::: Timestamp each debug line to find the pause (ts is in the moreutils package)
ssh -o GSSAPIAuthentication=no USER@HOST ::: If this is fast, GSSAPI was the cause
sudo sshd -T | grep -Ei 'usedns|gssapiauthentication' ::: Server settings that commonly cause delays
time ssh USER@HOST true ::: Total connection time, to compare before and after a change

@q SSH hangs at "expecting SSH2_MSG_KEX_ECDH_REPLY"
@w The TCP connection works but large packets never arrive. This is classic path-MTU trouble on VPNs, tunnels or overlay networks.
ping -M do -s 1472 -c 3 HOST ::: Send a full 1500-byte packet that must not fragment; failure points to an MTU problem
ping -M do -s 1372 -c 3 HOST ::: Lower the size until it works to find the usable MTU
tracepath HOST ::: Reports the path MTU hop by hop (no root needed)
ip link show | grep mtu ::: Your interfaces' MTU settings
sudo ip link set dev eth0 mtu 1400 ::: Temporarily lower the MTU to confirm the diagnosis (resets on reboot)

@q "kex_exchange_identification: Connection closed by remote host"
@w The server dropped the connection before the handshake: a tool like fail2ban banned your IP, MaxStartups is limiting new connections, or something other than sshd is on that port.
nc -v HOST 22 ::: A healthy sshd answers with a version banner such as "SSH-2.0-OpenSSH_9.6"
sudo fail2ban-client status sshd ::: On the server: is your IP in the banned list?
sudo journalctl -u ssh -u sshd --since "15 min ago" ::: The server's view of the dropped connection
sudo sshd -T | grep -i maxstartups ::: The limit on concurrent unauthenticated connections

@q "Too many authentication failures"
@w Your agent offered several keys and the server stopped after MaxAuthTries before reaching the right one.
ssh-add -l ::: How many keys the agent is offering
ssh -o IdentitiesOnly=yes -i ~/.ssh/KEY USER@HOST ::: Offer only the key you specify
@pre
# ~/.ssh/config
Host prod-*
    IdentityFile ~/.ssh/prod_ed25519
    IdentitiesOnly yes
@endpre

@q "no matching host key type found" or "no matching key exchange method found"
@w Modern OpenSSH has disabled old algorithms such as ssh-rsa with SHA-1, and old servers or network appliances only offer those.
ssh -Q kex  /  ssh -Q key ::: Algorithms your client supports
ssh -vv USER@HOST 2>&1 | grep -iE 'peer server|their offer' ::: What the server is offering
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa USER@HOST ::: Re-enable ssh-rsa for this one connection only

@q Which username does this cloud image use?
@w Default users depend on the image, and connecting as the wrong user looks exactly like a key problem.
ssh -i KEY.pem ubuntu@HOST ::: Ubuntu images
ssh -i KEY.pem ec2-user@HOST ::: Amazon Linux and many RHEL-family images on AWS
ssh -i KEY.pem admin@HOST   (Debian)  /  rocky@HOST  /  centos@HOST ::: Other common defaults
cat /etc/passwd | awk -F: '$3>=1000 {print $1}' ::: Once logged in, list the regular user accounts

@q The instance was fine but now won't accept SSH at all
@w Look at it from the cloud provider's side: the instance may be stuck at boot, out of disk, or have broken network config.
aws ec2 get-console-output --instance-id i-XXXX --latest --output text | tail -50 ::: Boot log on AWS (use your provider's equivalent)
gcloud compute instances get-serial-port-output VM_NAME --zone ZONE | tail -50 ::: Boot log on Google Cloud
aws ec2 describe-instance-status --instance-ids i-XXXX ::: AWS system and instance status checks
df -h; systemctl --failed ::: Once you're in via the serial console: a full disk or failed services often block sshd

@q Check sshd's configuration and debug it on the server
@w Validate changes before restarting, and run a temporary debug instance on a spare port to see exactly why logins fail.
sudo sshd -t ::: Syntax-check sshd_config (no output means OK)
sudo sshd -T | less ::: The fully expanded effective configuration
sudo /usr/sbin/sshd -d -p 2222 ::: One-off debug server on port 2222 that logs every step, then exits after one connection
ssh -p 2222 -vvv USER@HOST ::: Connect to the debug instance from your machine

@q Who is connected to this server over SSH right now?
@w Useful before maintenance, and for spotting unexpected sessions.
who ::: Logged-in users with their source IPs
w ::: Users plus what they're running
ss -tnp state established '( sport = :22 )' ::: Raw SSH connections and their sshd processes
last -n 20 ::: Recent logins

@s sshauth | Keys & authentication | SSH & Remote Access

@q "Permission denied (publickey)"
@w The server didn't accept any key you offered: wrong key, wrong user, the key isn't in authorized_keys, or permissions are too open (sshd silently ignores the file then).
ssh -v -i ~/.ssh/KEY USER@HOST 2>&1 | grep -E 'Offering|Authentications|denied' ::: Which keys were offered and what the server allows
ssh-keygen -lf ~/.ssh/KEY.pub ::: Fingerprint of your key
ssh-keygen -lf ~/.ssh/authorized_keys ::: On the server: fingerprints of every authorized key, to compare
chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys ::: On the server: permissions sshd requires
namei -l ~/.ssh/authorized_keys ::: On the server: your home directory must not be group- or world-writable either
sudo tail -n 30 /var/log/auth.log   (RHEL: /var/log/secure) ::: On the server: the exact reason, e.g. "bad ownership or modes"

@q "WARNING: UNPROTECTED PRIVATE KEY FILE!"
@w ssh refuses private keys that other users can read.
ls -l ~/.ssh/KEY ::: Should show -rw------- (600)
chmod 600 ~/.ssh/KEY ::: Fix it
chmod 400 ~/Downloads/KEY.pem ::: Same for keys downloaded from a cloud console

@q "Could not open a connection to your authentication agent"
@w ssh-agent isn't running in this shell, or SSH_AUTH_SOCK points to a socket that no longer exists (common inside tmux after reconnecting).
echo "$SSH_AUTH_SOCK" ::: Where the shell expects the agent socket
eval "$(ssh-agent -s)" ::: Start an agent for this shell
ssh-add ~/.ssh/id_ed25519 ::: Load a key into it
ssh-add -l ::: List the loaded keys

@q Create a new key and install it on a server
@w Ed25519 keys are short, fast and the modern default.
ssh-keygen -t ed25519 -C "you@company.com" -f ~/.ssh/work_ed25519 ::: Generate a key pair with a passphrase
ssh-copy-id -i ~/.ssh/work_ed25519.pub USER@HOST ::: Append the public key to the server's authorized_keys
ssh -i ~/.ssh/work_ed25519 -o IdentitiesOnly=yes USER@HOST ::: Test that exactly this key works
ssh-keygen -p -f ~/.ssh/work_ed25519 ::: Add or change the passphrase later

@q Password login doesn't work
@w Most cloud images disable password authentication entirely and only accept keys.
sudo sshd -T | grep -Ei 'passwordauthentication|kbdinteractive' ::: On the server: whether passwords are allowed at all
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no USER@HOST ::: Force a password attempt to test

@q The fingerprint in the console doesn't look like what ssh shows
@w Fingerprints can be shown as SHA256 (the modern default) or MD5 (older consoles), so compare in the same format.
ssh-keygen -lf KEY.pub ::: SHA256 fingerprint
ssh-keygen -E md5 -lf KEY.pub ::: MD5 fingerprint
ssh-keyscan -t ed25519 HOST 2>/dev/null | ssh-keygen -lf - ::: Fingerprint of a server's host key

@q "REMOTE HOST IDENTIFICATION HAS CHANGED"
@w Normally the instance was rebuilt behind the same IP or DNS name. Confirm the new fingerprint through a trusted channel (cloud console output, your team) before accepting it.
ssh-keyscan -t ed25519 HOST | ssh-keygen -lf - ::: Fingerprint the host is presenting now
ssh-keygen -F HOST ::: The entry currently in known_hosts
ssh-keygen -R HOST ::: Remove the old entry once you've verified the new key

@q Use my local keys on a remote server (for example, git clone there)
@w Agent forwarding lets the remote host use your agent without copying private keys. Only forward to hosts you trust.
ssh -A USER@HOST ::: Forward your agent for this session
ssh-add -l ::: Run on the remote host: your keys should be listed
ssh -T git@github.com ::: Run on the remote host: test access to GitHub

@s sshsess | Sessions & remote commands | SSH & Remote Access

@q The session drops when idle
@w NAT gateways, firewalls and load balancers silently drop idle TCP connections, often after about 350 seconds on AWS.
ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 HOST ::: Client keep-alives every 60 seconds
@pre
# ~/.ssh/config
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
@endpre

@q My terminal froze and Ctrl-C does nothing
@w The connection is dead but your client hasn't noticed yet. Use the SSH escape sequence, typed at the start of a line.
~. ::: Press Enter, then ~ then . to terminate the session
~? ::: List all escape sequences
~C ::: Open an ssh> prompt, for example to add a port forward to an existing session

@q A long-running job died when I disconnected
@w Processes started from your shell receive SIGHUP when the SSH session ends.
tmux new -s deploy ::: Start a persistent session; detach with Ctrl-b then d
tmux attach -t deploy ::: Reattach later, even from another machine
nohup ./migrate.sh > migrate.log 2>&1 & ::: Ignore the hang-up signal and write output to a file
screen -S deploy  /  screen -r deploy ::: An alternative to tmux

@q Run a command remotely without an interactive login
@w Handy in scripts. Quote carefully so variables expand on the side you intend.
ssh HOST 'uptime; df -h /' ::: Several commands in one call
ssh HOST "grep ERROR /var/log/app.log | tail -n $N" ::: $N expands locally, before sending
ssh HOST 'echo $HOSTNAME' ::: Single quotes make the variable expand on the remote side
ssh HOST 'bash -s' < ./check.sh ::: Run a local script on the remote host
ssh -o BatchMode=yes -o ConnectTimeout=5 HOST true && echo reachable ::: Non-interactive check that never prompts

@q sudo over SSH says "a terminal is required"
@w sudo needs a TTY to prompt for a password, and non-interactive ssh doesn't allocate one.
ssh -t HOST 'sudo systemctl status nginx' ::: Force a TTY
ssh -t HOST 'sudo -i' ::: Remote root shell

@q Run the same command on many servers
@w A plain loop works for a handful of hosts; xargs -P runs them in parallel.
for h in $(cat hosts.txt); do echo "== $h"; ssh -o BatchMode=yes "$h" 'uptime'; done ::: One at a time
xargs -P 10 -I{} ssh -o BatchMode=yes -o ConnectTimeout=5 {} 'echo "{}: $(uptime)"' < hosts.txt ::: Ten hosts in parallel
pssh -h hosts.txt -i 'uptime' ::: Parallel SSH tool (package: pssh or parallel-ssh)

@q Every SSH command is slow to connect
@w Multiplexing reuses one authenticated connection for later sessions, making repeat connections almost instant.
@pre
# ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 10m
@endpre
ssh -O check HOST ::: Is a master connection active?
ssh -O exit HOST ::: Close the master connection

@q The terminal looks broken (garbled output, "unknown terminal type")
@w The remote host doesn't know your terminal type, or a binary file was printed to the screen.
echo "$TERM" ::: Your terminal type
export TERM=xterm-256color ::: A value almost every server recognizes
reset ::: Reinitialize the terminal
stty sane ::: Restore normal input settings

@s sshtun | Tunnels & bastions | SSH & Remote Access

@q Reach a private database or service through a bastion
@w A local port forward makes a remote service appear on your laptop without exposing it publicly.
ssh -N -L 5432:db.internal:5432 USER@BASTION ::: Private Postgres on localhost:5432
ssh -N -L 8080:10.0.3.12:80 USER@BASTION ::: Internal web UI on http://localhost:8080
ssh -N -L 127.0.0.1:6379:cache.internal:6379 USER@BASTION ::: Bind explicitly to localhost so nobody else on your network can use it
psql -h 127.0.0.1 -p 5432 -U app appdb ::: Use the tunnel

@q Jump through one or more bastions
@w ProxyJump chains hops without keeping any keys on the bastions.
ssh -J USER@BASTION USER@10.0.2.15 ::: One hop
ssh -J bastion1,bastion2 USER@TARGET ::: Several hops
@pre
# ~/.ssh/config
Host bastion
    HostName 203.0.113.10
    User ec2-user
Host 10.0.*
    ProxyJump bastion
    User ubuntu
@endpre

@q "channel N: open failed: connect failed" when using a tunnel
@w Your SSH connection works, but the bastion itself can't reach the target host or port.
ssh BASTION 'nc -zv -w 5 db.internal 5432' ::: Test the target from the bastion
ssh BASTION 'getent hosts db.internal' ::: Does the bastion resolve the name?
ssh -v -N -L 5432:db.internal:5432 BASTION ::: Verbose output shows the failing channel

@q "bind: Address already in use" when starting a tunnel
@w Something on your machine, possibly an old tunnel, already uses that local port.
ss -ltnp 'sport = :5432' ::: Find what holds the local port
pgrep -af 'ssh .*-L' ::: Existing tunnel processes
ssh -N -L 15432:db.internal:5432 BASTION ::: Use a different local port instead

@q Make a local service reachable from a remote server
@w A remote forward opens a port on the server that leads back to your machine, for example to test a webhook against your laptop.
ssh -N -R 9000:localhost:3000 USER@HOST ::: Port 9000 on the server reaches port 3000 on your laptop
curl -s localhost:9000 ::: Test it from the server
sudo sshd -T | grep -i gatewayports ::: Whether remote forwards may bind beyond localhost on the server

@q Keep a tunnel up reliably
@w Tunnels die silently on network blips. Detect failure quickly and reconnect automatically.
ssh -f -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -L 5432:db.internal:5432 BASTION ::: Run in the background and exit if the forward fails
autossh -M 0 -f -N -o ServerAliveInterval=30 -L 5432:db.internal:5432 BASTION ::: Restart automatically when it drops (package: autossh)
pgrep -af 'ssh -f -N'  /  kill PID ::: Find and stop a background tunnel

@q Browse an internal network from my laptop
@w A dynamic forward turns SSH into a SOCKS proxy.
ssh -N -D 1080 USER@BASTION ::: SOCKS5 proxy on localhost:1080
curl --socks5-hostname localhost:1080 http://internal-dashboard/ ::: Use it from curl, resolving DNS on the remote side

@s sshxfer | File transfer | SSH & Remote Access

@q Copy files to or from a server
@w scp is fine for one-off copies; rsync is better for directories and repeat transfers.
scp ./app.tar.gz USER@HOST:/tmp/ ::: Upload a file
scp USER@HOST:/var/log/app.log ./ ::: Download a file
rsync -avz ./config/ USER@HOST:/etc/myapp/ ::: Sync a directory (the trailing slash means "contents of")
rsync -avzn ./config/ USER@HOST:/etc/myapp/ ::: Dry run first to see what would change

@q A large transfer keeps failing partway through
@w rsync can keep partial files and resume where it stopped.
rsync -avP USER@HOST:/data/dump.sql.gz ./ ::: -P keeps partial files and shows progress; re-run the same command to resume
rsync -avP --bwlimit=20m ./big.iso HOST:/tmp/ ::: Cap bandwidth at about 20 MB/s so you don't saturate the link
sha256sum dump.sql.gz; ssh HOST sha256sum /data/dump.sql.gz ::: Verify both copies match

@q Copy files through a bastion
@w Both scp and rsync accept the same jump options as ssh.
scp -J BASTION file.txt USER@10.0.2.15:/tmp/ ::: scp via a jump host
rsync -avz -e 'ssh -J BASTION' ./dist/ USER@10.0.2.15:/srv/app/ ::: rsync via a jump host

@q scp fails against an older server or appliance
@w Newer scp uses the SFTP protocol by default; some old or minimal servers only support the legacy protocol.
scp -O file.txt USER@HOST:/tmp/ ::: Use the legacy SCP protocol
sftp USER@HOST ::: Interactive SFTP as an alternative

@q Transfers between servers are slower than expected
@w Measure the raw network first, then tune the transfer.
iperf3 -s ::: On the receiving server: start a test listener
iperf3 -c RECEIVER_IP -t 10 ::: On the sender: measure throughput for 10 seconds
iperf3 -c RECEIVER_IP -P 4 ::: Four parallel streams, which helps on high-latency links
rsync -av --info=progress2 ./data/ HOST:/data/ ::: Overall progress for a large sync

@s ping | Reachability & ping | Network Diagnostics

@q Ping fails. Is the host down?
@w Not necessarily. Many cloud networks block ICMP by default. Test the actual port your application uses before concluding anything.
ping -c 4 HOST ::: Basic ICMP test
nc -zv -w 5 HOST 443 ::: TCP test of the real service port
timeout 3 bash -c '</dev/tcp/HOST/443' && echo open || echo closed ::: Port test using only bash
curl -sS -o /dev/null -w '%{http_code}\n' https://HOST/ ::: Application-level test

@q Ping says "Destination Host Unreachable"
@w Your machine or a router couldn't deliver the packet: on the local subnet, nothing answered ARP for that IP; otherwise a router has no route to it.
ip route get HOST_IP ::: Is it on your subnet or behind a gateway?
ip neigh show ::: FAILED or INCOMPLETE entries mean ARP got no reply
ping -c 3 "$(ip route | awk '/default/ {print $3; exit}')" ::: Is your gateway reachable?
arping -c 3 -I eth0 HOST_IP ::: ARP-level test on the same subnet (package: iputils-arping)

@q Ping says "Network is unreachable"
@w Your machine has no route to that network at all, usually because there's no default gateway or the interface is down.
ip -br link ::: Is the interface UP?
ip -br addr ::: Does it have an IP address?
ip route ::: Is there a default route?
networkctl status  /  nmcli device status ::: Network manager's view (systemd-networkd / NetworkManager)

@q Ping says "Name or service not known" / "unknown host"
@w Nothing is wrong with the network path; the name didn't resolve. See the DNS section.
getent hosts HOST ::: Resolve the way applications do
ping -c 3 1.1.1.1 ::: If an IP works, DNS is the problem
cat /etc/resolv.conf ::: Configured nameservers

@q Narrow down where connectivity breaks
@w Test outward one layer at a time: your interface, your gateway, the internet by IP, then by name.
ip -br addr ::: 1. Do you have an address?
ping -c 2 "$(ip route | awk '/default/ {print $3; exit}')" ::: 2. Can you reach the gateway?
ping -c 2 1.1.1.1 ::: 3. Can you reach the internet by IP?
ping -c 2 example.com ::: 4. Does name resolution work?
curl -sS -o /dev/null -w '%{http_code}\n' https://example.com ::: 5. Does HTTPS work end to end?

@q Ping works, but connecting to the service fails
@w ICMP is allowed but the specific TCP port is blocked or nothing listens there. Firewalls and security groups filter per port.
nc -zv -w 5 HOST PORT ::: "refused" means the host answered; "timed out" means it's being filtered
sudo ss -tlnp 'sport = :PORT' ::: On the server: is the app listening, and on 0.0.0.0 or only 127.0.0.1?
sudo tcpdump -i any -nn 'tcp port PORT and tcp[tcpflags] & tcp-syn != 0' ::: On the server: do connection attempts (SYNs) arrive at all?

@q Intermittent packet loss or timeouts
@w Take a large sample, then find which hop introduces the loss.
ping -c 200 -i 0.2 HOST | tail -3 ::: Loss percentage and min/avg/max/mdev latency over 200 pings
mtr -rwbc 200 HOST ::: Per-hop loss and latency report
ip -s link show eth0 ::: Errors and drops on your own interface
ethtool -S eth0 | grep -iE 'err|drop|miss' ::: Driver-level counters

@q High latency or jitter
@w Compare latency to the gateway, within your region and across regions to find where it's added.
ping -c 50 HOST | tail -1 ::: The mdev value is jitter
mtr -rwc 100 HOST ::: Shows the hop where latency jumps
ss -ti dst HOST ::: Round-trip time and retransmits for existing TCP connections

@q It works over IPv4 but not IPv6 (or the other way round)
@w Clients often try IPv6 first. A broken IPv6 path causes timeouts or slow fallback to IPv4.
getent ahosts HOST ::: Every address the name resolves to, IPv4 and IPv6
ping -4 -c 3 HOST  /  ping -6 -c 3 HOST ::: Test each protocol separately
curl -4 -sS -o /dev/null -w '%{http_code}\n' https://HOST  /  curl -6 … ::: The same at the application level
ip -6 route ::: Is there an IPv6 default route?

@q Test from a source that's allowed to reach the target
@w Security groups often only allow traffic from inside the VPC, so test from a host in the same subnet or security group.
ssh BASTION 'nc -zv -w 5 10.0.3.20 5432' ::: Test from the bastion
ssh BASTION 'ping -c 3 10.0.3.20' ::: ICMP from inside the VPC
ssh BASTION 'traceroute -n 10.0.3.20' ::: The path from inside the VPC

@s trace | Traceroute & path analysis | Network Diagnostics

@q How do I read traceroute output?
@w Each line is a router (hop). "* * *" means that hop didn't answer, which is often just ICMP filtering. Worry only when every hop after a point is "*" and the target never responds.
traceroute -n HOST ::: Classic UDP traceroute, numeric (no DNS lookups, so it's faster)
traceroute -I -n HOST ::: Use ICMP probes instead of UDP
traceroute -T -p 443 -n HOST ::: Use TCP SYNs to port 443, which pass through most firewalls (needs root)
tracepath -n HOST ::: No root needed; also reports path MTU

@q Traceroute stops at one hop and never reaches the target
@w Traffic is blocked or misrouted after the last responding hop: a security group or network ACL, a missing route in a route table or peering, or a firewall at the edge.
traceroute -T -p 443 -n HOST ::: Repeat with TCP to rule out ICMP or UDP filtering
mtr -T -P 443 -rwc 50 HOST ::: Continuous TCP-based path report
ip route get HOST_IP ::: Confirm your first hop is the gateway you expect
ssh OTHER_HOST "traceroute -n $(hostname -I | awk '{print $1}')" ::: Trace back from the other side; routes can be asymmetric

@q mtr shows packet loss at a middle hop
@w If loss appears at one middle hop but not at later hops or the destination, that router is just rate-limiting ICMP replies. Real loss continues all the way to the final hop.
mtr -rwc 200 HOST ::: Read the Loss% column at the LAST hop first
mtr -rwc 200 -i 0.5 HOST ::: Slower probing reduces rate-limiting artifacts
mtr -T -P 443 -rwc 200 HOST ::: TCP probes, closer to real application traffic

@q Which networks or providers does my traffic pass through?
@w AS numbers show where traffic leaves your cloud provider and which carriers carry it.
mtr -z -rwc 20 HOST ::: Show the AS number of each hop
whois -h whois.cymru.com " -v HOP_IP" ::: Look up the AS and owner of an IP (package: whois)

@q Large transfers stall but small requests work
@w A path-MTU "black hole": big packets are dropped and the ICMP "fragmentation needed" message never makes it back. Common with VPNs, VXLAN/overlay networks and GRE tunnels.
tracepath -n HOST ::: Shows where the path MTU drops ("pmtu 1400")
ping -M do -s 1472 -c 3 HOST ::: A 1500-byte packet with fragmentation forbidden (1472 + 28 bytes of headers)
ip link show dev eth0 | grep -o 'mtu [0-9]*' ::: Your interface MTU (9001 is common on AWS inside a VPC)
ss -ti dst HOST | grep -o 'pmtu:[0-9]*' ::: The path MTU the kernel learned for a live connection

@s iface | Interfaces & routing | Network Diagnostics

@q Which IP addresses and interfaces does this server have?
@w Cloud hosts often have several interfaces (primary, secondary ENIs, VPN, container bridges).
ip -br addr ::: Every interface with its addresses, one per line
ip -br link ::: Interface state (UP/DOWN) and MAC addresses
hostname -I ::: All IPs on one line
curl -s https://ifconfig.me ::: The public IP your outbound traffic uses (NAT gateway or elastic IP)

@q Which route will my traffic take?
@w The kernel picks the most specific route; hosts with several interfaces sometimes send traffic out the wrong one.
ip route ::: The main routing table
ip route get 10.20.1.5 ::: Exact interface, gateway and source IP for one destination
ip rule ::: Policy routing rules (used by some multi-interface setups)
ip route show table all | grep -v '^local' ::: Every table, including those used by policy routing

@q The server has no network after a reboot or config change
@w Check the link, the address, the route and DNS in that order, then the logs of whichever service manages networking.
ip -br link; ip -br addr; ip route ::: Link, address and route at a glance
networkctl status  /  nmcli general status ::: Whether systemd-networkd or NetworkManager is in charge
journalctl -u systemd-networkd -u NetworkManager -b --no-pager | tail -50 ::: Errors from the network manager
sudo cat /var/log/cloud-init.log | grep -iE 'network|error' | tail ::: cloud-init problems applying the network config
cat /etc/netplan/*.yaml ::: Ubuntu's network configuration

@q Add a route temporarily to test connectivity
@w Useful for reaching a peered VPC or VPN subnet before making the change permanent in your network config.
sudo ip route add 10.50.0.0/16 via 10.0.0.1 dev eth0 ::: Add a route (lost on reboot)
ip route get 10.50.1.10 ::: Confirm it's used
sudo ip route del 10.50.0.0/16 ::: Remove it again

@q Is the interface dropping packets or showing errors?
@w Rising error or drop counters point to driver, ring-buffer or upstream problems rather than your application.
ip -s link show eth0 ::: RX/TX errors and drops
ethtool eth0 ::: Link speed and duplex
ethtool -S eth0 | grep -iE 'drop|err|miss|fifo' ::: Detailed driver counters
nstat -az | grep -iE 'retrans|drop|overflow' ::: Kernel-wide TCP retransmit and drop counters

@q Suspect a duplicate IP address
@w Two machines with the same IP cause flapping, intermittent connectivity.
arping -D -c 3 -I eth0 10.0.1.25 ::: Duplicate address detection; any reply means another host has the IP
ip neigh show 10.0.1.25 ::: The MAC address currently mapped to that IP
watch -n1 'ip neigh show 10.0.1.25' ::: Look for the MAC changing back and forth

@q What does the cloud provider think this instance's network is?
@w The instance metadata service reports the assigned IPs, MACs and subnets from the provider's side.
TOKEN=$(curl -sX PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 60') ::: AWS: get an IMDSv2 session token
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4 ::: AWS: private IPv4
curl -s -H 'Metadata-Flavor: Google' http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip ::: Google Cloud: primary internal IP
curl -s -H 'Metadata: true' 'http://169.254.169.254/metadata/instance/network?api-version=2021-02-01' | jq ::: Azure: network details

@s ports | Ports & sockets | Network Diagnostics

@q Is my service actually listening?
@w A service bound to 127.0.0.1 looks healthy locally but can't be reached from other machines or a load balancer.
sudo ss -tlnp ::: All listening TCP sockets with process names
sudo ss -tlnp 'sport = :8080' ::: One port: check whether the address is 0.0.0.0, [::] or 127.0.0.1
sudo ss -ulnp ::: Listening UDP sockets
sudo lsof -nP -iTCP:8080 -sTCP:LISTEN ::: The same question answered by lsof
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/health ::: Local test, bypassing the network

@q "Address already in use" when the app starts
@w Another process, often a previous instance that didn't exit, already holds the port.
sudo ss -ltnp 'sport = :8080' ::: Find the PID holding the port
ps -o pid,user,etime,cmd -p PID ::: What it is and how long it has been running
sudo fuser -v 8080/tcp ::: Another way to identify the owner
systemctl status myapp ::: Check whether systemd is already running a copy

@q "Connection refused" vs "Connection timed out": what's the difference?
@w Refused: the host answered but nothing listens there, or a firewall REJECT rule replied. Timed out: packets are being silently dropped (DROP rule, security group, routing).
nc -zv -w 5 HOST PORT ::: Reproduce the error quickly
curl -v --connect-timeout 5 http://HOST:PORT/ ::: The same from curl's point of view
sudo tcpdump -i any -nn port PORT ::: On the server: do packets arrive? Does the server send back a RST?

@q Which ports on a server are reachable from outside?
@w Scan from another machine to see what the network actually allows. Only scan hosts you own or are authorized to test.
nmap -Pn -p 22,80,443,5432 HOST ::: Check specific ports, treating the host as up even if ping is blocked
nmap -Pn --top-ports 100 HOST ::: The 100 most common ports
nc -zv HOST 20-30 ::: A quick range check without nmap

@q Who is connected to my service?
@w Count established connections by client to spot a misbehaving client or a connection leak.
ss -tn state established '( sport = :443 )' | awk 'NR>1 {split($4,a,":"); print a[1]}' | sort | uniq -c | sort -rn | head ::: Top client IPs
ss -tn state established '( sport = :443 )' | wc -l ::: Total connections to port 443
ss -tnp state established '( dport = :5432 )' ::: Outbound connections from this host to Postgres, with processes

@q TIME_WAIT sockets piling up, or ephemeral ports running out
@w Opening a new connection for every request (no keep-alive or pooling) leaves thousands of TIME_WAIT sockets and can exhaust local ports, causing "Cannot assign requested address".
ss -s ::: Totals by state
ss -tan state time-wait | wc -l ::: TIME_WAIT count
ss -tan state time-wait | awk 'NR>1 {print $4}' | sort | uniq -c | sort -rn | head ::: Which remote endpoints they belong to
sysctl net.ipv4.ip_local_port_range ::: The available ephemeral port range

@q Test a UDP service
@w UDP has no handshake, so "open" isn't really provable. Use a protocol-specific client where possible.
nc -zuv HOST 514 ::: Best-effort UDP check
dig @HOST example.com ::: DNS over UDP (port 53)
sudo tcpdump -i any -nn udp port 514 ::: On the server: do the packets arrive?

@s fw | Firewalls & security groups | Network Diagnostics

@q Is the host firewall blocking traffic?
@w Look at the rules and their packet counters; a counter that rises as you retry shows which rule is matching.
sudo iptables -L -n -v --line-numbers ::: iptables rules with hit counters
sudo nft list ruleset ::: nftables rules (the default on newer distributions)
sudo ufw status verbose ::: Ubuntu's ufw
sudo firewall-cmd --list-all ::: RHEL-family firewalld
watch -n1 'sudo iptables -L INPUT -n -v | head -20' ::: Watch counters while you retry the connection

@q Is it the cloud security group or the host firewall?
@w Capture on the target host. If connection attempts arrive, the cloud layer let them through and the problem is on the host. If nothing arrives, look at the security group, network ACL or route table.
sudo tcpdump -i any -nn 'tcp port 443 and tcp[tcpflags] & tcp-syn != 0' ::: Do SYNs reach the host?
sudo ss -tlnp 'sport = :443' ::: Is anything listening for them?
aws ec2 describe-security-groups --group-ids sg-XXXX --query 'SecurityGroups[].IpPermissions' ::: AWS: inbound rules on a security group
aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=subnet-XXXX ::: AWS: network ACLs for the subnet (they're stateless, so return traffic needs rules too)

@q Was my IP banned by fail2ban?
@w Several failed logins from your address can trigger an automatic ban.
sudo fail2ban-client status ::: Active jails
sudo fail2ban-client status sshd ::: Banned IPs in the sshd jail
sudo fail2ban-client set sshd unbanip YOUR_IP ::: Lift the ban

@q "nf_conntrack: table full, dropping packet"
@w The kernel's connection-tracking table is full, so new connections are dropped at random. This happens on busy proxies and NAT hosts.
dmesg -T | grep -i conntrack ::: Confirm the message
sysctl net.netfilter.nf_conntrack_count net.netfilter.nf_conntrack_max ::: Current entries vs the limit
sudo conntrack -S ::: Per-CPU statistics, including drops (package: conntrack)

@q SELinux is blocking my service from binding or connecting
@w On RHEL-family systems, SELinux can deny a port or outbound connection even when file permissions and the firewall are fine.
getenforce ::: Enforcing, Permissive or Disabled
sudo ausearch -m avc -ts recent ::: Recent denials
sudo semanage port -l | grep http_port_t ::: Ports a web service may bind to
getsebool httpd_can_network_connect ::: Whether web servers may make outbound connections

@s pcap | Packet capture | Network Diagnostics

@q Capture traffic to see what's really happening
@w A packet capture settles whether a problem is in the application or the network.
sudo tcpdump -i any -nn host 10.0.1.5 and port 443 ::: Live traffic for one host and port
sudo tcpdump -i any -nn -c 100 port 5432 ::: Stop after 100 packets
sudo tcpdump -i any -nn -w /tmp/cap.pcap port 443 ::: Save for analysis in Wireshark
tcpdump -nn -r /tmp/cap.pcap | head ::: Read a saved capture

@q Watch only connection attempts or resets
@w TCP flag filters show whether connections are being attempted, accepted or refused.
sudo tcpdump -i any -nn 'tcp[tcpflags] & tcp-syn != 0 and port 8080' ::: SYNs (connection attempts)
sudo tcpdump -i any -nn 'tcp[tcpflags] & tcp-rst != 0' ::: Resets (refusals or aborted connections)
sudo tcpdump -i any -nn 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0 and host 10.0.1.5' ::: Connection opens and closes for one host

@q See DNS queries or plain HTTP requests on the wire
@w Useful when an application resolves the wrong name or sends unexpected headers.
sudo tcpdump -i any -nn port 53 ::: Every DNS query and response
sudo tcpdump -i any -A -s0 'tcp port 80' | grep -E '^(GET|POST|Host:|HTTP/)' ::: Plain-HTTP request lines and Host headers

@q Capture on a remote server and view it in Wireshark locally
@w Stream the capture over SSH instead of saving and copying files.
ssh HOST 'sudo tcpdump -i any -U -s0 -w - port 443' | wireshark -k -i - ::: Live remote capture into local Wireshark
ssh HOST 'sudo tcpdump -i any -c 1000 -w - port 5432' > db.pcap ::: Save a remote capture to your laptop

@q Capture over a long period without filling the disk
@w Rotate through a fixed number of files of a fixed size.
sudo tcpdump -i any -nn -w /var/tmp/cap-%Y%m%d%H%M.pcap -G 300 -W 12 port 443 ::: A new file every 5 minutes, keeping 12
sudo tcpdump -i any -nn -C 100 -W 10 -w /var/tmp/cap.pcap port 443 ::: Ten files of 100 MB in rotation

@s tput | Throughput & bandwidth | Network Diagnostics

@q Network transfers between servers are slow
@w Measure raw throughput first to see whether the network or the application is the limit.
iperf3 -s ::: On server A: start a listener (port 5201)
iperf3 -c SERVER_A -t 15 ::: On server B: TCP throughput test
iperf3 -c SERVER_A -R ::: Reverse direction
iperf3 -c SERVER_A -P 8 ::: Eight parallel streams, which helps on high-latency paths
ethtool eth0 | grep -i speed ::: Negotiated link speed

@q Which process is using all the bandwidth?
@w Per-process and per-connection views show who is consuming the link.
sudo nethogs eth0 ::: Bandwidth by process (package: nethogs)
sudo iftop -i eth0 -nP ::: Bandwidth by connection (package: iftop)
sar -n DEV 1 5 ::: Throughput per interface over time (package: sysstat)
nload eth0 ::: Simple live in/out graph (package: nload)

@q TCP connections are slow even though bandwidth is available
@w Look at retransmits and congestion window size: packet loss or small buffers throttle TCP on long-distance links.
ss -ti dst HOST ::: rtt, cwnd and retrans for each connection
nstat -az TcpRetransSegs TcpExtTCPLostRetransmit ::: System-wide retransmit counters
sysctl net.ipv4.tcp_congestion_control net.core.rmem_max net.core.wmem_max ::: Congestion algorithm and maximum buffer sizes

@s dns | DNS | Name Resolution & Web

@q A hostname won't resolve
@w Check what the system resolver returns (/etc/hosts plus DNS) before blaming the DNS server.
getent hosts NAME ::: Resolves the same way your application does
dig +short NAME ::: Ask the configured DNS server directly
dig @1.1.1.1 +short NAME ::: Compare with a public resolver
cat /etc/resolv.conf ::: Which nameservers and search domains are configured
resolvectl status ::: Per-interface DNS on systemd-resolved hosts (nameserver 127.0.0.53 means the local stub)

@q What do NXDOMAIN, SERVFAIL and a timeout each mean?
@w NXDOMAIN: the name doesn't exist. SERVFAIL: the resolver couldn't get a valid answer (broken delegation, DNSSEC failure, upstream down). Timeout: the resolver is unreachable.
dig NAME | grep -E 'status:|SERVER:' ::: The status code and which server answered
dig +trace NAME ::: Walk from the root to find where resolution breaks
dig NS example.com +short ::: Authoritative nameservers for the domain
dig @ns1.example.com NAME ::: Ask an authoritative server directly

@q I changed a DNS record but some machines still see the old value
@w Answers are cached until their TTL expires, both in resolvers and inside long-running applications.
dig NAME ::: The number in the ANSWER section is the remaining TTL
dig @AUTHORITATIVE_NS NAME ::: The current authoritative answer
sudo resolvectl flush-caches ::: Clear the systemd-resolved cache
sudo systemctl restart myapp ::: Some runtimes cache DNS for the life of the process

@q DNS lookups are slow (5-second pauses)
@w Often an unreachable nameserver listed first, or IPv6 (AAAA) queries timing out before the resolver falls back.
time getent hosts NAME ::: Measure a lookup
dig +stats NAME | grep 'Query time' ::: Time per query
grep -E '^(nameserver|options)' /etc/resolv.conf ::: Check timeout/attempts options and the nameserver order
dig AAAA NAME ::: Does the IPv6 lookup hang?

@q A name resolves differently on two servers
@w /etc/hosts overrides, different search domains, or split-horizon DNS (private zones visible only inside the VPC).
grep -v '^#' /etc/hosts ::: Local overrides
grep hosts /etc/nsswitch.conf ::: Lookup order (files before dns means /etc/hosts wins)
grep -E '^(search|domain)' /etc/resolv.conf ::: Search domains that change what short names mean
dig +short NAME @"$(awk '/^nameserver/ {print $2; exit}' /etc/resolv.conf)" ::: Ask the exact server this host uses

@q Check other record types (CNAME, MX, TXT, reverse)
@w Mail, domain verification and service discovery depend on more than A records.
dig +short CNAME www.example.com ::: Alias target
dig +short MX example.com ::: Mail servers
dig +short TXT example.com ::: Verification and SPF records
dig +short SRV _sip._tcp.example.com ::: Service records with ports
dig -x 10.0.1.25 +short ::: Reverse lookup (IP to name)

@s tls | TLS & certificates | Name Resolution & Web

@q "x509: certificate signed by unknown authority" / "unable to get local issuer certificate"
@w The client doesn't trust the issuing CA (common with internal CAs), or the server isn't sending its intermediate certificates.
openssl s_client -connect HOST:443 -servername HOST -showcerts </dev/null ::: The full chain the server presents
openssl verify -CAfile ca.pem server.pem ::: Does this CA actually sign the certificate?
curl --cacert ca.pem https://HOST/ ::: Test with an explicit CA bundle
sudo cp corp-ca.pem /usr/local/share/ca-certificates/corp-ca.crt && sudo update-ca-certificates ::: Add an internal CA to the system trust store (Debian/Ubuntu)

@q "certificate is valid for X, not Y" (hostname mismatch)
@w The name you connected with isn't in the certificate's Subject Alternative Names, which happens when you use an IP, a tunnel to localhost, or an internal alias.
openssl s_client -connect HOST:443 -servername HOST </dev/null 2>/dev/null | openssl x509 -noout -ext subjectAltName ::: Names the certificate covers
curl --resolve api.example.com:443:127.0.0.1 https://api.example.com/ ::: Connect to a different IP while keeping the correct name

@q When does this certificate expire?
@w Expired certificates are one of the most common causes of sudden outages, so check them in monitoring or CI.
openssl x509 -in cert.pem -noout -enddate ::: Expiry date of a local file
echo | openssl s_client -connect HOST:443 -servername HOST 2>/dev/null | openssl x509 -noout -dates ::: Expiry of a live endpoint
openssl x509 -in cert.pem -noout -checkend 2592000 && echo "valid for 30+ days" ::: Exit code you can use in scripts

@q TLS handshake fails ("handshake failure", "wrong version number", "protocol version")
@w Client and server share no TLS version or cipher, or you're speaking TLS to a plain-HTTP port (that's the "wrong version number" error).
openssl s_client -connect HOST:443 -tls1_2 </dev/null ::: Try TLS 1.2 specifically
openssl s_client -connect HOST:443 -tls1_3 </dev/null ::: Try TLS 1.3
curl -v http://HOST:443/ ::: If this returns HTTP, the port isn't speaking TLS at all
nmap --script ssl-enum-ciphers -p 443 HOST ::: The versions and ciphers the server supports

@q Does this private key belong to this certificate?
@w Servers refuse to start, with vague errors, when the key and certificate don't match.
openssl x509 -in cert.pem -noout -pubkey | sha256sum ::: Hash of the certificate's public key
openssl pkey -in key.pem -pubout | sha256sum ::: Hash of the key's public half; must match the line above

@q I need a certificate for local development
@w A short-lived self-signed certificate is enough for testing HTTPS locally.
openssl req -x509 -newkey rsa:2048 -nodes -days 30 -keyout dev.key -out dev.crt -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" ::: Self-signed certificate valid for localhost
openssl x509 -in dev.crt -noout -text | less ::: Inspect what you created

@s http | HTTP & APIs | Name Resolution & Web

@q Test an API endpoint from the server
@w curl lets you reproduce exactly what your app sends.
curl -i https://api.example.com/v1/items ::: Response headers and body
curl -sS -H "Authorization: Bearer $TOKEN" https://api.example.com/v1/me | jq ::: Authenticated request, pretty-printed
curl -sS -X POST -H 'Content-Type: application/json' -d '{"name":"test"}' URL ::: POST a JSON body
curl -v URL 2>&1 | grep -E '^[<>]' ::: Request and response headers only

@q Requests are slow: where does the time go?
@w Break the request into DNS lookup, TCP connect, TLS handshake and time to first byte.
curl -o /dev/null -s -w 'dns %{time_namelookup}s  connect %{time_connect}s  tls %{time_appconnect}s  ttfb %{time_starttransfer}s  total %{time_total}s\n' URL ::: Timing breakdown
for i in $(seq 10); do curl -o /dev/null -s -w '%{time_total}\n' URL; done | sort -n ::: Ten samples to spot outliers

@q The app can't reach an external API, but my laptop can
@w Typical causes: no outbound route (missing NAT gateway or internet gateway), egress rules, a required proxy, or DNS that differs inside the VPC.
curl -v --connect-timeout 5 https://api.example.com ::: See whether it fails at DNS, connect or TLS
getent hosts api.example.com ::: What the server resolves the name to
ip route | grep default ::: Is there a default route out?
curl -s https://ifconfig.me ::: The public IP your traffic appears from, for the partner's allow-list
env | grep -i _proxy ::: Proxy variables that might be redirecting traffic

@q My script treats error pages as success
@w Plain curl exits 0 even on a 500. Make failures fail, and add timeouts and retries.
curl -fsS URL ::: Non-zero exit on HTTP 4xx/5xx
curl -fsS --retry 5 --retry-delay 2 --retry-connrefused --max-time 30 URL ::: Retry transient failures with an overall time limit
code=$(curl -s -o body.json -w '%{http_code}' URL) ::: Capture the status code separately from the body

@q Everything has to go through a corporate proxy
@w Most CLI tools respect the proxy environment variables; exclude internal hosts so they don't go through it.
export HTTPS_PROXY=http://proxy.corp:3128 ::: Send HTTPS traffic via the proxy
export NO_PROXY=localhost,127.0.0.1,.internal,10.0.0.0/8 ::: Skip the proxy for internal addresses
curl -x http://proxy.corp:3128 https://example.com ::: Use a proxy for one request

@s lb | Load balancers & proxies | Name Resolution & Web

@q The load balancer returns 502 or 504
@w 502: the backend refused or reset the connection, or sent an invalid response. 504: the backend didn't answer within the load balancer's timeout. Test the backend directly, bypassing the load balancer.
curl -v http://BACKEND_IP:8080/health ::: Hit one backend directly from inside the VPC
curl -sv --resolve app.example.com:443:BACKEND_IP https://app.example.com/ ::: Same request with the real hostname
sudo ss -tlnp 'sport = :8080' ::: On the backend: listening on 0.0.0.0, not 127.0.0.1?
journalctl -u myapp --since "10 min ago" -p warning ::: Backend errors around the time of the 5xx

@q Health checks fail but the app seems fine
@w The check uses a specific path, port and expected status, from the load balancer's subnets. Any mismatch marks the target unhealthy.
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/health ::: Must return the status code the check expects (often 200)
sudo tcpdump -i any -nn port 8080 and src net 10.0.0.0/16 ::: Do health-check probes from the load balancer subnets arrive?
time curl -s localhost:8080/health ::: Must respond within the check's timeout

@q My app sees the load balancer's IP instead of the client's
@w Proxies replace the source IP. The original client address travels in a header (X-Forwarded-For) or via PROXY protocol.
sudo tcpdump -i any -A -s0 'tcp port 8080' | grep -i 'x-forwarded-for' ::: Is the header arriving?
curl -s -H 'X-Forwarded-For: 203.0.113.9' localhost:8080/debug/ip ::: Check how the app parses the header (if it has a debug endpoint)

@q Connections drop after a fixed amount of time
@w Idle timeouts on the load balancer, proxy or NAT gateway are shorter than your keep-alive or query time.
ss -tno state established '( dport = :443 )' ::: Timer information for each connection
time curl -s https://app.example.com/slow-endpoint > /dev/null ::: Does it always fail at the same duration (for example 60 s)?
sysctl net.ipv4.tcp_keepalive_time ::: Kernel TCP keep-alive interval (default 7200 s, far longer than most load balancer timeouts)

@s disk | Disk & storage | Server Health

@q "No space left on device"
@w Find which filesystem is full, then what is filling it. Logs, temp files, old releases and container images are the usual suspects.
df -hT ::: Usage per filesystem
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -15 ::: Largest directories on the root filesystem (-x stays on one filesystem)
sudo find / -xdev -type f -size +500M -exec ls -lh {} + 2>/dev/null ::: Individual files over 500 MB
journalctl --disk-usage ::: Space used by the systemd journal
sudo lsof +L1 ::: Deleted files still held open (space is only freed when the process closes them)
ncdu -x / ::: Interactive explorer for drilling down (package: ncdu)

@q df says there's space, but writes still fail
@w You've run out of inodes (millions of small files), or the filesystem has been remounted read-only after an error.
df -i ::: Inode usage per filesystem
sudo find /var -xdev -type f | cut -d/ -f2-3 | sort | uniq -c | sort -rn | head ::: Directories with the most files
findmnt -no OPTIONS / ::: Look for "ro" in the mount options
dmesg -T | grep -iE 'error|read-only|ext4|xfs' | tail ::: Kernel messages explaining a forced read-only remount

@q Logs are growing too fast
@w Make sure rotation is configured and working before the disk fills up again.
ls -lhS /var/log | head ::: Biggest log files
sudo logrotate -d /etc/logrotate.d/myapp ::: Dry run: shows what rotation would do
cat /etc/logrotate.d/myapp ::: Check size/daily rules, rotate count and compress
journalctl -u myapp --since "1 hour ago" | wc -l ::: How chatty the service is

@q I resized the cloud volume but the filesystem is still the old size
@w There are three layers to grow: the disk, the partition and the filesystem.
lsblk ::: Confirm the disk is now larger than its partition
sudo growpart /dev/nvme0n1 1 ::: Extend partition 1 to fill the disk (package: cloud-utils)
sudo resize2fs /dev/nvme0n1p1   (XFS: sudo xfs_growfs /) ::: Grow the filesystem online
df -h / ::: Verify the new size

@q Disk I/O seems slow
@w Look at device utilization and wait times, then at which process is responsible.
iostat -xz 1 5 ::: %util near 100 or a high await means the disk is saturated (package: sysstat)
sudo iotop -o ::: Processes currently doing I/O (package: iotop)
vmstat 1 5 ::: The "wa" column shows CPU time spent waiting on I/O

@q "Device or resource busy" when unmounting
@w A process has a file open, or its working directory, on that mount.
sudo lsof +D /mnt/data ::: Open files under the mount
sudo fuser -vm /mnt/data ::: Processes using the mount


@s perf | CPU & memory | Server Health

@q The server is slow. Where do I start?
@w Spend 60 seconds working out whether the pressure is CPU, memory, disk or network before changing anything.
uptime ::: Compare the load average with the number of CPUs (nproc)
top -o %CPU   (or htop) ::: Top consumers right now
vmstat 1 5 ::: r = runnable queue, si/so = swapping, wa = waiting on I/O
free -h ::: Memory: look at "available", not "free"
iostat -xz 1 3 ::: Disk utilization and latency
dmesg -T | tail -20 ::: Recent kernel warnings (OOM kills, disk errors)

@q My process was killed without warning
@w The kernel's out-of-memory (OOM) killer ends the largest process when RAM runs out. In containers, the memory limit triggers it for that cgroup.
dmesg -T | grep -iE 'out of memory|killed process' ::: OOM kill events and their victims
journalctl -k --since today -g 'Out of memory' ::: The same events via journald
ps -eo pid,rss,cmd --sort=-rss | head ::: Largest memory users now (RSS in KB)
systemctl show myapp -p MemoryMax -p MemoryCurrent ::: Memory limit and usage if systemd caps the service

@q Memory keeps climbing: is it a leak?
@w Track one process's resident memory over time. Page cache growth is normal, but steadily growing process RSS is not.
watch -n 5 'ps -o pid,rss,vsz,cmd -p PID' ::: Watch a process's memory
grep -E 'VmRSS|VmSwap|Threads' /proc/PID/status ::: Memory, swap and thread count
pmap -x PID | tail -1 ::: Total mapped memory for the process
smem -tk ::: Proportional memory per process, counting shared pages fairly (package: smem)

@q One process is pegging the CPU
@w Identify it, then look at which threads are busy and what they're doing.
ps -eo pid,user,%cpu,%mem,etime,cmd --sort=-%cpu | head ::: Top CPU consumers
top -H -p PID ::: Per-thread CPU usage inside one process
sudo perf top -p PID ::: Hot functions in the process (package: linux-tools)
sudo strace -c -p PID ::: Syscall summary; press Ctrl-C after a few seconds

@q "Too many open files"
@w The process hit its file descriptor limit. Busy servers need far more than the default 1024.
ulimit -n ::: Limit for your current shell
grep 'open files' /proc/PID/limits ::: Limit for the running process
ls /proc/PID/fd | wc -l ::: How many it has open right now
sudo systemctl edit myapp   →  [Service] LimitNOFILE=65536 ::: Raise it for a systemd service, then reload and restart

@q Load average is high but CPU usage is low
@w Load counts tasks waiting on I/O (state D) as well as tasks using CPU, so this usually points to storage or NFS problems.
ps -eo pid,stat,wchan:30,cmd | awk '$2 ~ /D/' ::: Tasks stuck in uninterruptible I/O wait
cat /proc/pressure/io ::: Share of time tasks are stalled on I/O (kernel 4.20+)
iostat -xz 1 3 ::: Which device is struggling


@s proc | Processes | Server Health

@q Find a process and stop it cleanly
@w Confirm exactly what matches first, then ask it to exit with SIGTERM so it can shut down gracefully.
pgrep -af PATTERN ::: Matching PIDs with their full command lines
ps -ef --forest | less ::: The process tree, showing parents and children
kill PID ::: Send SIGTERM (graceful shutdown)
kill -HUP PID ::: Many daemons reload their config on SIGHUP

@q What is this process doing? Is it stuck?
@w Look at its state, the files and sockets it holds, and the system calls it's making.
ps -o pid,stat,etime,wchan:25,cmd -p PID ::: State: R running, S sleeping, D waiting on I/O, Z zombie
sudo lsof -p PID ::: Open files, sockets and pipes
sudo strace -f -tt -p PID ::: Live system calls (slows the process; Ctrl-C to stop)
cat /proc/PID/cmdline | tr '\0' ' '; echo ::: The exact command it was started with
sudo cat /proc/PID/environ | tr '\0' '\n' ::: The environment it was started with

@q Run something in the background and check on it later
@w Shell job control works for quick tasks; use tmux or systemd for anything that must outlive your session.
./task.sh & ::: Start in the background
jobs -l  /  fg %1  /  bg %1 ::: List jobs, bring one to the foreground, resume one in the background
Ctrl-Z ::: Suspend the foreground job
nohup ./task.sh > task.log 2>&1 & ::: Survives logout
systemd-run --user --unit=adhoc ./task.sh ::: Run as a transient service you can inspect with systemctl --user status adhoc

@q Give a heavy job lower priority so it doesn't slow the service
@w Lower its CPU and I/O priority so production traffic always wins.
nice -n 15 ./batch.sh ::: Start with low CPU priority
renice +10 -p PID ::: Lower priority of a running process
ionice -c3 ./backup.sh ::: Idle I/O class: only uses the disk when nothing else needs it
timeout 30m ./batch.sh ::: Stop it automatically if it overruns


@s svc | Services & logs | Server Health

@q My service won't start
@w The cause is almost always in the last few dozen log lines. Then run the binary by hand with the same user and config.
systemctl status myapp --no-pager -l ::: State plus the most recent log lines
journalctl -u myapp -b -n 100 --no-pager ::: The last 100 lines since boot
systemctl cat myapp ::: The exact unit file and any overrides in effect
sudo -u myapp /opt/myapp/bin/server --config /etc/myapp/config.yml ::: Run it in the foreground as the service user to see errors directly
systemd-analyze verify /etc/systemd/system/myapp.service ::: Check the unit file for mistakes

@q The service keeps restarting (crash loop)
@w systemd keeps restarting it according to Restart=. Find the first error in the loop, not the most recent one.
systemctl show myapp -p NRestarts -p ExecMainStatus -p Result ::: Restart count and the last exit status
journalctl -u myapp --since "30 min ago" -p warning --no-pager ::: Warnings and errors only
journalctl -u myapp -o cat --since "30 min ago" | grep -m1 -iE 'error|fatal|panic' ::: The first error in that window

@q Change environment variables or limits for a service
@w Use a drop-in override instead of editing the packaged unit file, so upgrades don't overwrite your changes.
sudo systemctl edit myapp ::: Opens an override file, e.g. [Service] Environment=LOG_LEVEL=debug
sudo systemctl daemon-reload ::: Reload unit definitions
sudo systemctl restart myapp ::: Apply the change
systemctl show myapp -p Environment ::: Confirm the variables the service now gets

@q Find a specific error in the logs fast
@w Filter by service, priority, time range and pattern instead of scrolling.
journalctl -u myapp -p err --since today ::: Errors from today
journalctl -u myapp -g 'timeout|refused' --since "1 hour ago" ::: Search with a regex
journalctl -u myapp -f ::: Follow new lines live
journalctl -b -1 -u myapp ::: Logs from before the last reboot
grep -h 'ERROR' /var/log/myapp/*.log | sort | uniq -c | sort -rn | head ::: Most frequent error lines in plain log files

@q The application writes structured (JSON) logs
@w Use jq to filter and summarize them instead of grep.
tail -F app.log | jq -c 'select(.level=="error")' ::: Follow errors only
jq -r 'select(.status >= 500) | .path' app.log | sort | uniq -c | sort -rn | head ::: Endpoints producing the most 5xx responses
jq -r '.latency_ms' app.log | sort -n | awk '{a[NR]=$1} END {print "p50", a[int(NR*0.5)], "p99", a[int(NR*0.99)]}' ::: Rough latency percentiles

@q Did the machine reboot? Why?
@w Check the boot history and the end of the previous boot's journal.
uptime -s ::: When the current boot started
journalctl --list-boots | tail ::: Recent boots
last -x reboot shutdown | head ::: Reboot and shutdown history
journalctl -b -1 -n 50 --no-pager ::: The last messages before the previous boot ended


@s time | Time & clocks | Server Health

@q Auth tokens or TLS fail with "not yet valid" or "expired" on one server only
@w Clock skew. Signed tokens (JWT, cloud signatures) and certificates depend on accurate time.
timedatectl ::: Shows whether the clock is NTP-synchronized
chronyc tracking ::: Current offset from the reference clock (chrony)
date -u; curl -sI https://www.google.com | grep -i '^date' ::: Compare with a trusted HTTP Date header

@q Log timestamps don't line up across servers
@w Mixed time zones make it painful to correlate incidents. Standardize servers on UTC.
timedatectl | grep 'Time zone' ::: Current time zone
date -u +%Y-%m-%dT%H:%M:%SZ ::: ISO-8601 UTC timestamp for scripts and logs
date -d @1700000000 -u ::: Convert an epoch timestamp
date -d '2026-11-01T10:00:00Z' +%s ::: Convert a timestamp to epoch seconds


@s perms | Permissions & users | Files & Access

@q "Permission denied" when running a script
@w The file isn't executable, or the filesystem is mounted noexec (often the case for /tmp).
ls -l script.sh ::: Look for the x bits, e.g. -rwxr-xr-x
chmod +x script.sh ::: Make it executable
bash script.sh ::: Run it without needing the execute bit
findmnt -no OPTIONS -T script.sh ::: "noexec" here means the mount forbids running programs

@q The app can't read its config or write to its data directory
@w Services usually run as their own user, and every directory along the path must be traversable by it.
systemctl show myapp -p User -p Group ::: The account the service runs as
namei -l /etc/myapp/config.yml ::: Permissions of every component of the path
sudo -u myapp test -r /etc/myapp/config.yml && echo readable ::: Test as that user
sudo chown myapp:myapp /var/lib/myapp ::: Give the service its data directory

@q Write a root-owned file from a script
@w "sudo echo text > file" fails because the redirection runs as you, not as root.
echo "setting=1" | sudo tee /etc/myapp/extra.conf > /dev/null ::: Write the file as root
echo "setting=2" | sudo tee -a /etc/myapp/extra.conf > /dev/null ::: Append as root
sudo install -m 640 -o root -g myapp app.conf /etc/myapp/ ::: Copy with owner and mode in one step

@q What am I allowed to do with sudo?
@w Check your own privileges before an automation run fails halfway through.
id ::: Your user, groups and IDs
sudo -l ::: Commands you're allowed to run with sudo
getent group docker ::: Members of a group

@q New files keep getting the wrong permissions
@w The umask controls default permissions; shared directories also need the setgid bit so new files inherit the group.
umask ::: Current mask (022 gives 644 files and 755 directories)
chmod g+s /srv/shared ::: New files inherit the directory's group
setfacl -d -m g:devs:rwX /srv/shared ::: Default ACL so the group keeps write access
getfacl /srv/shared ::: Show ACLs in effect


@s files | Files & searching | Files & Access

@q Which file sets this config value?
@w Search the whole config tree, including drop-in directories.
grep -rn 'max_connections' /etc/ 2>/dev/null ::: Every occurrence with file and line number
grep -rn --include='*.yml' --include='*.yaml' 'timeout' ./deploy ::: Only YAML files
rg -n 'DATABASE_URL' ::: ripgrep: fast and respects .gitignore

@q What changed on this server recently?
@w Recently modified files and package changes usually point straight at the cause.
sudo find /etc -type f -mmin -120 ::: Config files changed in the last two hours
ls -lt /etc/myapp/ ::: Newest files first
grep -E ' (install|upgrade) ' /var/log/dpkg.log | tail   (RHEL: dnf history) ::: Recent package changes
last -n 10 ::: Recent logins

@q Compare a file between two servers
@w Process substitution lets you diff remote files without copying them anywhere.
diff <(ssh host1 cat /etc/myapp/config.yml) <(ssh host2 cat /etc/myapp/config.yml) ::: Line-by-line differences
for h in host1 host2 host3; do echo "$h $(ssh "$h" sha256sum /etc/myapp/config.yml | cut -c1-12)"; done ::: Spot the odd one out by checksum

@q Find large, old or recently modified files
@w find can filter by size, age, owner and type in a single pass.
find . -type f -size +100M ::: Files over 100 MB
find /var/tmp -type f -mtime +30 ::: Files untouched for 30+ days
find . -type f -newer deploy.marker ::: Files changed since a reference file
find . -type f -printf '%T@ %p\n' | sort -n | tail ::: Most recently modified files

@q Replace a value across many files safely
@w Preview the matches, then edit in place with backups.
grep -rln 'old.example.com' ./config ::: Files that would change
grep -rn 'old.example.com' ./config ::: The exact lines
grep -rlZ 'old.example.com' ./config | xargs -0 sed -i.bak 's/old\.example\.com/new.example.com/g' ::: Replace in place, keeping .bak copies

@q Pack or unpack an archive
@w tar handles most deployment artifacts; list the contents before extracting.
tar -tzf release.tar.gz | head ::: List the contents
tar -xzf release.tar.gz -C /opt/myapp/releases/v42 ::: Extract into a specific directory
tar -czf backup-$(date +%F).tar.gz --exclude='*.log' ./data ::: Create a compressed archive, skipping logs
zcat app.log.1.gz | grep ERROR ::: Search a compressed log without extracting it


@s env | Configuration & environment | Files & Access

@q The app doesn't see an environment variable I set
@w Variables set in your shell don't reach systemd services, cron jobs or other users' processes.
printenv APP_ENV ::: What your shell has
sudo cat /proc/PID/environ | tr '\0' '\n' | grep APP_ ::: What the running process actually has
systemctl show myapp -p Environment -p EnvironmentFiles ::: What systemd passes to the service
export APP_ENV=staging ::: Variables must be exported to reach child processes

@q Load a .env file into my shell or script
@w set -a exports every variable defined while it's active.
set -a; source .env; set +a ::: Export everything in .env
env -i bash -c 'set -a; source .env; ./run.sh' ::: Run with only the variables from .env
grep -v '^#' .env | grep -v '^$' ::: Show the settings without comments or blank lines

@q "command not found" right after installing something
@w The binary isn't on your PATH, or the shell has cached an older location.
command -v mytool || echo "not on PATH" ::: Where the command resolves, if anywhere
echo "$PATH" | tr ':' '\n' ::: Your PATH, one entry per line
hash -r ::: Clear the shell's cache of command locations
export PATH="$HOME/.local/bin:$PATH" ::: Add a directory (persist it in ~/.bashrc)

@q Which version of a tool or library am I actually running?
@w Version mismatches between laptop, CI and servers cause "works on my machine" bugs.
python3 --version; node --version; java -version 2>&1 | head -1 ::: Runtime versions
type -a python3 ::: Every python3 on PATH, in order of precedence
ldd /usr/local/bin/myapp ::: Shared libraries a binary links against
cat /etc/os-release ::: Distribution and release


@s bash | Bash scripting | Scripting & Automation

@q My script keeps going after a command fails
@w Bash ignores errors by default, including failures in the middle of a pipeline.
set -euo pipefail ::: Exit on errors, on unset variables, and on failures anywhere in a pipeline
trap 'echo "failed at line $LINENO: $BASH_COMMAND" >&2' ERR ::: Report where the failure happened
cmd || true ::: Explicitly allow one command to fail
echo "${PIPESTATUS[@]}" ::: Exit code of every stage of the last pipeline

@q It works in my terminal but fails in cron or CI
@w Non-interactive environments have a minimal PATH, no ~/.bashrc and none of the variables you exported.
env -i HOME="$HOME" bash --noprofile --norc -c './script.sh' ::: Reproduce a bare environment
command -v aws ::: Use the absolute path this prints inside scripts
#!/usr/bin/env bash ::: Make sure the script runs in bash, not sh
*/10 * * * * /opt/scripts/job.sh >> /var/log/job.log 2>&1 ::: Always capture cron output somewhere

@q Values with spaces or special characters break my commands
@w Unquoted variables are split into words and expanded as file patterns.
"$var"  "${files[@]}" ::: Always quote expansions
args=(--region "$REGION" --tag "env=$ENV"); mycli deploy "${args[@]}" ::: Build argument lists as arrays, never as strings
while IFS= read -r line; do echo "$line"; done < file.txt ::: Read lines without mangling spaces or backslashes
shellcheck script.sh ::: Flags unquoted variables and other classic bugs

@q Wait until a service is up before the next step
@w Poll for readiness with an overall timeout instead of guessing with sleep.
timeout 120 bash -c 'until curl -fsS http://localhost:8080/health >/dev/null; do sleep 2; done' ::: Wait for an HTTP health check
timeout 60 bash -c 'until nc -z db.internal 5432; do sleep 1; done' ::: Wait for a TCP port
timeout 60 bash -c 'until [[ -f /var/run/myapp.ready ]]; do sleep 1; done' ::: Wait for a file to appear

@q Retry a flaky command with backoff
@w Network calls and cloud APIs fail transiently; a small helper keeps scripts resilient.
@pre
retry() {
  local attempt=1 max=5
  until "$@"; do
    (( attempt >= max )) && { echo "giving up after $max attempts" >&2; return 1; }
    sleep $(( 2 ** attempt )); attempt=$(( attempt + 1 ))
  done
}
retry curl -fsS https://api.example.com/health
@endpre

@q Parse command-line options in a script
@w getopts handles short flags and their arguments.
@pre
usage() { echo "usage: $0 [-e env] [-n] [-v]"; exit 2; }
env=dev dry_run=0
while getopts "e:nvh" opt; do
  case "$opt" in
    e) env="$OPTARG" ;;
    n) dry_run=1 ;;
    v) set -x ;;
    *) usage ;;
  esac
done
shift $(( OPTIND - 1 ))
@endpre

@q Keep secrets out of logs, history and ps
@w Command-line arguments are visible to other users in ps and saved to shell history, and set -x prints everything.
read -rs API_TOKEN && export API_TOKEN ::: Enter a secret without echoing it
curl -H @headers.txt URL ::: Read headers from a file instead of the command line (curl 7.55+)
HISTCONTROL=ignorespace ::: Commands starting with a space aren't saved to history
{ set +x; } 2>/dev/null ::: Turn off tracing before handling secrets

@q Debug a misbehaving script
@w Trace each command with its file and line number.
bash -x script.sh ::: Print every command as it runs
PS4='+ ${BASH_SOURCE}:${LINENO}: ' bash -x script.sh ::: Tracing with file:line prefixes
bash -n script.sh ::: Syntax check without running
shellcheck script.sh ::: Static analysis with explanations

@q Log consistently from a script
@w Timestamped messages on stderr keep stdout clean for data.
log() { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >&2; } ::: A small logging helper
exec > >(tee -a /var/log/myscript.log) 2>&1 ::: Also copy all output to a log file
logger -t myscript "deploy finished" ::: Send a message to the system journal

@q Run the same task across many inputs in parallel
@w xargs -P is available everywhere and is enough for most fan-out jobs.
xargs -P 8 -n 1 ./process.sh < ids.txt ::: Eight at a time, one argument each
find ./images -name '*.png' -print0 | xargs -0 -P 4 -I{} optipng {} ::: Null-safe parallel processing of files
parallel -j 8 ./process.sh {} < ids.txt ::: GNU parallel equivalent, with better output handling


@s cron | Scheduled jobs | Scripting & Automation

@q My cron job isn't running
@w Check that cron fired it, then whether the script failed because of cron's minimal environment.
crontab -l ::: Your scheduled jobs
grep CRON /var/log/syslog | tail   (RHEL: /var/log/cron) ::: Did cron start the job?
journalctl -u cron --since today   (RHEL: -u crond) ::: The same via journald
systemctl status cron ::: Is the cron daemon running?

@q Runs overlap when a job takes longer than its interval
@w A lock file ensures only one copy runs at a time.
flock -n /tmp/report.lock /opt/scripts/report.sh ::: Skip this run if the previous one still holds the lock
flock -w 300 /tmp/report.lock /opt/scripts/report.sh ::: Wait up to five minutes for the lock instead

@q Should I use a systemd timer instead of cron?
@w Timers log to the journal, can catch up on missed runs (Persistent=true) and show when they'll run next.
systemctl list-timers ::: All timers with their last and next run
systemd-analyze calendar 'Mon..Fri 02:30' ::: Check what a schedule expression means
journalctl -u report.service --since today ::: Output of the job the timer started


@s data | JSON & text processing | Scripting & Automation

@q Pull one value out of a JSON API response
@w jq is the standard tool; -r prints raw strings without quotes.
curl -s URL | jq -r '.data.id' ::: A single field
jq -r '.items[] | select(.status=="active") | .name' resp.json ::: Filter an array
jq -r '.items | length' resp.json ::: Count elements
jq -e '.ok' resp.json > /dev/null ::: Exit code reflects the value (handy in scripts)

@q Build JSON safely from shell variables
@w Hand-built JSON breaks on quotes and newlines; let jq handle escaping.
jq -n --arg name "$NAME" --argjson n 3 '{name: $name, replicas: $n}' ::: Construct an object
jq -n --arg msg "$MSG" '{text: $msg}' | curl -sS -H 'Content-Type: application/json' -d @- "$WEBHOOK_URL" ::: Send it straight to an API

@q Compare two JSON files or API responses
@w Sort the keys first so only real differences show up.
diff <(jq -S . a.json) <(jq -S . b.json) ::: Key-sorted diff
jq -s '.[0] == .[1]' a.json b.json ::: true or false

@q Summarize an access log quickly
@w awk and sort cover most one-off log analysis.
awk '{print $9}' access.log | sort | uniq -c | sort -rn ::: Count by HTTP status code (combined log format)
awk '$9 >= 500 {print $7}' access.log | sort | uniq -c | sort -rn | head ::: Paths producing the most 5xx errors
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head ::: Busiest client IPs
grep "$(date +%d/%b/%Y:%H)" access.log | wc -l ::: Requests in the current hour

@q Work with CSV or delimited data
@w cut, sort and awk handle simple CSV; use a real parser when fields contain quoted commas.
cut -d, -f1,3 data.csv | head ::: Select columns
sort -t, -k3,3nr data.csv | head ::: Sort by the third column, numerically descending
awk -F, '{sum += $4} END {print sum}' data.csv ::: Sum a column
column -s, -t < data.csv | less -S ::: Display as an aligned table

@q Edit config text from a script
@w sed handles quick substitutions; keep a backup when editing in place.
sed -n '/^\[database\]/,/^\[/p' app.ini ::: Print one section of an INI file
sed 's/^LOG_LEVEL=.*/LOG_LEVEL=debug/' .env ::: Preview a substitution (prints only)
sed -i.bak 's/^LOG_LEVEL=.*/LOG_LEVEL=debug/' .env ::: Apply it in place with a .bak copy
envsubst < config.tpl > config.yml ::: Fill ${VARS} in a template from the environment

@q Encode, decode or hash something
@w Common in auth headers, secrets and integrity checks.
echo -n 'user:pass' | base64 ::: Base64 encode (-n avoids encoding a newline)
echo 'dXNlcjpwYXNz' | base64 -d ::: Decode
cut -d. -f2 <<< "$JWT" | tr '_-' '/+' | base64 -d 2>/dev/null | jq ::: Peek at a JWT payload (padding may need adding)
sha256sum release.tar.gz ::: Checksum for verifying downloads
openssl rand -hex 32 ::: Generate a random secret


@s db | Databases & caches | Application Ops

@q The app can't connect to the database
@w Work up the stack: DNS, then the TCP port, then authentication, then the database itself.
getent hosts db.internal ::: Does the hostname resolve?
nc -zv -w 5 db.internal 5432 ::: Is the port reachable? (3306 MySQL, 6379 Redis)
pg_isready -h db.internal -p 5432 ::: Is Postgres accepting connections?
psql "host=db.internal user=app dbname=app sslmode=require" -c 'select 1' ::: Full login test
mysql -h db.internal -u app -p -e 'select 1' ::: The same for MySQL

@q "Too many connections" or the connection pool is exhausted
@w Count connections by client and state to find the leak or the misconfigured pool.
ss -tn state established '( dport = :5432 )' | wc -l ::: Connections from this host to Postgres
psql -c "select client_addr, state, count(*) from pg_stat_activity group by 1,2 order by 3 desc" ::: Connections by client and state, as the database sees them
psql -c "select pid, now()-query_start as runtime, left(query,80) from pg_stat_activity where state <> 'idle' order by 2 desc limit 10" ::: Longest-running queries

@q Check Redis health and memory
@w redis-cli exposes stats, latency and the biggest keys.
redis-cli -h cache.internal ping ::: Should answer PONG
redis-cli -h cache.internal info memory | grep -E 'used_memory_human|maxmemory_human' ::: Memory use vs limit
redis-cli -h cache.internal --latency ::: Ongoing latency samples
redis-cli -h cache.internal --bigkeys ::: Largest keys per type (scans the keyspace; run off-peak)


@s deploy | Deployments & releases | Application Ops

@q Which version is deployed on this server?
@w Confirm what's actually running before you debug.
readlink -f /opt/myapp/current ::: The release the "current" symlink points at
cat /opt/myapp/current/VERSION ::: A version file written at build time
systemctl show myapp -p ExecMainStartTimestamp ::: When the running process started
curl -s localhost:8080/version ::: Ask the app itself, if it exposes a version endpoint

@q Switch releases without downtime, and roll back quickly
@w Deploy each release into its own directory and repoint a symlink in a single step. Rolling back means pointing it at the previous release.
ls -1t /opt/myapp/releases | head ::: Available releases, newest first
ln -sfn /opt/myapp/releases/v42 /opt/myapp/current ::: Repoint "current" to the new release
sudo systemctl reload-or-restart myapp ::: Pick up the new code
ln -sfn /opt/myapp/releases/v41 /opt/myapp/current && sudo systemctl restart myapp ::: Roll back to the previous release

@q Check that a deploy is healthy before calling it done
@w Verify the process, the port, the health endpoint and the error rate.
systemctl is-active myapp ::: Should print "active"
curl -fsS localhost:8080/health ::: Health endpoint responds
journalctl -u myapp --since "5 min ago" -p err --no-pager ::: No new errors since the deploy
for i in $(seq 20); do curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/; done | sort | uniq -c ::: Quick status code distribution

@q Verify an artifact before installing it
@w Checksums catch corrupted or tampered downloads.
sha256sum -c release.tar.gz.sha256 ::: Compare against a published checksum file
gpg --verify release.tar.gz.asc release.tar.gz ::: Verify a signed release
tar -tzf release.tar.gz | head ::: Check the archive's contents before extracting

</script>

<script>
(function(){
  "use strict";
  var raw = document.getElementById("data").textContent.split("\n");
  var sections = [], sec = null, card = null, inPre = false, buf = [];
  raw.forEach(function(line){
    if (inPre){
      if (line.trim() === "@endpre"){ if (card) card.items.push({pre: buf.join("\n")}); buf = []; inPre = false; }
      else buf.push(line);
      return;
    }
    var t = line.trim();
    if (!t) return;
    if (t.indexOf("@s ") === 0){
      var p = t.slice(3).split("|").map(function(x){ return x.trim(); });
      sec = {id:p[0], title:p[1], group:p[2], cards:[]}; card = null; sections.push(sec); return;
    }
    if (!sec) return;
    if (t.indexOf("@q ") === 0){ card = {q:t.slice(3), why:"", items:[]}; sec.cards.push(card); return; }
    if (t.indexOf("@w ") === 0 && card){ card.why = t.slice(3); return; }
    if (t.charAt(0) === "@" && t !== "@pre") return;
    if (t === "@pre"){ inPre = true; return; }
    if (!card) return;
    var parts = line.split(" ::: ");
    card.items.push({cmd: parts[0].trim(), desc: (parts[1]||"").trim()});
  });

  var grid = document.getElementById("grid"), nav = document.getElementById("nav");
  function el(tag, cls, txt){ var e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; }
  function copyable(node, text){
    node.title = "Click to copy";
    node.addEventListener("click", function(){
      try { navigator.clipboard.writeText(text).then(function(){ node.classList.add("copied"); setTimeout(function(){ node.classList.remove("copied"); }, 900); }, function(){}); } catch(e){}
    });
  }

  // sidebar tools
  var tools = el("div","tools"), bOpen = el("button", null, "Expand all"), bClose = el("button", null, "Collapse all");
  tools.appendChild(bOpen); tools.appendChild(bClose); nav.appendChild(tools);

  var groups = [], groupMap = {}, n = 0, totalCmds = 0;
  sections.forEach(function(s){
    // main content
    var sn = el("section","sec"); sn.id = s.id;
    var head = el("div","sec-head"); head.appendChild(el("h2", null, s.title)); head.appendChild(el("span","tag", s.group)); sn.appendChild(head);
    s.cardObjs = [];
    // sidebar: group > topic > questions
    var g = groupMap[s.group];
    if (!g){
      var gd = el("details","grp"); var gs = el("summary"); gs.appendChild(document.createTextNode(s.group));
      var gc = el("span","c"); gs.appendChild(gc); gd.appendChild(gs); nav.appendChild(gd);
      g = groupMap[s.group] = {node:gd, count:gc, topics:[]}; groups.push(g);
    }
    var td = el("details","topic"), ts = el("summary"); ts.appendChild(document.createTextNode(s.title));
    var tc = el("span","c", String(s.cards.length)); ts.appendChild(tc); td.appendChild(ts);
    var ul = el("ul"); td.appendChild(ul); g.node.appendChild(td);
    s.navTopic = td; s.navCount = tc; g.topics.push(s);

    s.cards.forEach(function(c){
      n++;
      var id = "q" + n, cn = el("article","card"); cn.id = id;
      var hay = (c.q + " " + c.why + " " + s.title + " " + s.group).toLowerCase();
      var h = el("h3"); h.appendChild(el("span","n", (n < 10 ? "0" : "") + n)); h.appendChild(document.createTextNode(c.q)); cn.appendChild(h);
      if (c.why) cn.appendChild(el("p","why", c.why));
      var box = el("div","cmds");
      c.items.forEach(function(it){
        if (it.pre != null){ var pre = el("pre","block", it.pre); copyable(pre, it.pre); box.appendChild(pre); hay += " " + it.pre.toLowerCase(); return; }
        totalCmds++; hay += " " + (it.cmd + " " + it.desc).toLowerCase();
        var r = el("div","row"), cm = el("div","cmd", it.cmd); copyable(cm, it.cmd);
        r.appendChild(cm); r.appendChild(el("div","desc", it.desc)); box.appendChild(r);
      });
      cn.appendChild(box); sn.appendChild(cn);
      var li = el("li"), a = el("a", null, c.q); a.href = "#" + id; li.appendChild(a); ul.appendChild(li);
      s.cardObjs.push({node:cn, hay:hay, li:li});
    });
    s.node = sn; grid.appendChild(sn);
  });
  if (groups[0]) groups[0].node.open = true;

  var allDetails = nav.querySelectorAll("details");
  bOpen.addEventListener("click", function(){ for (var i=0;i<allDetails.length;i++) allDetails[i].open = true; });
  bClose.addEventListener("click", function(){ for (var i=0;i<allDetails.length;i++) allDetails[i].open = false; });

  var stats = document.getElementById("stats");
  var netCount = sections.filter(function(s){ return /SSH|Network|Name Resolution/.test(s.group); }).reduce(function(a,s){ return a + s.cards.length; }, 0);
  [[n, "problems covered"], [netCount, "networking & SSH"], [totalCmds, "commands"]].forEach(function(x){
    var d = el("div","stat"); d.appendChild(el("b", null, String(x[0]))); d.appendChild(el("span", null, x[1])); stats.appendChild(d);
  });

  var q = document.getElementById("q"), count = document.getElementById("count"), empty = document.getElementById("empty");
  function apply(){
    var terms = q.value.toLowerCase().trim().split(/\s+/).filter(Boolean), shown = 0, filtering = terms.length > 0;
    groups.forEach(function(g){
      var gv = 0;
      g.topics.forEach(function(s){
        var vis = 0;
        s.cardObjs.forEach(function(c){
          var ok = terms.every(function(t){ return c.hay.indexOf(t) > -1; });
          c.node.classList.toggle("hide", !ok); c.li.classList.toggle("hide", !ok); if (ok) vis++;
        });
        s.node.classList.toggle("hide", filtering && vis === 0);
        s.navTopic.classList.toggle("hide", filtering && vis === 0);
        s.navCount.textContent = String(vis);
        if (filtering && vis) s.navTopic.open = true;
        gv += vis;
      });
      g.node.classList.toggle("hide", filtering && gv === 0);
      g.count.textContent = String(gv);
      if (filtering && gv) g.node.open = true;
      shown += gv;
    });
    count.textContent = filtering ? shown + " of " + n + " match" : n + " problems";
    empty.style.display = shown ? "none" : "block";
  }
  q.addEventListener("input", apply);
  document.addEventListener("keydown", function(e){
    if (e.key === "/" && document.activeElement !== q){ e.preventDefault(); q.focus(); }
    if (e.key === "Escape" && document.activeElement === q){ q.value = ""; apply(); }
  });
  apply();
})();
</script>
<div id="scrim"></div>
<button id="top" aria-label="Back to top">↑</button>
<script>(function(){var nb=document.getElementById("navbtn"),sc=document.getElementById("scrim"),nv=document.getElementById("nav");nb.addEventListener("click",function(){document.body.classList.toggle("nav-open")});sc.addEventListener("click",function(){document.body.classList.remove("nav-open")});nv.addEventListener("click",function(e){if(e.target.closest("li a"))document.body.classList.remove("nav-open")});var b=document.getElementById("top");addEventListener("scroll",function(){b.classList.toggle("show",scrollY>800)},{passive:true});b.addEventListener("click",function(){scrollTo({top:0,behavior:"smooth"})});})();</script>
</body>
</html>
HTML_EOF
}

#  Run the script.
#  "$@" passes along every option the user typed.
main "$@"
