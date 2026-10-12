# Apply to upstream Markdown only. Structural runtime adaptations live in patches/.
# Match raw Cursor mechanics before replacing model names or tool tokens.

/Every spawn is a Task subagent with /c\
Resolve explorer and explainer roles through `skill://pstack-omp`. Give each a read-only brief and an explicit write ban. Model selection stays in the operator's `modelRoles` and `task.agentModelOverrides`; do not change it for this workflow.
/Each spawn below names a role line in /c\
Resolve investigators and the synthesizer through `skill://pstack-omp`. Use the operator's existing role configuration and report unavailable model diversity; do not rewrite it.
/Each reviewer and the synthesizer name a role line in /c\
Resolve the three reviewers and synthesizer through `skill://pstack-omp`. Keep Divergent on a different model family from Judgment when returned model metadata proves that diversity. Otherwise report the limitation. Preserve the operator's existing configuration.
/^4\. Pick the worker model from /c\
4. Resolve the worker role and existing model configuration through `skill://pstack-omp`. For a model race, record each arm's returned model metadata; do not infer diversity from different prompts or change operator configuration.
/^3\. Pick the runners\. Use the /c\
3. Resolve runners through `skill://pstack-omp` using existing role configuration. Prefer different model families for judgment-sensitive work when returned metadata proves it, and report unavailable diversity. Spawn more runners when the arena covers multiple design directions. Use the same model N times when the work is generation-bound rather than judgment-sensitive.
/^Take the runners from the `architect runners` line /c\
Resolve design runners through `skill://pstack-omp` using the operator's existing configuration. Preserve Arena's candidate isolation and diversity requirements.
/^After all Phase B candidates complete, choose one model /c\
After all Phase B candidates complete, start a read-only cross-judge through `skill://pstack-omp`. Prefer a different model family from the parent's when returned metadata proves it; otherwise report the limitation. It sees the rubric and candidates by sanitized path label, scores each criterion, and recommends a base with rationale. It runs in parallel with your reading in Phase D. Do not spawn it while candidates are still writing.
/^Launch all reviewers in a single message with the Task tool/c\
Launch independent reviewers through `skill://pstack-omp`: one `tasks[]` batch when exposed, otherwise one flat `task`/`solutionSpace` call per reviewer, all before waiting. Give them separate contexts and the same intent, evidence, and rubric. Prefer a different model family or provider for each reviewer and from the writer when returned metadata proves it. Preserve the existing configured panel size; do not infer it from a model list or change operator configuration.
/^Each reviewer gets `subagent_type:/c\
Resolve the reviewer agent from the live roster through `skill://pstack-omp`. State read-only posture and the write ban in each brief; pass only fields exposed by the live task schema.
/^If the Task tool rejects a configured entry, run that reviewer /c\
If a configured reviewer cannot run, report the actual rejection and the resulting diversity gap. Use an available reviewer context without changing model configuration, and identify any runtime fallback from returned metadata.
s#Spawn all N workers in one message with .*#Spawn all N workers through `skill://pstack-omp`: one `tasks[]` batch when exposed, otherwise one flat `task`/`solutionSpace` call per worker, all before waiting. Give each a standalone brief and explicit write ownership. Create separate worktrees before dispatch when workers may write the same paths.#
s#Spawn all N subagents in one message with `run_in_background: true`, each with#Spawn all N subagents through `skill://pstack-omp`, in one `tasks[]` batch when exposed or separate flat `task`/`solutionSpace` calls before waiting, each with#
s#One message, three `Task` calls, `subagent_type: generalPurpose`, agent mode \(`readonly: false`\)\. Reviewers need MCP access to look up the tickets, chat threads, and observability traces the transcript references, and readonly strips MCPs\.#Start three independent reviewer contexts through `skill://pstack-omp`: one `tasks[]` batch when exposed, otherwise separate flat `task`/`solutionSpace` calls before waiting. Their briefs permit the required MCP lookups but forbid edits. They inspect tickets, chat threads, and observability traces cited by the transcript.#
s#One `Task` call, `subagent_type: generalPurpose`, `model` from .* Pass `references/synthesizer.md`#Start one fresh synthesizer through `skill://pstack-omp` with the required read-only MCP access. Pass `references/synthesizer.md`#
s#`model`: the `why investigators` line, default `[^`]+`\.#Resolve each investigator through `skill://pstack-omp` with the existing role configuration.#
s#`model`: the `why synthesizer` line, default `[^`]+`\.#Resolve the synthesizer through `skill://pstack-omp` with the existing role configuration.#
s#Every spawn is `generalPurpose` with `readonly: false` \(agent mode\)\. \*\*Do not use readonly/Ask mode\.\*\* It strips MCP access, which disables the MCP-backed investigators and the synthesizer's citation spot-checks\. Investigators still shouldn't write anything\.#Resolve read-only investigators and the synthesizer through `skill://pstack-omp`. Their briefs permit the MCP lookups and citation checks they need, and forbid all writes.#
s#with `subagent_type: "poteto-agent"` and an explicit model per the Subagents section#through `skill://pstack-omp` with read-only scope and existing role configuration#g
s#`subagent_type: "([^"]+)"`#`agent`: `\1`#g
s#When a worker must start from a non-default pushed branch, pass `cloud_base_branch`\.#When a worker needs a non-default base, create its private `git worktree` on that exact base before dispatch and name the absolute path in its brief.#
s#N is total workers, not the cloud concurrency limit\.#N is total workers. Respect the live runtime's concurrency limit without changing operator configuration.#
s#One Cursor cloud agent#One root-started owner in its own worktree#g
s#each a Cursor cloud agent#each a root-started worker in its own worktree#g
s#Each live lane runs on its own cloud VM at the PR head\.#Each live lane runs in its own worktree at the exact PR head.#
s#Fan out N parallel cloud workers\.#Fan out N parallel workers through `skill://pstack-omp`.#
s#as cloud agents#in separate worktrees#g
s#Cloud-agent PR tools default to draft, so set `draft: false` on every PR creation call\.#Open a ready PR with the resolved forge's documented command. Do not assume another runtime's defaults.#

