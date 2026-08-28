# herdr — handoff notes

> **Superseded — this setup is no longer in use.**
>
> The remote sessions are now reached with one iTerm profile per host running
> `ssh -t <host> tmux new -A -s main` (`config/iterm/hosts.json`). Persistence
> was never the Mac's job: the remote multiplexer owns the panes and keeps them
> alive regardless, which is why the local half can be an ordinary terminal tab.
>
> Running a multiplexer at *both* ends was the whole cost — it is what made
> `ctrl+b` ambiguous, opened new tabs on the wrong machine, and turned a network
> blip into a screenful of retry output. What was lost with it: the agent
> sidebar, which only paid off with several machines busy at once.
>
> Kept for the herdr-specific findings below, several of which took real digging
> and are not in the published docs. `herdr` itself is still installed on the Mac
> and on all four remotes; nothing was uninstalled.


Working notes for whoever (human or agent) picks this up later: what was set up,
why it is shaped this way, and where the sharp edges are.

> **Partly wired into `bootstrap.sh`.** The helper scripts below now live in
> `dotfiles/bin/` and are symlinked into `~/.local/bin/` by `bootstrap.sh`, so they
> reach every machine and survive a wipe. Herdr's own config files
> (`~/.config/herdr/config.toml`, here and on each remote) are still real files
> written by hand — `bootstrap.sh` does not install or configure herdr itself.

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
running `herdr-reconnect <host>` (which supervises `herdr --remote <host>`). `ctrl+b w` (workspace picker) switches between
them.

Only workspaces appear in the spaces sidebar; tabs do not. That is why the layout
is workspace-per-machine rather than tabs inside one container — an earlier
`remotes`-workspace-with-four-tabs arrangement put every machine behind a single
sidebar entry.

## Configuration

### Local — `~/.config/herdr/config.toml`

Tracked as `config/herdr/config.toml` and symlinked by `bootstrap.sh`, **on
Darwin only**: this Mac needs `allow_nested` and the agent-sidebar rows, while
the remotes need the opposite UI settings below. One shared file would break one
end or the other.

