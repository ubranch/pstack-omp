---
name: setup-pstack
description: "Inspect OMP model choices or change explicitly requested pstack agent routing and reasoning settings. Use for /setup-pstack, model configuration, or budget changes."
---

# Set up pstack on OMP

Inspect existing choices first. Running `/setup-pstack` alone does not authorize replacing models, changing budgets, or resetting configuration. Valid operator choices need no change. pstack does not set the active chat model, install providers, create agents, or expand approval permissions.

Read [OMP model configuration](../omp-mechanics/references/setup-pstack-config.md) for map semantics. `skill://pstack-omp` owns role selection and dispatch. Configure only exact agent names accepted by the live runtime, not labels invented by an imported skill.

## 1. Inspect selected settings and available models

Use exposed cfg tools or the `cfg://` configuration interface when available. Read their live documentation and consent requirements before use. Request only `modelRoles`, `task.agentModelOverrides`, and scope metadata needed for the requested change. Narrow role reads to referenced aliases when supported.

If no native configuration reader is exposed, use documented read-only CLI commands in the same profile and project as this session:

```sh
omp config get modelRoles --json
omp config get task.agentModelOverrides --json
omp models
```

Use an exposed model inventory instead of the CLI when it supplies the required information. Inventory determines the selectors and reasoning settings you can offer. Do not read provider credentials, auth files, environment dumps, or the entire config. Do not run `omp config list` to discover two keys. Resolve the active profile rather than assuming a config path.

Finish with the relevant current choices, their resolution status, the available alternatives, and the effective scope. If an inventory or setting cannot be read, report that exact limitation. Missing inventory does not make an existing choice invalid.

## 2. Preserve existing choices

Resolve existing selectors and aliases through the native runtime when possible. Leave valid choices alone, including inheritance from an absent agent override. Preserve unrelated and currently inactive agent entries. An agent missing from today's roster is not permission to delete its configuration.

Do not import upstream provider defaults, role lists, panel sizes, or a universal reasoning ladder. Unresolved choices are reported for a user decision, not replaced with an invented fallback. For an inspection-only request, report the result and stop here.

## 3. Propose only the requested change

Use the user's stated model or budget request. If a required preference is missing, ask one focused question with choices supported by the detected inventory. Keep current choices as the default. A reasoning change uses the runtime's supported selector syntax, not a fabricated model slug or a task `effort` field.

Show each affected agent or alias with its current and proposed value and write scope. An alias can affect multiple agents and other OMP work. Account for every known reference before proposing to change it. If those effects exceed the request, use an independent alias or obtain authorization for the wider change.

Model configuration does not set participant count, concurrency, isolation, service tiers, advisors, fallbacks, or tool approvals. Report unavailable model diversity without changing those settings.

## 4. Apply an authorized minimal edit

Validate each requested selector against native resolution and the detected inventory. Confirm that its reasoning setting is supported. Validate agent names against the live dispatch contract. Resolve the writable layer and any higher-precedence override before writing.

Prefer native cfg entry-level writes. Honor cfg's own consent gate even when the user requested the change or the approval mode allows writes. If consent is denied, times out, or cannot be collected, stop that operation and report any earlier writes. Do not retry through shell commands or direct file edits to bypass it.

If cfg is unavailable, use a documented writer only when the intended scope and preservation of unrelated entries can be established. A whole-map writer requires a fresh read of the writable layer and a merge of only the authorized entries. Never persist a merged effective map from other layers into global settings. If the available interface cannot make that edit safely, report the exact missing capability and give the requested entry changes for the operator to apply.

Write only the approved entries in `modelRoles` and `task.agentModelOverrides`. Remove an agent override only when the user requested inheritance, using the interface's supported entry deletion. Do not reset either map, remove retired-looking entries, rewrite config comments, or clean up other settings.

## 5. Read back the affected entries

Read only the changed settings and verify the requested entries. Report what changed, what stayed unchanged, any partial or refused write, and any layer that still overrides the saved choice. If no change was needed, say so.

Routing changes apply to subsequent subagent launches after the runtime reloads settings. They do not switch a running agent or the current chat model. Do not require a restart without runtime evidence that one is needed.

If the project lacks a real app driver and the user is asking how to prove changes, offer `/create-verification-skill` once. If the project lacks a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code) and the user is asking how to prove a property holds in every case in scope, offer `/create-formal-verification-skill` once. Create either only on an explicit request. Model setup does not install or generate verification tooling on its own.
