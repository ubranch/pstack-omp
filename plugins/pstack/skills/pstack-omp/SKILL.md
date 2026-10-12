---
name: pstack-omp
description: "Route pstack delegation through live OMP tools. Read before dispatching standalone briefs, panels, owners, or watchers."
---

# pstack on OMP

`skill://poteto-mode` selects the playbook, roles, steps, and gates. This file is the sole dispatch and agent-lifecycle contract for the port. Read it before following delegation examples in imported skills. `skill://omp-mechanics` owns the other platform amendments.

OMP system instructions, operator permissions, approval policy, and response style take precedence. A skill command or an upstream autonomy slogan grants no additional permission. Keep operator model configuration unchanged unless the user explicitly requests a configuration change through `skill://setup-pstack`.

## Resolve the live tools and roles

Inspect the current tool schemas and agent roster. Use `task` when exposed. If only another worker runtime is exposed, read its live documentation and translate the same ownership and acceptance requirements. Do not assume task fields, worker tiers, messaging, or isolation carry over.

With no worker tool, do permitted bounded work directly. Report any gate that requires independent execution as unavailable. One session cannot impersonate an independent panel.

Select the most specific listed agent for the work:

| Role | Agent preference when listed |
|---|---|
| Repository explorer | `scout`, with a read-only assignment |
| Code reviewer or evidence synthesizer | `reviewer` |
| Security reviewer | `security-reviewer`, with a read-only assignment |
| Mechanical worker | `sonic`, for fully specified changes |
| Implementer, planner, designer, researcher, or owner | An appropriate listed specialist, otherwise the default worker |
| One-shot watcher | A read-only specialist with the required observation tools, otherwise the default worker |

Omit `agent` for the default worker. Use `poteto-agent` or `comment-sicko` only when the live roster lists that exact name and the assignment fits it. Otherwise give an available worker the relevant instructions and file pointers. Do not create agent definitions merely to satisfy an imported role or model example.

Agent selection is not model selection. Record resolved-model and fallback metadata when the runtime returns it. Different contexts do not prove different models or providers. If model diversity cannot be established, retain required independent contexts and report the limitation.

## Write a standalone brief

Children start without the parent conversation. Each assignment must contain:

- Target: the outcome, role, repository or worktree, writable paths, forbidden paths, and output artifact.
- Change: source pointers, the settled contract, constraints, dependencies, the base SHA or generation, and decisions already made.
- Acceptance: observable done predicates, required evidence, allowed verification commands or a root-only verification rule, report format, and stop conditions.

Put shared immutable material in `context` only when that field is exposed. Otherwise embed it in each standalone brief or point each brief to an authorized, accessible artifact. A file pointer does not replace the goal or write ownership. Ordinary children do not spawn children, ask the user, or run shared checks unless the root explicitly assigns that responsibility. When `yield` is exposed, require a terminal result as `data` or a failure as `error`, never both. Reports name only checks actually executed.

## Dispatch through task

Choose the payload from the live schema, preserving the operator's `task.batch` setting:

| Native setting and exposed schema | Supported payload |
|---|---|
| `task.batch: true`, with `tasks[]` and `context` | `{ context: "<shared Goal, Constraints, Contract>", tasks: [{ task: "<standalone brief>", solutionSpace: "<remaining decisions>" }] }` |
| `task.batch: false`, with flat `task` and `solutionSpace` | `{ task: "<standalone brief including shared context or its authorized artifact>", solutionSpace: "<remaining decisions>" }` |

Each participant requires `task` and `solutionSpace`. The latter states which decisions remain open, not the volume of work. With `tasks[]`, start genuinely independent participants in one batch. With a flat schema, start one participant per call and issue all independent calls before waiting; do not send `tasks[]` or `context`. Include an intent field such as `i` only when the live schema exposes or requires it.

Use optional `name`, `agent`, `outputSchema`, `schemaMode`, or `tools` only when exposed and needed. Give named participants unique names that meet the live schema. Omit `effort` and per-call model overrides. Do not assume `readonly`, `isolated`, `apply`, or `merge` fields. Never enable `task.batch` or change operator settings to make an imported example callable.

A read-only brief is not a sandbox. Prefer a listed restricted specialist and still state the write ban. An exposed `tools` field refers to documented eval-defined tools, not an arbitrary grant of built-in tools.

Give concurrent writers disjoint paths or explicitly arranged worktrees. Without returned isolation evidence, assume they share the workspace. Branch switching in a shared checkout is not isolation. Honor the runtime's concurrency limit without overriding it.

## Collect results and send messages

Record the identifiers returned by the runtime. Results auto-deliver. When available, read `agent://<id>` for complete output and `history://<id>` for its transcript. Bare `history://` lists registered agents. Inspect only agents within the authorized session and project scope.

When messaging is exposed, `write` to `agent://<id>` with a non-empty message steers that recorded peer. Use `agent://all` only for a necessary order to visible authorized peers. Agent IDs and process IDs are different identifiers. Do not construct IDs or infer liveness from a transcript timestamp.

Use the exposed `wait` tool only when blocked with no other actionable work. Do not poll while results will auto-deliver. For processes, start jobs through the live `bash` contract, read returned `proc://<id>` status and logs, and cancel only owned jobs through the documented `proc://<id>/kill` operation. A process status resource is not an agent-resume API.

## Choose a fresh agent or a stateful continuation

Give new work to a fresh agent by default. This includes fix rounds, follow-ups, retries, and the next queue item. Consolidate the original brief, every later directive, the previous report, and the branch or artifacts into the new assignment.

Resume or message an existing agent for work only when the continuation strictly needs costly local state, such as its checkout, uncommitted changes, or a process it still runs. Confirm that the runtime can resume the recorded agent. A stop or hold order is not reuse. A logical owner may outlive its agent, but the next round normally gets a fresh one.

## Run the lifecycle protocols

### Bounded assignment

Collect the complete report and artifacts, then independently accept or reject them. A correction follows the fresh-agent rule above.

### Panel

Partition candidates or slices with explicit ownership. Start all independent participants before waiting, and account for missing or canceled participants by identity. Freeze candidates before independent reviews. Freeze reviews before synthesis. The root decides. Agreement is evidence, not proof.

### Owner

Keep one logical owner for each coupled unit, with a recorded workspace and generation. Require a report at each acceptance boundary. Use a fresh agent for its next round unless the stateful-continuation condition holds. Sibling owners do not share a branch.

### One-shot watcher

Observe one branch, head, or generation for one exact predicate, with a time limit and stop conditions. Return the meaningful event and finish. A changed generation requires a new watcher. Watchers do not fix, merge, authorize, or silently follow a new head.

## Keep root acceptance separate

The root owns user interaction, scope, approvals, integration, external writes, merges, deletion decisions, and final acceptance. Children prepare local branches, diffs, exact head/base evidence, and requested PR actions; the root performs authorized pushes, PR creation or mutations, external comments, and merges after the applicable operator, CI, and independent-review gates. Local ownership or a full-autonomy grant does not transfer those operations to a child. Freeze sibling edits before shared formatting, linting, builds, or project-wide tests. A worker verifies only when its assignment authorizes that lane.

A commit, rebase, conflict resolution, or applied patch changes the evidence generation. Reconcile that change before accepting a verdict. Use a patch-id exception only when the selected playbook explicitly permits it. Report exact paths, generation, executed commands, results, deviations, and unavailable capabilities. A successful worker exit is not artifact acceptance.
