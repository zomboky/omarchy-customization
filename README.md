# Omarchy Customization

A personal collection of small tools for [Omarchy](https://omarchy.org/) (Arch +
Hyprland + the Quickshell `omarchy-shell` bar). Each tool is **self-contained**,
**installable in one command**, and **never overwrites a config without a
timestamped backup**.

Nothing here touches `/usr/share/omarchy/` — everything lands in `~/.config/`, so
it survives `omarchy update`.

## Tools

| Tool | What it does |
| --- | --- |
| [`netspeed`](netspeed/) | Live download/upload rate in the bar, in MB/s, with direction arrows. |

## Install

```bash
git clone https://github.com/zomboky/omarchy-customization.git ~/Documents/omarchy-customization
cd ~/Documents/omarchy-customization

./install.sh            # install every tool
./install.sh netspeed   # or just one
```

Re-running an installer is safe: each one detects an existing install and leaves
it alone.

## Uninstall

Per tool:

```bash
./netspeed/uninstall.sh
```

## Requirements

- Omarchy (for the `omarchy-shell` bar and the `omarchy` CLI).
- `bash`, `jq`, `coreutils`, `iproute2` — `jq` is the only non-default one
  (`omarchy pkg add jq`).

## Repo layout / conventions

```
install.sh              dispatches to every <tool>/install.sh
<tool>/
  README.md             what it is, screenshots, config, limitations
  install.sh            idempotent; backs up anything it edits under ~/.config
  uninstall.sh          reverts install.sh
  bin/                  the scripts that get copied into ~/.config/omarchy/...
  screenshots/          images used by the tool README
```

Rules every tool follows:

- **Idempotent install** — running it twice changes nothing the second time.
- **Backup before edit** — any file under `~/.config/` is copied to
  `<file>.bak.<epoch>` before modification.
- **No source-tree edits** — `/usr/share/omarchy/` is read-only; customizations
  go to `~/.config/`.
- **Reversible** — every `install.sh` has a matching `uninstall.sh`.
