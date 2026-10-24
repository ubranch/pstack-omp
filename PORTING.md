# Pstack on OMP

Use the [consumer install and upgrade guide](plugins/pstack/README.md) to install the ubranch fork. This document explains how the port is built and maintained.

## Official source and pin

The official source is [`cursor/plugins`, subdirectory `pstack`](https://github.com/cursor/plugins/tree/main/pstack), by Lauren Tan under the MIT license. This fork continues [negoro26's original OMP port](https://github.com/negoro26/pstack-omp). Attribution and licenses remain in [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The 0.15.32 update targets official commit `e73df471cd4bd918367e99f3dd9c51bd53ddf5f0`. `omp-port/UPSTREAM` holds the authoritative full 40-character commit SHA for the generated tree. Branch history and a marketplace description are not substitutes for that pin.

`omp-port/sync-upstream.sh` reads the version from the pinned canonical `pstack/plugin.json`, falling back to canonical `pstack/.cursor-plugin/plugin.json` for historical pins. It refreshes native OMP package metadata and the marketplace description, not a shipped copy of the canonical manifest. Generated skill, playbook, and principle counts live in the [marketplace catalog](.omp-plugin/marketplace.json).

The update adds `/statechart`, `/sharpen`, `/in-your-own-words`, `/ketchup-video`, `/create-formal-verification-skill`, and `/maintain-formal-verification-skill`, and carries negoro26's `hold-unpushed` audit bucket and no-force worktree cleanup. The [plugin README](plugins/pstack/README.md#new-in-the-01532-update) describes them.

## Deterministic regeneration

`plugins/pstack/skills` and `plugins/pstack/agents` are build output, except for the three owned directories below. The build:

1. Extracts the official skills and agents at the pin.
2. Applies the ordered translations in `omp-port/rules.sed`.
3. Applies `omp-port/patches/*.patch` with zero fuzz. A patch that no longer applies stops the build.
4. Restores the paths listed in `omp-port/owned.txt` from the working tree. A missing owned path falls back to `HEAD`.

The port owns these directories:

| Directory | Contract |
|---|---|
| `plugins/pstack/skills/pstack-omp` | Dispatch and agent lifecycle through the live schema and roster, plus process and messaging APIs. |
| `plugins/pstack/skills/omp-mechanics` | Non-dispatch platform amendments, privacy, approvals, style precedence, and unavailable capabilities. |
| `plugins/pstack/skills/setup-pstack` | Selected-key routing inspection and explicitly requested, consented configuration changes. |

A direct edit to any other generated skill or agent fails reproducibility and is replaced by regeneration. Put a lasting change in `rules.sed`, a focused patch, or an owned directory. Keep upstream scripts and prose unless a specific OMP mechanic needs adaptation.

Root documentation, the plugin README, extension code, and native package and marketplace metadata are maintained outside the generated skills and agents. The build does not extract upstream `docs/`. There is no local `plugins/pstack/docs/guide/` tree.

## Check for official changes

Run the port scripts from this repository. On Windows, use native Git Bash with the required Git, GitHub CLI, `jq`, and patch utilities available. A WSL shell does not operate on the same OMP installation by default.

```bash
bash omp-port/sync-upstream.sh check
```

Empty stdout and exit code 0 mean no upstream drift since the pin. Otherwise, stdout lists commits that touched `pstack/`, newest first, with the short SHA, date, and subject. A nonempty list is a drift report, not a failed gate.

The resolved target is printed to stderr as `target <full-sha>`. If `SYNC_TARGET_OUT` is set, the script writes that same target to the named file. Automation uses the recorded target rather than resolving a possibly different head later.

## Sync or rebuild

Before syncing, preserve any uncommitted edits to generated skills and agents. A normal sync refuses changes that it would overwrite, except for owned paths.

To build the official 0.15.32 target:

```bash
bash omp-port/sync-upstream.sh e73df471cd4bd918367e99f3dd9c51bd53ddf5f0
```

With no target argument, the script resolves the newest official commit that touched `pstack/`. An explicit target must be a full SHA in that path-filtered history. There is no `build` subcommand.

To rebuild the current pin after editing translations, patches, or owned paths:

```bash
bash omp-port/sync-upstream.sh rebuild
```

`rebuild` does not move the pin. It replaces generated output even when that output has uncommitted changes. Owned working-tree edits survive.

Set `CANON` to reuse a local `cursor/plugins` checkout. The default is `/tmp/cursor-plugins`, which the script creates from the official repository when needed. Use paths understood by the chosen shell.

The pin advances only after the build installs and the derived fields are refreshed. The sync script stages its affected plugin files and native package and marketplace metadata. Review those changes before committing. A successful sync is not a passing release gate.

## Run the gates

After the complete sync and all owned changes have landed:

```bash
bash omp-port/check-port.sh
```

The full gate checks the generated tree, including reproducibility, principle and playbook parity, references, routing translations, unsupported mechanics, and derived metadata. You can pass the canonical checkout as its positional argument or set `CANON`.

If the reproducibility check reports `SKIP`, it has not proved that the tree matches the pin. Restore access to the official checkout and rerun the full gate before release. A failed patch or gate requires a source fix, not a weakened check.

### Real CLI smoke

With OMP and Node.js on your path, run:

```bash
node omp-port/smoke-plugin.mjs plugins/pstack "<catalog-model>"
```

Replace `<catalog-model>` with a model selector from your local OMP catalog. The argument permits startup. The smoke does not call a provider or start assistant inference.

The script launches the real OMP CLI in RPC mode with `--no-session`, the supplied plugin path, and the pin extension explicitly loaded. It sets `PI_CONFIG_DIR=.` in a temporary working directory, isolates `PI_CODING_AGENT_DIR`, `HOME`, and `USERPROFILE`, and removes `OMP_PROFILE` and common credential-bearing environment variables.

It asserts discovery of the six new skills, recorded on/off custom entries and pin toggling within the running process, no assistant inference, and clean exit 0. This is not a disk-persistence or restart-restoration test.

The same command can target an installed plugin directory instead of `plugins/pstack`. It does not test marketplace registration, optional agent discovery, model access, or permission enforcement. Report only the checks actually run.

### Local 0.15.32 verification

These commands were exercised against the local candidate. Paths and the catalog selector below are from the Windows run:

```bash
C:/Users/inspire/scoop/apps/git/current/bin/bash.exe omp-port/check-port.sh /c/Projects/pstack-canonical
node omp-port/worktree-audit.test.mjs C:/Users/inspire/scoop/apps/git/current/bin/bash.exe
node omp-port/smoke-plugin.mjs plugins/pstack anthropic/claude-opus-5-5
```

From `plugins/pstack/skills/poteto-mode/scripts`, the exercised commands were `bun run test` and `bun run typecheck`.

- `check-port.sh`: PASS, including generated-artifact reproducibility and metadata parity. Inventory totals remain in the marketplace catalog.
- Worktree-audit E2E: PASS against real Git worktrees, native OMP session paths, and the audit script. It covers automatic lookup, dotenv/profile precedence, aliases, malformed records, unchanged OMP profile files, and inherited config-overlay isolation, plus `hold-unpushed` for a branch commit with no remote branch, a detached head off base, and unavailable enrichment. Permission-denial cases, control-character filenames, and POSIX XDG cases were explicitly skipped where Windows could not exercise them. The fixture isolates Git repository settings, hooks, signing, and GitHub CLI configuration.
- Native RPC smoke: PASS for the six new skills, recorded on/off custom entries, pin toggling, no inference, and clean exit 0.
- `bun run typecheck`: PASS.
- `bun run test`: 72 passed, 10 failed: nine `orch/orch.test.ts` `withFakeForge` cases and one `watch-pr/github.test.ts` fake-`gh` case. The pristine upstream tree at the same pin fails the same 10 on native Windows, because those fixtures put Bash-shebang fakes on a `:`-joined `PATH`. Those forge fixture paths remain unverified here; the suite is not fully green.

The user configuration and three installation registries remained hash-identical. These are local verification results, not evidence of fork publication, a live installation, or mode-state restoration after restart.

### Repository automation

This fork does not ship the upstream `upstream-sync.yml` workflow. It squash-merged upstream syncs unattended, and GitHub never registered it on the fork, so it could not be disabled through Actions. Run the local sync command and merge reviewed updates instead.

`gate.yml` runs `check-port.sh` on pull requests and pushes to `main`. Its separate Ubuntu audit job installs the official OMP 18.10.2 binary, verifies the pinned SHA-256, and runs the native worktree-audit E2E, including POSIX dotenv-selected XDG roots. That job must pass before merging or installing this update. It has read-only repository permission. The download token is scoped to the download step, not the test process.

A PR opened by `github.token` does not trigger a separate pull-request workflow. The sync job's gate and the post-merge push gate provide those checks. These workflows do not run `smoke-plugin.mjs` or verify installed marketplace registration.

## OMP runtime contracts

Read `skill://pstack-omp` before dispatch. That adapter is the dispatch authority. It resolves role names against the live task schema and available agent roster. Optional `poteto-agent` and `comment-sicko` agents are used only when discovered. A fresh agent handles a new work item or fix round unless expensive local state makes reuse necessary.

There is no per-task `model`, `readonly`, or `isolated` field and no `hub` tool. Imported prose is not evidence of a sandbox, a cloud worker, or checkout isolation. Use the adapter's supported dispatch form rather than copying literal fields from Cursor examples.

Use `context` and `tasks[]` only when the live schema exposes them. Otherwise issue standalone flat calls with the required `task` and `solutionSpace` fields. Independent flat calls start before waiting. Do not enable batching to make an example fit. The main agent performs authorized pushes, PR mutations, and merges after the existing gates; children return local changes, evidence, and proposed remote actions.

For processes, use `bash` with a unique service name and readiness criteria when needed. Read status and logs from the returned `proc://<id>`. Stop only a process you own with `write proc://<id>/kill`. For agents, read results from `agent://<id>`, read roster and transcripts through `history://`, and send messages with `write agent://<id>`.

These process and messaging APIs do not provide an out-of-session scheduler. Do not promise a background wake, cross-session continuation, or platform-specific daemon without an available, explicitly authorized mechanism.

Session records can contain credentials and private prompts. Follow `omp-mechanics` and its session-store reference. Read the needed context rather than exporting whole transcripts or configurations.

Worktree-audit discovers session directories automatically for this repository's registered worktrees. A read-only helper resolves the native profile and XDG data root directly, without starting OMP or loading its settings. It derives exact buckets from canonical worktree paths. Temp-relative buckets take precedence over home-relative buckets. Windows ignores XDG. The audit never lists the global sessions root, searches unrelated buckets, migrates buckets, initializes profiles, extracts native caches, or invokes a model. Transcript headers must still belong to a registered worktree. Nonmatching header paths are resolved against canonical worktree paths so junctions, symlinks, and Windows case variants retain their owner.

Automatic lookup requires Node.js with `node:util.parseEnv`, or Bun with that API, Git with `worktree list --porcelain -z`, and the audit's existing Bash, jq, ripgrep, find, and stat utilities. Node.js is preferred. A Node.js version without `parseEnv` fails closed. Bun is used only when Node.js is absent, with `bun run --no-env-file` to disable implicit dotenv loading. A Node.js execution failure never retries through Bun. Production lookup does not require OMP on `PATH`. `PI_CODING_AGENT_SESSION_DIR` remains an optional nonempty exact-directory override that bypasses root lookup. Explicit overrides need a JavaScript runner only when a header path does not exactly match a registered worktree. An unset or empty override selects automatic lookup.

The helper privately parses only the fixed native `.env` locations with `node:util.parseEnv`. Locations are frozen before dotenv application. Precedence is the project, initial agent directory, initial profile config root, then initial home, filling only falsy environment values. Uppercase `OMP_` keys override their `PI_` aliases within each file, not in the inherited launch environment. Only directory, profile, home, and temp selectors are retained. The initial profile stays frozen while directory selectors are refreshed. An explicitly empty `OMP_PROFILE` selects default rather than inheriting `PI_PROFILE`. Windows environment lookup is case-insensitive. Git receives the original inherited environment, never dotenv keys. The helper does not read config YAML, JSON, or databases.

A missing automatic bucket means no recorded files. A missing explicit override, unavailable required runtime, invalid selector, conflicting Windows selector spellings, unreadable or non-file dotenv input, unreadable directory, failed canonicalization, malformed transcript header, or failed search or metadata read makes enrichment unavailable. Windows drive-relative agent overrides are unsupported and fail closed. Affected clean candidates get `LAST_CHAT=unavailable` and `verify-session-unavailable`, not `safe`. An unmatched header whose path cannot be resolved is unverified, not evidence of unrelated ownership. Worktree paths containing control characters and a failed initial Git worktree listing stop the audit without cleanup recommendations. Control characters in session paths or headers also fail closed. Lookup supports the native OMP 18.10 session layout, not historical hashed buckets or custom layouts outside an explicit override.

The entrypoint E2E uses native model-free RPC startup only as a test oracle. It seeds sessions at the actual `get_state` session file path, guarded for containment inside the fixture root. Native startup can write isolated fixture state. The audit itself must leave fresh and legacy profile files and cache directories byte-for-byte unchanged. Fixtures remove inherited `PI_CONFIG_FILES` and `OMP_CONFIG_FILES` case-insensitively before subprocesses. Dotenv-selected roots, profile precedence, and Git isolation have entrypoint cases. POSIX XDG cases run only on Linux or macOS, and permission-denial cases report explicit skips where the host cannot enforce them. These new cases await root verification; the earlier verification record above predates the read-only resolver.

## Models, permissions, and platform limits

The operator chooses the chat model with `/model`. `modelRoles` and `task.agentModelOverrides` are operator-owned routing settings. Keep valid existing choices, unrelated entries, and configuration layers. Setup changes require an explicit request and consent. A denied, timed-out, or unavailable consent step stops that mutation.

The shipped agents are model-free. Do not edit an installed agent to add a Cursor model alias, create a thin agent for every role, reset the routing map, or install provider defaults. `/setup-pstack` uses the current configuration contract. The [model-agnostic convention](omp-port/model-agnostic.md) explains the distinction between a capability and a model selector.

Imported autonomy language does not grant permissions. Repository safety rules, approvals, and operator style take precedence. A read-only brief is an instruction, not a read-only sandbox. `/ketchup` stays read-only and does not start a job to manufacture a result or visual.

GitHub, Origin, Graphite, browser, and desktop workflows depend on tools and access actually available in the session. Report an unavailable capability rather than changing merge policy, granting access, or deploying a service to satisfy a playbook. Verification skills are generated for the application, not supplied as proof that this port works.

## Packaging and mode state

OMP discovery uses `plugins/pstack/package.json` and `.omp-plugin/marketplace.json`. The artifact deliberately omits `plugins/pstack/plugin.json`; no `.cursor-plugin/plugin.json` is shipped or needed. Reading the canonical manifest for its version does not make that manifest part of the OMP package.

On OMP 18.10, a root `plugin.json` selects the exclusive, strict Agent Plugins provider. Its six-field frontmatter schema rejects `disable-model-invocation` and pstack-specific fields, hiding most skills. The real RPC smoke failed with that marker and passed without it. The portable manifest is unsupported for this artifact; keep hidden/manual-invocation metadata rather than stripping it to fit that schema.

The native extension entry remains `omp.extensions` in `plugins/pstack/package.json`. The `potetomode` extension supplies `/poteto-mode` pin controls and a short pointer to the skill. It restores explicit saved on or off state before applying the `--poteto` default. The `--no-session` smoke checks recording and toggling in the running process, not disk persistence or restoration after restart.

## Durable port history

The original port used the `backnotprop/pstack` mirror at `18e0e90` on 2026-08-19. That mirror lagged official `cursor/plugins`. Later syncs moved the port to the official source. Never use the mirror as the current parity baseline.

Earlier official syncs added `make-bot-ui` and replaced `poteto-mode/references/plan.md` with `poteto-mode/scripts/check-plan.mjs`. The executable checker remains upstream-derived. Cursor marketplace image assets and `automations/benny` are not part of the OMP skills-and-agents build.

Older install notes described manual agent symlinks and a Claude-plugin discovery workaround. Those notes are historical, not a requirement to enable broad discovery today. The live roster determines whether an agent is available. Earlier claims about isolation, process hubs, or blanket approval mode do not define the current runtime contract.

The runtime adapter incorporates Daniel Sebban's work from [dsebban/skills](https://github.com/dsebban/skills). The ubranch update retains that credit, negoro26's original port credit, and Lauren Tan's upstream copyright.