s#One owner per PR carries build through merge, and the root swarm-verifies each PR before its owner merges#One owner per PR prepares the change and merge-ready evidence, and the root swarm-verifies and performs each authorized merge#
/^\*\*You own the verdicts, never the PRs\./c\
**You own the verdicts and authorized publication. One local owner prepares each PR from build to merge-ready, and the root merges only on its clean swarm verdict.** For "autopilot this queue", "full autopilot", and one-owner-per-PR programs. Orchestrate runs a standing program whose coordinator lands verified work. Here each PR's owner keeps the local lifecycle, while the root performs pushes, PR mutations, approvals, and merges under the operator's grant and existing gates.
s#owns build, the first push, a ready PR,#owns build, local branch/head evidence and requests for the root's first push and ready PR,#
s#and the merge itself\.#and merge-ready evidence for the root.#
s#pushes its first branch snapshot, and opens the PR ready, never draft\.#returns its first local branch snapshot and a ready-PR request to the root, never a draft request. The root performs the authorized first push and PR creation before self-proof.#
s#After that, the owner pushes its branch again after every verifiable unit \(hooks on, a WIP commit is fine\)\.#After that, the owner returns local branch, diff, and head evidence after every verifiable unit; the root performs each authorized push with hooks on after the pre-review checks (a WIP commit is fine).#
s#To publish each rebase, push the owner's own branch with `git push --force-with-lease` after an `ls-remote` check\.#To publish each rebase, the owner returns the exact local head and a publication request; the root pushes the owner's branch with `git push --force-with-lease` after an `ls-remote` check.#
s#The merge is the one step an owner may not take alone\. Step 4 gates it\.#The owner never performs remote writes or merges. Step 4 gates the root's merge.#
s#On a clean verdict the owner merges, and a fresh owner takes the next item\.#On a clean verdict the root merges, and a fresh owner takes the next item.#
s#The owner merges only from a head freshly rebased onto trunk\.#The root merges only from the owner's exact head freshly rebased onto trunk.#
s#The owner squash-merges its own PR through the resolved forge and returns\.#The root performs the authorized squash-merge through the resolved forge after these gates, and the owner returns.#
s#The owner records it in the form that the tool's approval contract allows, with a pointer to the root's countersign\.#The owner returns a local approval record with a pointer to the root's countersign. The root records any authorized external approval in the form the tool's approval contract allows.#
s#owns its change end to end: build, first push, a ready PR opened before self-proof,#owns the local change end to end: build, branch/head evidence and a request for the root to push and open a ready PR before self-proof,#
s#Owners push only their own branches and report the tip, current base, and intended parent\. The root is the only topology writer\.#Owners prepare only their own local branches and report the diff, tip, current base, intended parent, and publication requests. The root is the only publisher and topology writer.#
s#FORBIDDEN    no gt, no rebase, no force-push, no fixes outside scope, plus unit-specific bans#FORBIDDEN    no gt, no rebase, no external writes or merges, no fixes outside scope, plus unit-specific bans#
s#On heavy repos the stacker is a standing role from wave one, integrating as units verify\.#On heavy repos the stacker is a standing local-preparation role from wave one, returning integration evidence as units verify; the root applies merges and performs authorized publication after the verdict gates.#
s#A worker pushes its branch, a verifier writes its ledger row, receipts land in the store\.#A worker returns its local branch, diff, exact head, and publication request; the root performs the authorized push after the applicable gates. A verifier writes its local ledger row, and receipts land in the store.#
/^A subagent that opens a PR runs /c\
A subagent preparing a PR applies the `unslop` skill (`skill://unslop`) and returns its local branch, diff, exact head/base, proposed PR title/body, and review requests for `interrogate` and `/no-comments`. The root starts those reviews, accepts their evidence, and performs authorized pushes, PR creation and mutations after the applicable gates; it reports the resulting URL. The child returns without babysitting unless it is an Autopilot-full or Autopilot-stack owner. That owner's brief assigns the local babysit loop and is the ask `playbooks/babysit.md` waits for. The owner starts the loop after its code-ready report, returns requested remote actions to the root, reports merge-ready or STACK-READY per its playbook, and retains the exception to waiting for a whole stack before babysitting.
s#<Who merges, and which PR ids are the operator's items that stop at merge-ready\.>#<The root performs authorized merges; name the operator's items that stop at merge-ready for the operator's click.>#
s#Spawn one owner per PR with the full lifecycle the execution playbook names\.#Spawn one owner per PR with the local lifecycle the execution playbook names; each returns branch/diff/head evidence and requested remote actions to the root.#
s#Open the PR ready, never draft, per \*\*Opening a PR\*\*\.#The root opens the PR ready, never draft, per **Opening a PR**, from the owner's local evidence and PR request after the applicable gates.#
s#Run the repo's lint and typecheck once before the PR-facing push\. Push with hooks on\.#Run the repo's lint and typecheck once before the PR-facing push. The root performs the authorized push with hooks on.#
s#<The owner squash-merges its own PR, or the root appends it to the base-branch stack and the operator lands it bottom-up\.>#<The root squash-merges after the operator, CI, patch-id, and independent-review gates, or appends to the base-branch stack for the operator to land bottom-up.>#
s#Post the screenshots and the video in chat\. Stop at merge-ready\. Wait for the operator's click\.#Return the screenshots and video to the root for the operator's review in chat. Stop at merge-ready. Wait for the operator's click.#
s#that owner rebases its own branch and publishes it with `git push --force-with-lease` per#that owner prepares the local rebase and reports its exact head; the root publishes it with `git push --force-with-lease` per#
s#The one sanctioned creation: when a fix's owning PR has already merged, it becomes a new PR on top of the remaining stack,#The one sanctioned creation: when a fix's owning PR has already merged, the child returns a local follow-up branch and PR request; the root opens the authorized new PR on top of the remaining stack,#
s#Batch every known fix into one push wave\.#Batch every known fix into one local change wave and return its head and publication request; the root performs the authorized push wave after the applicable gates.#
s#Flake or infrastructure earns one fresh build, never a job retry\. One retry only\.#Flake or infrastructure earns one fresh build, never a job retry. A delegated babysitter returns a retrigger request; the root starts the authorized fresh build. One retry only.#
s#Push that wave before replying so the reply cites the commit\. On Origin, reply with#The babysitter returns the local wave, exact head, and proposed replies; the root pushes the authorized wave before replying so each reply cites the published commit. On Origin, the root replies with#
s#On GitHub, call `gh api --method POST#On GitHub, the root calls `gh api --method POST#
s#Dismiss noise with the concrete disproof on the thread\.#The babysitter returns concrete disproof for noise; the root posts any authorized dismissal on the thread.#
s#Each returns `PASS`, `PASS\+NOTES` or `FAIL` and posts that verdict on its own PR\.#Each returns `PASS`, `PASS+NOTES` or `FAIL` with exact head/base evidence and a proposed PR comment; the root accepts the evidence and posts the authorized verdict on that PR.#
s#One subagent per PR, not batched,#One independent verifier per PR with its own brief, dispatched through `skill://pstack-omp` in one `tasks[]` batch when exposed or separate flat `task`/`solutionSpace` calls before waiting,#
s#No PR and no push unless you already had one out\.#Children return local evidence and any publication request to the root. The root opens no PR and performs no push unless one was already out and the operation remains authorized.#

