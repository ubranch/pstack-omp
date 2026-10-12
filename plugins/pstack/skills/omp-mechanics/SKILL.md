---
name: omp-mechanics
description: "OMP platform amendments for pstack. Read after poteto-mode and before model setup, status lookup, session history, process or UI control, or scheduled work."
disable-model-invocation: true
---

# OMP mechanics

Imported skills keep upstream workflow behavior. This adapter replaces platform-specific mechanics that a text translation cannot supply. `skill://pstack-omp` is the sole contract for role selection, task payloads, messaging, isolation, and agent lifecycles. Follow it instead of task-shaped examples elsewhere.

Skill commands written as `/<name>` in imported skills are typed `/skill:<name>` on OMP; only `/poteto-mode` is registered bare. A `/loop` instruction means the root-owned wake mechanism the runtime actually exposes; without one, report that no wake is available.

## Preserve permissions and response style

OMP system instructions and operator policy govern every skill and playbook. `/poteto-mode`, `/setup-pstack`, an autonomy slogan, or a request to keep working does not expand tool access or approval permissions. Keep configuration, installations, and external actions within the user's authorized scope. A denied capability is not a reason to switch tools to bypass its gate.

OMP's active response style takes precedence over imported reply templates, including `/ketchup`. Retain the requested evidence and decisions without forcing an upstream voice or layout that conflicts with that style.

## Resolve models without changing them

For architect, arena, interrogate, reflect, and other panels, use configured model diversity when the runtime can prove it. Preserve independent participants when only one model is available. Report unavailable diversity or independent execution rather than creating model-specific agents or editing settings to satisfy an example.

For requested model configuration, run `skill://setup-pstack`. [OMP model configuration](references/setup-pstack-config.md) describes the two operator-owned maps and their limits. Agent labels in imported tables are roles, not new live agent names or per-task model selectors.

## Use the available code tools

For bug fixes, use an exposed language server to locate definitions and callers before runtime investigation. When a debugger supports the target, use it to inspect program state before adding logging. Read the tool's live documentation before choosing operations. A delegated agent may have fewer tools than the root. Do not enable tools or change plan mode to escape that restriction.

For features and refactoring, use available language-server references and rename operations, then inspect string literals and prose that symbol refactors cannot reach. Treat diagnostics as evidence only for the files and checker actually covered. An unavailable or failed server does not prove the code is clean. Use the project's real checks when authorized, following the root-only verification contract in `skill://pstack-omp`.

Skill `globs` metadata does not guarantee automatic attachment on OMP. Read `skill://typescript-best-practices` when working on TypeScript files.

## Locate installed sources and programs

For multi-phase plans, resolve script and reference paths from the loaded skill location. Do not assume a global plugin directory or that installed files are vendored in the product repository. Product-owned source pointers stay relative to that repository and its evidence generation.

For swarm and orchestrate, the root dispatches participants through `skill://pstack-omp`. Track owners return briefs for the root to dispatch. A collaboration UI is not an agent messaging API and does not authorize access to another session's workers.

## Report scheduling capabilities honestly

A background process does not schedule a future assistant turn. Agent results and service logs do not prove a durable wake chain exists.

Use a loop, goal, scheduler, or inbound event only when the session actually exposes it and its documented behavior fits the request. Do not enable it or install a timer merely because an upstream playbook mentions one. With no scheduler exposed, report that unattended wakeups are unavailable. Continue work that can finish in the active session, or leave a precise resume condition when the workflow requires a later wake. Do not invent a `/loop`, webhook, or operating-system timer.

## Keep ketchup read-only

`/ketchup` summarizes this chat since the user's preceding message. Notifications and agent reports are not user messages. Include unresolved user decisions even if they predate that message.

Use existing chat evidence and read-only status lookups for the agents, jobs, PRs, and CI runs this chat touched. Scope agent and process reads through `skill://pstack-omp`. Query a forge's status-only operation, not a watch or drive mode. Do not launch or resume workers, start jobs or apps, change code or settings, or post externally to improve the report.

Distinguish current observed state from the last known state. If a status tool, scope, permission, or identifier is unavailable, say which status could not be checked. A missing result or an old timestamp proves neither completion nor liveness. Link only existing artifacts. An inline table or diagram may use already observed facts without creating a file.

## Control processes and interfaces

Inspect the current runtime and host OS before choosing a driver. Use the live `bash` service contract for a server, with a unique name and a documented readiness predicate. Both log and port predicates must pass when both are supplied. A readiness timeout is not proof that the process stopped. Read its returned process status and logs before deciding what happened.

Use browser or desktop automation only when exposed. On runtimes that provide browser or computer helpers through `eval`, read those helpers' documentation before use. A navigation invalidates element references. Re-observe before acting. Prefer accessibility information and do not mix accessibility coordinates with screenshot pixels. Cite actual driver output as verification evidence.

Persist a browser session or a service only when the authorized workflow requires it and the live API supports it. Do not assume a helper, CLI, POSIX shell, desktop, browser profile, or Tailscale connection exists. Windows, macOS, Linux, and remote hosts can require different commands and access. Never substitute a desktop or shell driver to bypass a restricted director's tools.

Before using make-bot-ui, read [make-bot-ui on OMP](references/make-bot-ui-on-omp.md). Local HTTP UI work can be supported without claiming an inbound assistant webhook or hidden secret card exists.

## Read only authorized session history

For recall, reflect, eval, session-pickup, show-me-your-work, and automate-me, read [OMP session history](references/session-store-on-omp.md) before looking on disk. Prefer current-scope internal resources when available. Resolve the active profile and session root rather than assuming a workstation path.

Stay within the authorized session and project. Do not glob sibling project buckets or expose unrelated transcripts, credentials, or provider configuration. A raw transcript can contain material before a context reset. Do not treat that material as current context or silently widen a pickup to include it.

## Treat foreign integrations as optional

Cursor-specific babysit warnings, Custom Modes, Grok Bot routine panels, and `api2.cursor.sh` are not OMP capabilities. Use the selected pstack playbook and report any unavailable integration. Assess review-bot findings against repository evidence rather than trusting their origin.

Graphite and Origin are optional external CLIs. Use only a forge tool or CLI actually available and authorized for the workflow. Do not install a missing tool or claim GitHub operations replace unsupported stack semantics. Cursor cache cleanup applies only if the user explicitly authorized that product and its actual path on the host.