```toml
[experimental]
allow_nested = true

[ui.sidebar.agents]
rows = [
  ["state_icon", "agent", "state_text"],
  ["$detail"],
]
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

## Scripts — `dotfiles/bin/`, symlinked into `~/.local/bin/`

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

**Panes run `herdr-reconnect <host>`, not `herdr --remote` directly**, so a
dropped link reattaches itself. Disconnecting therefore kills the supervisor
first and the client second — killing the client alone just makes the supervisor
reattach. A pane counts as connected while its supervisor lives, including
mid-backoff, so re-running the script never stacks two supervisors on one pane.

**Why it exists:** after a reboot, launchd restarts the server and herdr restores
the workspace *shape* — but not the processes that were running in the panes. The
panes come back as idle shells. This script reconnects them.

### `herdr-reconnect`

`herdr-reconnect <host>` re-execs `herdr --remote <host>` whenever it exits
non-zero, backing off 1s → 30s. A clean exit (detaching from the inner session on
purpose) ends the loop.

It exists because a dropped bridge is the one moment this setup feels worse than
plain SSH tabs, even though it is strictly better: the remote server owns the
panes and keeps running, so nothing is lost — but without a supervisor you are
left with a dead pane and a command to retype.

Do **not** try to prevent the drop by adding `ServerAliveInterval` to
`~/.ssh/config`. Herdr writes its own ssh config (`src/remote/attach.rs:1795`)
that `Include`s yours and then appends `ServerAliveInterval 15` /
`ServerAliveCountMax 4`. Since the include comes first and ssh is
first-match-wins, a value in `~/.ssh/config` **overrides** herdr's and makes drop
detection slower. Sixty-second detection is already the intended behaviour; the
supervisor handles what follows.

Failed attempts print herdr's six-line diagnosis only when it is *news* — the
first failure of an outage, or when the text changes. Repeats are suppressed and
each attempt shows as one compact line, thinning to every tenth once an outage is
clearly not brief. Retrying itself is unbounded on purpose: a laptop closed
overnight should be attached again by morning. The earlier version printed every
line of every attempt, which through a real outage buried the pane and made
ctrl-c look like the only way out — the one action that also cancels the
reconnect.

An attempt shorter than five seconds never finished connecting, so it counts as
an outage and keeps growing the backoff; a longer one was a real session that
dropped, and resets it.

### `herdr-agents`

Cross-machine agent rollup: lists every agent on the Mac and all four remotes in
one table, over SSH. Answers "which agent is blocked waiting for me?" without
attaching to each machine in turn. Exists because herdr's own sidebar is
per-server.

The populated path has now run, and the warning that used to sit here was
justified: it read `status` and `name`, neither of which exists, so every live
agent rendered as `?  ?`. The fields are `agent_status` and
`terminal_title_stripped`.

It also skips panes listed in `~/.cache/herdr-agent-feed.json`. Those are the
Mac panes the feed reports into, and their state is a copy of a remote this
table already lists on its own row — without the filter every machine appears
twice. A local pane the feed does not own is a real local agent and still shows.

### `herdr-agent-feed`

Populates the Mac's agent sidebar, which is otherwise permanently empty.

Herdr's agent panel lists local panes only, and every pane on this Mac is a
viewer onto another machine: the foreground process is `herdr`, and the screen
is the remote's TUI chrome rather than a Claude prompt box. The agents are
processes on the remotes. Screen detection cannot see them and no configuration
changes that.

`herdr pane report-agent` is the documented way in — the same mechanism
lifecycle-hook integrations use. The feed polls each remote's own
`herdr agent list` over ssh and reports the rollup against the local pane
displaying that host, so the panel finally answers *which machine is blocked
waiting for me?*

```bash
herdr-agent-feed --dry-run   # print what it would report, touch nothing
herdr-agent-feed --once      # one cycle
herdr-agent-feed --clear     # release every claim, restore screen detection
herdr-agent-feed -v          # foreground, logging each cycle
```

Runs under launchd as `com.dotfiles.herdr-agent-feed`, installed by
`macos/herdr-agent-feed.sh` from a generated plist (generated, not symlinked
like keyremap's: it names an absolute path and launchd does not expand `$HOME`).
Log: `~/Library/Logs/herdr-agent-feed.log`.

Four things the reporting API forces:

- **Reported state outranks screen detection and persists until replaced.** A
  crashed feed would leave a comfortable lie on screen indefinitely. Every exit
  path releases; SIGTERM is turned into the same unwind as ctrl-c so
  `launchctl unload` cleans up; and `~/.cache/herdr-agent-feed.json` lets the
  next run retire claims left by a run that was killed outright.
- **A host running nothing gets no row at all.** Reporting `idle` there invents
  an agent that does not exist, colours the workspace dot as though something
  were waiting, and prints a label that can only repeat the group header above
  it — the panel becomes a second copy of the spaces list. An *unreachable*
  host is a different answer and does get a row, labelled `unreachable`: no
  route and nothing running must not render alike.
- **Identity is (source, label).** A label that follows the remote's window
  title would strand a ghost row on every title change, so a changed label
  releases the old one first. The label is also never the host name, which is
  already the group header: one agent lends its window title, several become
  `N agents` with the tally in the message.
- **One pane carries one state.** A host running several agents collapses
  worst-wins — `blocked` > `working` > `done` > `idle` > `unknown` — which is
  the question being asked anyway. Subagents inside a Claude session remain
  invisible; nothing can fix that (see Gotchas).
- **One entry, but several lines.** The entry ceiling is real (reporting three
  labels to one pane leaves only the last), but `ui.sidebar.agents.rows` renders
  an entry as many lines, and a `$token` line is filled by
  `herdr pane report-metadata --token NAME=VALUE --ttl-ms N`. That is what makes
  `3 agents` / `1 blocked, 2 working` possible. Tokens are **not** namespaced by
  source: `--clear-token` from one source clears another source's token.

Under launchd the PATH is minimal, so the plist supplies one; a missing `herdr`
raises like any other failure rather than escaping as `FileNotFoundError` and
turning a PATH mistake into a restart loop. A cycle that fails logs and waits
instead of exiting, because a crash loop would re-dial all four hosts once per
throttle window.

### `dot-status`

Not herdr-specific, but the tool that keeps this setup honest across machines:
`dot-status` reports, for `~/dotclaude` and `~/dotfiles` on every host, how far
each is from `origin/main`, whether its working-tree changes are real or just
Claude Code rewriting `settings.json`, and whether the installers' symlinks are
actually in place. `--suggest` prints (never runs) the reconciling commands,
bundled one ssh per machine.

The symlink check is the part that matters here: `git pull` updates a checkout
but does not run `install.sh` or `bootstrap.sh`, so a commit that adds a new file
leaves a machine holding content with nothing pointing at it.

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
- **A new tab opens on the Mac, not on the workspace's machine.** Each remote
  workspace is a *local* workspace whose pane happens to render a remote UI, so
  the outer herdr catches `ctrl+b c` and makes a local tab. Use the doubled
  prefix — `ctrl+b` `ctrl+b` `c` — which sends a literal prefix through to the
  inner session (`src/config/keybinds.rs:1029`). `--remote-keybindings server`
  does *not* help: it only selects which keymap file the remote client reads, not
  which herdr receives the keystroke.
- **`report-agent` accepts four states; the rest of the API knows five.**
  `agent list` returns `done` and `agent wait --until` accepts it, but
  `pane report-agent --state done` is rejected outright with *invalid pane agent
  state: done*. Anything mirroring state from one server into another has to map
  `done` onto `idle`, and must do so per host — an unguarded failure escapes the
  per-host loop and freezes every other machine's row, not just the one that
  finished.
- **The agent panel lists panes, not agents.** Per the docs, "each pane has one
  status authority", so one Claude session is one row no matter what runs inside
  it. Subagents have no terminal and no pane, and detection is regex over a
  pane's bottom screen buffer, so they can never be listed. Herdr does *read*
  them — `claude.toml` has a rule `background_agents_working` matching
  `Waiting for N background agents to finish` — but the rule's only output is
  `state = "working"`. The count colours one dot and is discarded.
- **The sidebar is split 50/50 by default.** `sidebar_section_split` in
  `~/.config/herdr/session.json` (persisted UI state, not config — there is a
  drag handler for it). Worth dragging down on any machine where the agents half
  stays sparse.
- **Installing atuin registers Claude Code hooks, uninvited.** atuin 18.20's
  installer adds `atuin hook claude-code` to `PreToolUse`, `PostToolUse` and
  `PostToolUseFailure` (matcher `Bash`), and re-serialises `settings.json` with
  keys sorted alphabetically. Since that file is a symlink into `dotclaude`, a
  routine `bootstrap.sh` quietly produced tracked-config changes on every machine
  and put a second hook beside the git-push guard on every Bash call.

  These have been removed. Note only two of the three show up as *new keys* in a
  diff — the `PreToolUse` one is appended to the array `guard-bash.sh` already
  occupies, so a naive key-level comparison undercounts. The alphabetical
  re-serialisation also makes the diff look like blocks were deleted when they
  were only moved; compare semantically before concluding a guard was dropped.

  They come back on any fresh atuin install. Remove with
  `git -C ~/dotclaude checkout -- claude/settings.json`, which restores the
  tracked file exactly, then confirm `permissions.deny` and `guard-bash` survive.
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
change lands in that repo, not this one, where it is now on `main`.

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
