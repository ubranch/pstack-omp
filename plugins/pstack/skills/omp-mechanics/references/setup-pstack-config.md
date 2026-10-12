# OMP model configuration

`skill://setup-pstack` owns inspection, authorization, validation, and writes. `skill://pstack-omp` owns dispatch. The port supplies no model defaults or required alias names.

## The two model maps

`modelRoles` maps operator-chosen role aliases to native model selectors. Selectors can include supported reasoning suffixes. A selector's format, available models, and accepted reasoning values come from the active runtime and catalog, not an upstream model slug.

`task.agentModelOverrides` maps exact runtime agent names to native selectors or aliases such as `@<role>`. The runtime resolves the referenced role through `modelRoles`. An absent override retains runtime inheritance. A task display name or an imported workflow role is not an agent definition and cannot create a model slot.

The maps are shared operator configuration. An alias may affect several agents or work outside pstack. Existing valid entries, unrelated roles, and the active chat model remain unchanged unless the user explicitly requests those effects. A missing map does not mean setup failed or that a rule must be generated.

Upstream lists such as "arena runners" describe workflow participants. OMP's agent override map is not a participant list. Its entry count does not set panel size, and no thin agent files are required by the port. Native inheritance replaces Cursor's instruction to omit a task `model`; the port does not write `auto` or `inherit-parent` as invented selectors.

## Scope and persistence

OMP can resolve settings from environment, runtime, overlay, project, global, and default layers. The active profile can relocate global storage. Effective settings are not necessarily the writable layer, and a global edit can remain shadowed by a higher layer.

Native cfg tools, when exposed, provide the preferred configuration interface. Their documented scope and consent rules govern mutations. Consent that is denied, unanswered, or unavailable does not authorize an alternative writer. The CLI provides selected-key inspection through `omp config get <key> --json` and model inventory through `omp models`. Neither requires displaying the entire config or reading credentials.

Ordinary `omp config set` writes global settings. Project model-role assignment can have a different destination under the runtime's model-role storage policy. Copying an effective merged map into global settings would persist entries from other layers. Entry-level updates preserve that distinction. A whole-map update is safe only with a fresh writable-layer read and preservation of every unrelated entry.

Model routing reloads for subsequent subagent launches and fallback decisions. A routing change does not restart an agent or change an already running chat's model.

## Separate runtime settings

Concurrency, isolation, provider service tiers, prewalk, advisors, retry chains, and approval policy are outside pstack model setup. Their current values remain operator-owned. A retry or fallback can change the model actually used, so configured aliases alone do not prove model or provider diversity. Returned resolution evidence is required for that claim.