s#go to your strongest judgment model \(`claude-[a-z0-9.-]+`\)#go to your strongest judgment model#
s#`claude-(fable|opus)-[0-9.-]+(-(thinking-)?[a-z]+)?`#your strongest judgment model#g
s#`gpt-[0-9.]+-sol-[a-z]+`#your strongest instruction-following model#g
s#`(cursor-)?grok-[0-9.]+-([a-z]+-)?fast(-[a-z]+)?`#your fast code model#g
s#`(claude|gpt|grok|gemini|opus)-[a-z0-9.]+-[a-z0-9.-]+`#your configured model for this role#g

s#`AskQuestion`#the live user-question tool#g
s#AskQuestion#the live user-question tool#g
s#the `deslop` skill from the `cursor-team-kit` plugin \(`/deslop`\)#the `unslop` skill (`skill://unslop`)#g
s#Run `/deslop` from `cursor-team-kit` over the diff before commit\.#Run the `unslop` skill (`skill://unslop`) over the diff before commit.#
s#`/deslop`#the `unslop` skill (`skill://unslop`)#g
s#`control-ui` or `control-cli` runtime verification \(from `cursor-team-kit`\)#runtime verification through the live browser or desktop controls, or bash and PTY for CLIs#g
s#\(`control-cli` or `control-ui` from `cursor-team-kit` as the change demands\)#(the live browser or desktop controls, or bash and PTY for CLIs, as the change demands)#g
s#\(`control-ui` or `control-cli` from `cursor-team-kit` as the change demands\)#(the live browser or desktop controls, or bash and PTY for CLIs, as the change demands)#g
s#Drive through `control-ui` or `control-cli` from `cursor-team-kit`\.#Drive through the live browser or desktop controls, or bash and PTY for CLIs.#
s#Browser, Electron, and web UIs use `control-ui` from `cursor-team-kit`\. CLIs and TUIs use `control-cli` from `cursor-team-kit`\.#Browser, Electron, and web UIs use available browser controls. Native desktop UIs use available desktop controls. CLIs and TUIs use bash and PTY.#
s#`cursor-team-kit` publishes `control-cli` \(CLIs and TUIs\) and `control-ui` \(browser / Electron / web UIs\)\.#Use available browser or desktop controls for UIs, and bash and PTY for CLIs. Read each live tool's schema before using it.#
s#`control-ui`#the live browser controls#g
s#`control-cli`#bash and PTY#g
s# from `cursor-team-kit`##g
s#^1\. Use the \*\*create-skill\*\* skill \(Cursor's built-in for authoring SKILL\.md files\)\.$#1. Write the SKILL.md with the live file tools. Give it valid YAML frontmatter, a name matching its directory, and a description that states its invocation conditions. Preserve the runtime's supported invocation metadata.#
s#the \*\*create-skill\*\* skill \(Cursor's built-in for authoring SKILL\.md files\)#the **authoring-a-skill** playbook (`skill://poteto-mode/playbooks/authoring-a-skill.md`)#g
s#Cursor's built-in `create-skill` skill#the `authoring-a-skill` playbook#g
s#Cursor's built-in `create-skill`#the `authoring-a-skill` playbook#g
s#`create-skill`'s#the `authoring-a-skill` playbook's#g
s#`create-skill`#the `authoring-a-skill` playbook#g
s#A `create-skill`-style#An `authoring-a-skill`-style#g
s#new skill via create-skill:#new skill via authoring-a-skill:#g
s#draft a new skill via create-skill#draft a new skill via the authoring-a-skill playbook#g
s#via create-skill \+ unslop#via the authoring-a-skill playbook + unslop#g
s#Drive a long or stubborn hunt with Cursor's `/loop` command\.#Drive a long or stubborn hunt to the stated predicate. Use `/loop` only when the live runtime exposes it and the operator has enabled it.#
s#Pick the wake mechanism using Cursor's `/loop` command \(a built-in, not a pstack skill\)\.#Pick a supported wake mechanism through `skill://pstack-omp`. Use `/loop` only when it is exposed and already enabled; otherwise use a root-owned watcher or an authorized external supervisor.#
s#A local root arms each tick as a real terminal `/loop`\. The loop uses a monitored-shell 30-minute sleep and emits an output-notification sentinel\.#A root in session arms each tick with the live runtime's supported loop or root-owned watcher.#
s#A cloud root uses the existing cloud-sleeper wake chain instead\.#A wake outside the session requires an authorized external supervisor. A background job alone does not guarantee a wake.#
s#In a local session, a real terminal `/loop`\. In a cloud root, a cloud-sleeper wake chain\.#Use a supported in-session loop or root-owned watcher. Out-of-session wakes require an authorized external supervisor.#
s#Run `drive` and `background` under `/loop` in dynamic mode\.#Run `drive` and `background` with a root-owned watcher or the live loop when exposed and already enabled.#
s#Hold the watch under `/loop` in dynamic mode\.#Hold the watch with a root-owned watcher or the live loop when exposed and already enabled.#
s#`/loop` per component until the diff is zero\.#Repeat per component until the diff is zero using a supported root-owned wake mechanism.#
s#"/loop until X"#"run until X"#g
s#the cloud agent's status in the Cursor dashboard#the returned agent status and its `agent://<id>` report#g
s#After a Cursor restart: local agents are dead, cloud work is not\.#After a runtime restart, reconcile agent and job state against the actual returned handles. Do not infer that a saved transcript is a running agent.#
s#reattach cloud work by PR and branch rather than agent id#reattach pushed work by PR and branch rather than an old agent id#g
s#a Cursor restart#a runtime restart#g
s#cloud-agent URL#the prior returned `history://<id>` or `agent://<id>` handle#g

