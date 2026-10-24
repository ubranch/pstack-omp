# pstack for oh-my-pi

Install the ubranch fork from your terminal:

```bash
omp plugin marketplace add ubranch/pstack-omp
omp plugin install pstack@pstack-omp
```

This is Lauren Tan's pstack methodology for OMP, updated to official pstack 0.15.32. It continues [negoro26's original port](https://github.com/negoro26/pstack-omp). Upstream workflows, scripts, and MIT attribution remain part of the port.

## Start a task

1. Restart OMP after installation so the new process loads the updated plugin.
2. Run `/poteto-mode on` to pin the workflow. Give it a goal and a check that can pass or fail.
3. Run `/poteto-mode off` when you no longer want the workflow pinned.

The `potetomode` extension handles these commands and restores saved state when you resume, switch, branch, or start a new chat. Explicit saved on or off state takes precedence over the `--poteto` startup default.

OMP runs every other pstack skill as `/skill:<name>`, for example `/skill:poteto-help`. A bare `/ketchup` is sent as plain text. Upstream docs and skills write the bare form; add the `skill:` prefix when you type it.

`/skill:setup-pstack` is optional. Use it when you want to inspect or change model routing. It preserves valid `modelRoles`, `task.agentModelOverrides`, unrelated settings, and permission choices. Changes require your request and consent. The shipped agents inherit the chat model unless you configure an override.

## Upgrade

For an existing ubranch marketplace registration:

```bash
omp plugin marketplace update pstack-omp
omp plugin upgrade pstack@pstack-omp
```

If your `pstack-omp` marketplace still points to negoro26:

1. Copy `~/.omp/marketplaces.json` to a backup file.
2. In the entry whose `name` is `pstack-omp`, change only `sourceUri` to `ubranch/pstack-omp`. Preserve every other entry and field.
3. Refresh the registration and upgrade:

```bash
omp plugin marketplace update pstack-omp
omp plugin upgrade pstack@pstack-omp
```

Adding the same marketplace name again fails. A targeted registry edit avoids removing the existing registration. The marketplace name remains `pstack-omp`, and the plugin ID remains `pstack@pstack-omp`.

To preview a forced reinstall, use `omp plugin install pstack@pstack-omp --force --dry-run`. Only `install` supports `--dry-run`. Use `omp plugin install pstack@pstack-omp --force` if a reinstall is needed.

Keep any local plugin edits before upgrading. Do not delete or replace `~/.omp/agent/config.yml` during this migration.

Restart the OMP process after upgrading. A new chat inside an already-running process may still use the old plugin. Optional `poteto-agent` and `comment-sicko` agents are used only when the live task roster lists them. Agent discovery depends on the OMP version and installation route. The adapter can use another available worker when these agents are absent. Do not enable a broad discovery provider or change permissions just to make an optional agent appear.

## New in the 0.15.32 update

- `/skill:statechart` draws how a system moves between states as a Mermaid chart checked by a TLA+ model, with each bug as a numbered path. It can also turn an agreed chart into a TLA+ skeleton.
- `/skill:create-formal-verification-skill` generates a project skill that formally checks one property tests rarely reach. `/skill:maintain-formal-verification-skill` brings it back in line after the covered code changes.
- `/skill:sharpen` rewrites a prompt deeper, not bigger, and returns the prompt without doing the task.
- `/skill:in-your-own-words` restates the user's goal and problem before work starts.
- `/skill:ketchup-video` catches you up like `/skill:ketchup`, as a short silent slide video with the waiting decisions as text.
- `scripts/worktree-audit.sh` adds a `hold-unpushed` bucket for worktrees whose commits exist nowhere else. The cleanup playbook never forces `git worktree remove`, never uses `rm -rf` or prune to bypass a refusal, and rechecks status right before removal.

The 0.15.19 update added `/skill:ketchup`, `/skill:correct`, `/skill:poteto-help`, `/skill:benchmark-checklist`, and `/skill:principle-explain-the-number`.

The existing playbooks and executable scripts remain upstream-derived. Skill, playbook, and principle counts are generated into the [marketplace description](../../.omp-plugin/marketplace.json) by the sync script, not maintained in this README.

## What differs from Cursor

The port adapts mechanics instead of promising every Cursor feature on OMP. It has three port-owned skills:

| Skill | Responsibility |
|---|---|
| [`pstack-omp`](skills/pstack-omp/SKILL.md) | Dispatch, agent lifecycle, processes, and messaging through the live OMP tool schema and roster. |
| [`omp-mechanics`](skills/omp-mechanics/SKILL.md) | Platform amendments, session privacy, approvals, unavailable capabilities, and operator style precedence. |
| [`setup-pstack`](skills/setup-pstack/SKILL.md) | Inspect selected routing keys and make only explicitly requested, consented changes. |

Read `skill://pstack-omp` before dispatch. There is no per-task `model`, `readonly`, or `isolated` field, and no `hub` tool. A role or permission instruction in a brief is not a sandbox guarantee. Model routing belongs in the operator's configuration, not a Cursor model rule or a copied tool argument.

Named processes use `bash` and returned `proc://` IDs. Agent messages use `write agent://<id>`, and transcripts use `history://`. These APIs do not provide an out-of-session scheduler. Do not promise a cloud worker, isolated checkout, cross-session wake, or automatic deployment when the live environment cannot provide it.

Project safety rules, approval requirements, and your style settings override imported prose. Use only available platform tools. Windows maintainers need native Git Bash for the port scripts, not a WSL shell pointed at the Windows OMP installation.

## Maintain the port

[`PORTING.md`](../../PORTING.md) describes the pinned official source, deterministic regeneration, and the real CLI smoke command. Generated skills and agents are not maintained by hand. Changes belong in the translation rules, a focused patch, or one of the three owned skill directories.

OMP uses `package.json` and the root [marketplace catalog](../../.omp-plugin/marketplace.json), not a shipped `plugin.json` or `.cursor-plugin/plugin.json`. Keep the native package format; the [packaging adaptation](../../PORTING.md#packaging-and-mode-state) explains why the portable manifest is unsupported.

See the root [LICENSE](../../LICENSE) and [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md) for Lauren Tan's upstream license, the original port attribution, and Daniel Sebban's routing contribution.

