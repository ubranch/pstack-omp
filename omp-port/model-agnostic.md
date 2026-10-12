# The model-agnostic convention

Port-only document. Upstream pstack names concrete model slugs. The port names capabilities and respects the operator's configuration.

## Why

The operator picks the chat model with omp's `/model` command. A model slug in an imported skill can become stale or override a valid local choice.

## The rule

Name the capability you need. Never name a vendor, a family, or a slug.

| Role | Write this | Never this |
|---|---|---|
| Hardest judgment, vague intent, cross-cutting design | your strongest judgment model | a named thinking model |
| A precisely specified sequence to execute to the letter | your strongest instruction-following model | a named instruction model |
| Trivial mechanical edits, bulk collection | your fast code model | a named fast model |
| Prose, reviews, synthesis | your prose model | a named prose model |

## Routing belongs to the operator

The chat model is the operator's choice, made with `/model`. A skill does not change it.

`modelRoles` and `task.agentModelOverrides` in `~/.omp/agent/config.yml` hold operator-owned routing choices. The overrides are keyed by agent name. Existing valid choices and unrelated entries must survive setup and upgrades.

The shipped pstack agents have no `model:` field. Without a configured override, they inherit the parent model. Use `/setup-pstack` when you explicitly want to inspect or change routing. It checks selected keys and asks before a mutation. It does not replace the whole configuration, install provider defaults, or create an agent for each role.

Read [`skill://pstack-omp`](../plugins/pstack/skills/pstack-omp/SKILL.md) before dispatch. The live tool schema and discovered roster determine how a role runs. The `task` tool has no per-task `model` field. A role alias in configuration is not a tool argument.

Skill visibility and manual-invocation metadata remain intact; they do not select a model or grant permissions. OMP uses its native package format rather than stripping that metadata to satisfy the portable manifest schema. See the [packaging adaptation](../PORTING.md#packaging-and-mode-state).

## Model diversity is a property, not a slug

`interrogate`, `arena`, and `reflect` exist to get an independent second opinion. What makes
the opinion independent is that the reviewer runs on a different model family from the writer,
not that it runs on any particular model.

State the property. Inspect the available catalog and configured agent routing before promising different model families. When only one family is available, report that limit. Never fake diversity with two model selectors from the same family or skip the review silently.

## Gate

`bash omp-port/check-port.sh` checks vendor slugs in the generated skills and agents, plus plugin docs when present. Illustrative prose that mentions a model name belongs in `omp-port/slug-allowlist.txt` with a reason. The gate does not prove that a configured model is available or suitable for a role.