s#`~/\.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>\.jsonl`#the current workspace's OMP session transcript, resolved from its session metadata#g
s#the active workspace's `agent-transcripts/` directory#the current workspace's session transcript directory#g
s#the workspace's `agent-transcripts/` directory#the current workspace's session transcript directory#g
s#under `agent-transcripts/`#under the current workspace's session transcript directory#g
s#`agent-transcripts/` directory#session transcript directory#g
s#`~/\.cursor/projects/\*/`#unrelated workspace session buckets#g
s#<agent-transcripts>#<current-workspace-session-directory>#g
s#local transcripts under `agent-transcripts/`#local transcripts under the current workspace's session directory#g
s#~/\.cursor/skills/#~/.omp/agent/skills/#g
s#\.cursor/skills/#.omp/skills/#g
s#, or plugin-installed paths under `~/\.cursor/plugins/`#, or the plugin path reported by the live skill loader#g
s#`~/\.cursor/plugins/`#the plugin path reported by the live skill loader#g
s#misses one that lives at `\.cursor/worktrees/myrepo/x`#misses one that lives at a tool-managed path like `.worktrees/myrepo/x`#g
s#The pinned and active chats are the real artifact \(principle-prove-it-works\)\. Get that set from the user or sidebar and cross-check every candidate\. The lever has marked `safe` a worktree the user had pinned, so the pinned set wins\.#Active sessions are the real artifact (principle-prove-it-works). Cross-check the returned agent handles, this workspace's session metadata, and the user's known active chats before removing a worktree. A script's `safe` label does not override a live owner's claim.#
s#report whether the chat is pinned or ongoing and which worktrees it touches#report whether the session is active and which worktrees it touches#g
s#A pinned chat spawns arena and repro trees into sibling worktrees via background subagents, and those are in use even when their names never hit the sidebar\.#An active chat can own sibling arena and repro worktrees even when their names do not appear in returned agent metadata.#
s#Before spawning investigators, list the available MCPs from the Cursor environment\. Use the available-tools map when present\. Otherwise inspect the `mcps/` directory Cursor exposes for enabled MCP servers\.#Before spawning investigators, inspect the live available-tools map and each relevant MCP schema. Use only integrations actually exposed in this session.#

