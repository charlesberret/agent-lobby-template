#!/usr/bin/env bash
# Probe a lobby wall. Run it INSIDE the wall you want to test, for example
#   sandbox-exec -D PAD="$PAD" -D TMP="$TMP" -f macos/guest.sb /bin/bash tools/probe.sh "$PAD"
# or as the guest uid:  sudo -u guest /bin/bash tools/probe.sh "$PAD"
# Each line prints  ALLOWED  or  DENIED  for one attempt. Compare with what you intended.
set -u
PAD="${1:?usage: probe.sh PAD_DIR}"
t() { # t "label" command...
  label=$1; shift
  if "$@" >/dev/null 2>&1; then echo "ALLOWED  $label"; else echo "DENIED   $label"; fi
}
t "read a file in the pad"            cat "$PAD/AGENTS.md"
t "write a file in the pad"           sh -c "echo x > '$PAD/.probe-write'"
t "list the owner's home"             ls "$HOME"
t "read ~/.ssh"                       ls "$HOME/.ssh"
t "read /etc/hosts"                   cat /etc/hosts
t "write to /tmp"                     sh -c "echo x > /tmp/.lobby-probe-$$"
t "connect to the public internet"    /usr/bin/nc -z -G 3 1.1.1.1 443
t "connect to localhost:11434"        /usr/bin/nc -z -G 2 localhost 11434
rm -f "$PAD/.probe-write" "/tmp/.lobby-probe-$$" 2>/dev/null
