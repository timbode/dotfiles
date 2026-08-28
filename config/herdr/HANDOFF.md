# herdr — handoff notes

Working notes for whoever (human or agent) picks this up later: what was set up,
why it is shaped this way, and where the sharp edges are.

> **Not wired into `bootstrap.sh`.** Unlike `starship`/`eza`/`atuin`, nothing in
> this directory is symlinked into `~/.config/`. The live files listed below are
> real files on each machine, created by hand. Running `bootstrap.sh` does **not**
> install or configure herdr. Wiring it in is an open option, not a done thing.

## What herdr is used for here

A terminal workspace manager (tmux-like) for AI coding agents: a background
server owns the real terminal processes, clients attach to render them, so panes
survive detach, terminal close, and SSH disconnect. It also detects coding agents
in panes and shows each one's state (`working` / `blocked` / `done` / `idle`).

The setup spans one Mac plus four remote machines.

## Installed

| Machine | Version | How | Path |
|---|---|---|---|
| Mac (local) | 0.8.2 | `brew install herdr` | `/opt/homebrew/bin/herdr` |
| `quicopt` | 0.8.2 | official `install.sh` | `~/.local/bin/herdr` |
| `simulations_tb` | 0.8.2 | official `install.sh` | `~/.local/bin/herdr` |
| `quicoptapi` | 0.8.2 | official `install.sh` | `~/.local/bin/herdr` |
| `tryquicoptapi` | 0.8.2 | official `install.sh` | `~/.local/bin/herdr` |

All remotes are Linux x86_64. `quicopt` and `simulations_tb` are reached via
`ProxyJump` through the `Jump` bastion (defined in `~/.ssh/config`); the other two
connect directly. Versions must match across client and server — the client/server
protocol is versioned.

## Architecture

- **One herdr server per machine.** There is no cross-machine view: the sidebar
  rolls up agents per *server*, so each machine's agents are visible only in that
  machine's UI. `herdr-agents` (below) exists to fill that gap.
- **Unix sockets only**, mode `0600`. No `TcpListener` anywhere in the codebase.
- **Local server runs under launchd** via `brew services start herdr`, so it has
  `PPID 1`. It is independent of any terminal and restarts at login. This is what
  makes local sessions survive; a server started from a shell dies with it.
- **Remote panes persist regardless of whether the Mac is connected.** Each remote
  server runs on its own machine. Verified by killing a local remote-client and
  finding the remote server still `running`. Connecting is a *viewing* decision,
  not a persistence one.

Layout in use: **one workspace per machine** — `Mac` (local, rooted at `~`, never
attached to anything) plus one per remote host, each holding a single pane
running `herdr --remote <host>`. `ctrl+b w` (workspace picker) switches between
them.

Only workspaces appear in the spaces sidebar; tabs do not. That is why the layout
is workspace-per-machine rather than tabs inside one container — an earlier
`remotes`-workspace-with-four-tabs arrangement put every machine behind a single
sidebar entry.

## Configuration

### Local — `~/.config/herdr/config.toml`

```toml
[experimental]
allow_nested = true
```

**Required.** Without it, `herdr --remote <host>` run inside a herdr pane exits
with `nested herdr is disabled by default`, which breaks the entire one-tab-per-host
layout. The guard is at `src/main.rs:595`, on the client path — note that the
`--remote` branch further down at `:810` is reached *after* it, so remote attach
does **not** bypass the check.

**This is the main fragility of the setup.** `allow_nested` is an *experimental*
flag; it can be renamed or removed on upgrade. If a herdr update suddenly breaks
the remote tabs, check this key first.

### Remotes — `~/.config/herdr/config.toml` on each of the four hosts

```toml
[ui]
sidebar_start_collapsed = true
hide_tab_bar_when_single_tab = true
```

Each remote's UI is rendered *inside* a pane of the Mac's herdr, so without this
two sidebars and two tab bars stack up and consume roughly 26 columns before any
actual terminal content.

**These are start-time settings.** `herdr server reload-config` does **not** apply
them — the remote server must be restarted to pick them up. Restarting a remote
server **kills its pane processes**, so check what is running there first
(`herdr pane list` on that host).

## Scripts — `~/.local/bin/`

### `herdr-remotes`

Creates or reconnects one workspace per machine.

```bash
herdr-remotes                          # ensure a workspace per machine, attach all
herdr-remotes quicopt                  # attach only the named host(s)
herdr-remotes quicopt simulations_tb
herdr-remotes --tabs-only              # create workspaces, attach nothing
herdr-remotes --disconnect quicopt     # drop the viewer for one host
herdr-remotes --disconnect             # drop all viewers
herdr-remotes --help
```

Host list defaults to the four above; override with `HERDR_REMOTE_HOSTS`. The
`Mac` workspace is created if missing and is never attached to anything.

**Idempotent.** Re-running reports `already connected` per host instead of
creating duplicate workspaces.

**Host matching is exact.** `--disconnect quicopt` must not also kill
`quicoptapi`, so the script matches the full `herdr --remote <host>` command line
rather than doing a substring search — a `pkill -f 'herdr --remote quicopt'`
would take down three hosts.

**Disconnecting is not stopping.** It kills only the local viewer process; the
remote server and everything running on it continue.

**Why it exists:** after a reboot, launchd restarts the server and herdr restores
the workspace *shape* — but not the processes that were running in the panes. The
panes come back as idle shells. This script reconnects them.