s#On the operator's go, arm `/loop 1h` with a prompt that runs this tick\. `/loop` works in local and cloud roots\.#On the operator's go, schedule the hourly tick with `/loop 1h` only when exposed and already enabled. Otherwise use a root-owned watcher or authorized external supervisor with the same cadence and predicate; a background job alone does not guarantee a wake.#
s#On the operator's go, the root arms `/loop 1h` with a prompt that runs this tick, per Autopilot-full step 6\.#On the operator's go, the root schedules the hourly audit tick through the supported wake mechanism in Autopilot-full step 6.#
s#As soon as a subagent starts, the owner adds its ID, expected runtime \(at least the longest past run of that kind\), and state to a `children\.tsv` kept the same way\.#When the root starts a participant for an owner, record its returned ID, expected runtime (at least the longest past run of that kind), and state in that owner's `children.tsv` kept the same way.#
s#the root has the owner record each stuck subagent as stuck and, if its work is still needed, replace it\.#the root has the owner record each stuck participant and starts its replacement if the work is still needed.#

s#name: Poteto Mode#name: poteto-mode#
/^is_background: true$/d
s#re-read this playbook from trunk with `git show origin/main:pstack/skills/#re-read this playbook from its installed URI, `read skill://#g
s#Re-read the execution playbook from trunk#Re-read the installed execution playbook#g
s#`git show origin/main:pstack/skills/<each other leaf skill the program uses>`#`git show origin/main:<each skill or doc the product repo vendors itself>`#g
s#`git show origin/main:pstack/skills/#`read skill://#g
s#`git show origin/main:<control skill path>`#the live control tool's documentation#g
s#pstack/skills/([a-z-]+)/#skill://\1/#g
s#https://github.com/cursor/plugins/blob/main/pstack/#https://github.com/ubranch/pstack-omp/blob/main/plugins/pstack/#g
s#^paths: \[#globs: [#
