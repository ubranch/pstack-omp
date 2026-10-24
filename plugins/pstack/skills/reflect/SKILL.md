---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Before fanning out, resolve this conversation's returned `history://<id>` handle or its transcript path from current session metadata. Read only this workspace's conversation. If neither is available, pass a tight digest and report that limit.



OMP session files begin with metadata records, not the opening user message. When matching a file, inspect its actual message records and session metadata rather than assuming a Cursor layout.

## 2. Spawn three reviewers in parallel

Start three independent reviewer contexts through `skill://pstack-omp`: one `tasks[]` batch when exposed, otherwise separate flat `task`/`solutionSpace` calls before waiting. Their briefs permit the required MCP lookups but forbid edits. They inspect tickets, chat threads, and observability traces cited by the transcript.

Resolve the three reviewers and synthesizer through `skill://pstack-omp`. Keep Divergent on a different model family from Judgment when returned model metadata proves that diversity. Otherwise report the limitation. Preserve the operator's existing configuration.

| Lens | Canonical role | Perspective | Prompt template |
|---|---|---|---|
| Judgment | reviewer | Judgment | `references/judgment-reviewer.md` |
| Tooling | reviewer | Tooling | `references/tooling-reviewer.md` |
| Divergent | reviewer | Different model family when available | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Reviewers return findings in the `Task` response body.

## 3. Synthesize

Start one fresh synthesizer through `skill://pstack-omp` with the required read-only MCP access. Pass `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. It returns an Accepted / Rejected / Backlog list.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the **encode-lessons-in-structure** principle skill.

## 5. Apply

Present the synthesizer's full Accepted / Rejected / Backlog output and wait for explicit approval before applying any Accepted edit. The user picks the subset and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

File each Backlog item to your team's devex or backlog tracker without waiting. Only the Accepted list waits for approval.

Never edit a skill under `plugins/cache/`. Before approval, show its destination, `.omp/skills/<skill>/` or `~/.omp/agent/skills/<skill>/`. After approval, copy the skill folder there and edit the copy. Never open a PR or push.

Follow each approved row's Routing exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): the parent does it directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): hand to the `authoring-a-skill` playbook and run its draft / test / iterate loop.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): hand to the `authoring-a-skill` playbook and run its description-optimization loop.
- `new skill via authoring-a-skill: <kebab-name>`: hand creation to the `authoring-a-skill` playbook. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done.

## 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
