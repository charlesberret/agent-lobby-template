# agent-lobby-template

A pattern for letting an untrusted coding agent visit one directory on your Mac without handing it
the rest of the machine, and for being honest about what actually confines it.

The idea is a **lobby**: a pad (a directory) the visitor may read, a place for it to leave a note,
and a guestbook you keep. The part worth copying is the vocabulary. When people say "the sandbox"
they usually mean three different things, and a claim about confinement is only as good as the
wall it names.

## Three walls

1. **Kernel wall: a separate unix user.** Run the visitor as a dedicated account (call it `guest`).
   It cannot read your mode-700 paths such as `~/.ssh`, and it cannot write files it does not own.
   Limit: if your home directory is mode 755, `guest` can still read world-readable files under it.
   Check with `ls -ld ~`. This repository does not script creating the account.
2. **Software wall: an OS sandbox profile.** [`macos/guest.sb`](macos/guest.sb) is a deny-default
   Seatbelt profile: the pad is readable, nothing outside a scratch directory is writable, and the
   only network path is loopback to a local model server on port 11434. Raise it with `sandbox-exec`.
   Limit: Seatbelt does not nest. A process already under one profile may not apply a second, so
   pick one tool for this wall. `sandbox-exec` is also deprecated by Apple, though it still works.
3. **Tool policy: the agent's own rules.** Whatever your agent harness lets you configure about
   which tools it may call. This is the weakest wall, because the agent is the thing being
   constrained. Treat it as a convenience, never as the thing you rely on.

**Your own shell is outside every wall.** If you start an agent from a normal shell in the pad, it
runs as you, with your credentials. Only a launch through the wall counts as a guest visit.

## What was measured

[`tools/probe.sh`](tools/probe.sh) tries eight things and prints `ALLOWED` or `DENIED` for each. Run
inside `macos/guest.sb` on macOS 26.5.2 (2026-10-14), with the script fed on stdin from the pad
directory:

```text
ALLOWED  read a file in the pad
DENIED   write a file in the pad
DENIED   list the owner's home
DENIED   read ~/.ssh
ALLOWED  read /etc/hosts
DENIED   write to /tmp
DENIED   connect to the public internet
ALLOWED  connect to localhost:11434
```

Run without the wall, every line prints `ALLOWED`. That control run is the reason to trust the
`DENIED` lines. The `localhost:11434` line was `ALLOWED` because a local model server was
listening; without one it fails for an unrelated reason, so read it as "not blocked".

## Try it

Host: your Mac. sudo: no. Expected output: the eight lines above.

```bash
git clone https://github.com/charlesberret/agent-lobby-template
cd agent-lobby-template
PAD="$PWD/pad"
TMP="$(mktemp -d /private/tmp/lobby-guest.XXXXXX)"
cd "$PAD"
sandbox-exec -D PAD="$PAD" -D TMP="$TMP" -f ../macos/guest.sb /bin/bash -s -- "$PAD" < ../tools/probe.sh
```

To launch a real visitor, replace `/bin/bash -s ...` with your agent's command. Expect to widen
the read rules for that agent's runtime (its install directory, its shared libraries) and check each
widening with the probe.

## The pad

[`pad/`](pad/) is the skeleton to copy: `AGENTS.md` tells the visitor the rules, `visitors/` is where
you file what each visitor reports, and `GUESTBOOK.md` is your record of who came and what they read.
The visitor cannot write the pad, so it leaves its note in its scratch directory and you file it.

## Not covered

- Creating the `guest` account and running the agent as it (macOS: `sysadminctl`, `sudo -u`).
- Linux. The same three walls apply, with a different sandbox (bubblewrap, Landlock or a container).
- Anything a cloud-hosted model does with what it reads. A visitor on a hosted model can keep
  whatever you let it read. Keep secrets out of the pad.

## Licence

MIT.