### `herdr-agents`

Cross-machine agent rollup: lists every agent on the Mac and all four remotes in
one table, over SSH. Answers "which agent is blocked waiting for me?" without
attaching to each machine in turn. Exists because herdr's own sidebar is
per-server.

> **Untested path:** only the empty-agent-list case has been exercised. The
> formatting for a *populated* list has never actually run. If a column looks
> wrong the first time a real agent shows up, that is why.

## Costs (measured, idle)

| | |
|---|---|
| Per attached host | ~31 MB + one SSH connection |
| Full setup (server + client + 4 attached) | ~1.5% CPU, ~207 MB |

Negligible on a modern Mac. The real costs of attaching everything are startup
latency (four SSH handshakes, two through the bastion) and screen chrome — not
CPU or memory. Since remote persistence does not depend on being connected,
attaching only the machines actually in use is free of downside.

## Privacy / supply chain

Audited from source before install:

- Apache-2.0, ~33k stars, full Rust source public at `github.com/herdrdev/herdr`.
- **No telemetry.** No analytics/sentry/posthog/etc. integration.
- **No POST anywhere** in the codebase. Session and pane content never leaves the
  machine.
- **No `TcpListener`** — all IPC is over unix domain sockets at mode `0600`.
- Only outbound calls are GETs, all for version/detection metadata:
  - `herdr.dev/latest.json`
  - `herdr.dev/preview.json`
  - `herdr.dev/agent-detection/index.toml`
  - `formulae.brew.sh/api/formula/herdr.json`

To silence those entirely:

```toml
[update]
version_check = false
manifest_check = false
```

Note the local socket is the real trust boundary: any process running as the same
user can connect to it and read or drive the panes. Same as tmux, but worth
knowing given the panes hold coding agents.

## Gotchas

- **`reload-config` does not apply start-time settings.** Anything that defines an
  *initial* state (e.g. `ui.sidebar_start_collapsed`) needs a server restart, not
  a reload. This is easy to miss because `reload-config` exits successfully.
- **Nested prefix.** With a remote herdr rendered inside a local pane, the *outer*
  herdr consumes `ctrl+b` first. To send the prefix to the inner session, press it
  twice — e.g. toggling the inner sidebar is `ctrl+b` `ctrl+b` `b`
  (`keys.toggle_sidebar` defaults to `prefix+b`).
- **Inconsistent CLI output formats.** Most subcommands emit a JSON envelope
  (parse `.result`), but `herdr status server` emits plain **text**, and
  `herdr pane run` emits **nothing**. Scripts must not blindly `json.loads`
  every command's stdout.
- **`~/.local/bin` is not on the remotes' `PATH`.** Harmless for `herdr --remote`,
  which execs the absolute path (`src/remote/attach.rs:779` probes
  `$HOME/.local/bin/herdr`). But a bare `herdr` typed in a plain SSH session on
  those hosts will not resolve — relevant for the phone/SSH workflow.
- **Only workspaces appear in the spaces sidebar**, not tabs. Adding a tab for a
  machine will not make it show up in that list; it needs a workspace.
- **The daemon inherits launchd's `PATH`, not the login shell's.** It runs with
  `/Library/TeX/texbin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`
  — no `~/.local/bin`, which is where `claude` lives. Consequence: the settings →
  integrations page reports every agent CLI as "not found". This does **not**
  affect agent detection (that reads the pane's rendered screen, and panes spawn a
  login shell with the full `PATH`); it only blocks installing integrations from
  that UI. Install them from a normal shell instead.
- **Do not try to fix that `PATH` via the plist.** `brew services stop` *deletes*
  `~/Library/LaunchAgents/homebrew.mxcl.herdr.plist`, and `brew services start`
  regenerates it from the formula — any `EnvironmentVariables` block added by hand
  is silently wiped. A durable fix needs a hand-written LaunchAgent outside brew's
  management.
- **`herdr server stop` does not stop the daemon.** The launchd job sets
  `KeepAlive=true`, so it is restarted within about a second with a new PID. The
  stop still kills every pane, so the net effect is losing all local panes for
  nothing. Use `brew services stop herdr` to actually bring it down.

## Claude Code integration

Installed (`herdr integration install claude`, integration v8). It writes
`~/.claude/hooks/herdr-agent-state.sh` and adds a `SessionStart` hook entry to
`~/.claude/settings.json` — both of which are symlinks into `~/dotclaude`, so the
change lands in that repo, not this one. Committed there on branch
`herdr/claude-integration`.

What it provides is **native session restore only**: the hook reports Claude
Code's session identity to the local herdr socket, letting herdr reattach a Claude
session after a server restart instead of leaving an idle shell. Agent *state*
(`working`/`blocked`/`done`) comes from screen-manifest detection with or without
it.

The hook command was rewritten from the absolute path herdr's installer emits to
`bash "$HOME/.claude/hooks/herdr-agent-state.sh" session`, matching the `$HOME`
convention the rest of `~/dotclaude` uses for cross-machine portability. Note the
inner quotes must be escaped in JSON; an unescaped rewrite silently produces an
invalid `settings.json`. `herdr integration status` still reports `current (v8)`
after the change, as it validates the hook script rather than the command string.

Reverse with `herdr integration uninstall claude`, which removes the hook entries
and deletes the script.
