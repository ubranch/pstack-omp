# pstack-omp

For a first-time install, run:

```bash
omp plugin marketplace add ubranch/pstack-omp
omp plugin install pstack@pstack-omp
```

If `pstack-omp` is already registered, follow the [upgrade guide](plugins/pstack/README.md#upgrade) instead. It preserves the registry entry and your model configuration.

This [ubranch fork](https://github.com/ubranch/pstack-omp) carries Lauren Tan's pstack engineering workflows for oh-my-pi, updated to official pstack 0.15.32. It continues the [original OMP port by negoro26](https://github.com/negoro26/pstack-omp). The separate `fan-out` plugin remains available with `omp plugin install fan-out@pstack-omp`.

Current skill, playbook, and principle totals are generated into the [marketplace catalog](.omp-plugin/marketplace.json).

Read the [pstack install and upgrade guide](plugins/pstack/README.md) for mode controls, optional agents, and model routing. The 0.15.32 update adds `/statechart`, `/sharpen`, `/in-your-own-words`, `/ketchup-video`, and the formal verification skills, plus a `hold-unpushed` worktree-audit bucket.

The OMP adapter uses the live task schema and agent roster. Read `skill://pstack-omp` before dispatch. Skills do not override your chat model, saved agent routing, permissions, or project safety rules.

For maintainers, [PORTING.md](PORTING.md) describes the official pin, deterministic regeneration, gates, and the real CLI smoke command. [`omp-port/UPSTREAM`](omp-port/UPSTREAM) is the authoritative upstream commit.

OMP discovery uses [`plugins/pstack/package.json`](plugins/pstack/package.json) and the [marketplace catalog](.omp-plugin/marketplace.json). Portable Agent Plugins and Cursor manifest markers are deliberately absent; see the [packaging adaptation](PORTING.md#packaging-and-mode-state).

## Credits and license

Pstack comes from [Lauren Tan's `cursor/plugins/pstack`](https://github.com/cursor/plugins/tree/main/pstack). The runtime adapter incorporates Daniel Sebban's routing work from [dsebban/skills](https://github.com/dsebban/skills). The original OMP port and its attribution remain credited to negoro26.

The fork retains the MIT license and Lauren Tan's copyright. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

